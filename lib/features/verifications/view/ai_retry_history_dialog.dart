import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/status_chip.dart';
import '../model/verification_result_models.dart';
import 'verification_copy_button.dart';
import 'verification_text_format.dart';

/// Human-readable audit of AI proposals. The raw snapshots stay in the API,
/// but administrators review the facts and the before/after decision here.
class AiRetryHistoryDialog extends StatelessWidget {
  const AiRetryHistoryDialog({super.key, required this.attempts});

  final List<AiRetryAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: size.width < 960 ? size.width - 32 : 960,
        height: size.height < 700 ? size.height - 32 : 650,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Historial de propuestas IA',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              const Text(
                'Cada reintento conserva la propuesta anterior y los tickets de Redmine que se volvieron a leer.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: attempts.isEmpty
                    ? const Center(
                        child: Text('Todavía no hay reintentos de IA.'),
                      )
                    : DefaultTabController(
                        length: attempts.length,
                        child: Column(
                          children: [
                            TabBar(
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              tabs: [
                                for (var i = 0; i < attempts.length; i++)
                                  Tab(text: 'Reintento ${attempts.length - i}'),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  for (final attempt in attempts)
                                    _AttemptDetail(attempt: attempt),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttemptDetail extends StatelessWidget {
  const _AttemptDetail({required this.attempt});
  final AiRetryAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final previous = attempt.previousResult;
    final previousRationale = previous['rationale'] as String?;
    final previousApplicability = previous['applicability'] as Map?;
    final humanPreserved = attempt.outcome == 'HUMAN_PRESERVED';
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        Text(
          DateFormat(
            'dd/MM/yyyy · HH:mm',
          ).format(attempt.attemptedAt.toLocal()),
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
        ),
        if (attempt.model != null)
          Text(
            'Modelo: ${attempt.model}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        const SizedBox(height: 12),
        _AuditSection(
          title: 'Qué cambió',
          icon: Icons.compare_arrows_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(
                    label: attempt.previousStatus.label,
                    tone: _tone(attempt.previousStatus),
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  StatusChip(
                    label: attempt.proposedStatus.label,
                    tone: _tone(attempt.proposedStatus),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                humanPreserved
                    ? 'La decisión humana se conservó. Solo cambió la propuesta automática.'
                    : attempt.outcome == 'NO_CHANGE'
                    ? 'La nueva evaluación no cambió el estado propuesto.'
                    : 'La nueva propuesta se aplicó al estado vigente.',
              ),
              const SizedBox(height: 8),
              Text(
                'Estado vigente: ${attempt.effectiveStatus.label}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              SelectableText(humanizeVerificationText(attempt.rationale)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _AuditSection(
          title: 'Tickets de Redmine releídos',
          icon: Icons.confirmation_num_outlined,
          child: attempt.ticketSnapshot.isEmpty
              ? const Text(
                  'No se consultaron tickets en este reintento. Este resultado puede depender de una nota del caso; si no hay hechos suficientes, resolvé la aplicabilidad manualmente.',
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < attempt.ticketSnapshot.length; i++) ...[
                      if (i > 0) const Divider(height: 24),
                      TicketSnapshotView(ticket: attempt.ticketSnapshot[i]),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 16),
        _AuditSection(
          title: 'Antes de este reintento',
          icon: Icons.history_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                previous['displayName'] as String? ?? 'Evidencia evaluada',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text('Propuesta anterior: ${attempt.previousStatus.label}'),
              if (previousApplicability != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Aplicabilidad anterior: ${_applicabilityLabel(previousApplicability['decision'])}',
                ),
              ],
              if (previousRationale != null &&
                  previousRationale.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Fundamento anterior',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                SelectableText(previousRationale),
              ],
              if (previous.isEmpty)
                const Text('No se conservó un resumen del resultado anterior.'),
            ],
          ),
        ),
      ],
    );
  }
}

class TicketSnapshotView extends StatelessWidget {
  const TicketSnapshotView({super.key, required this.ticket});
  final Map<String, dynamic> ticket;

  @override
  Widget build(BuildContext context) {
    final fields = ticket['customFields'] as List? ?? const [];
    final journals = ticket['journals'] as List? ?? const [];
    final description = ticket['description'] as String?;
    final theme = Theme.of(context);
    final subject = ticket['subject']?.toString().trim();
    final project = ticket['projectName'] ?? ticket['projectId'] ?? '—';
    final status = ticket['statusName'] ?? ticket['status'] ?? '—';
    return Card.outlined(
      color: AppColors.surfaceWhite,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final heading = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REDMINE · TICKET #${ticket['id'] ?? '—'}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .7,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subject?.isNotEmpty == true
                          ? subject!
                          : 'Ticket sin asunto',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                );
                final copy = VerificationCopyButton(
                  text: formatTicketSnapshotForCopy(ticket),
                  label: 'Copiar ticket',
                );
                if (constraints.maxWidth < 560) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [heading, copy],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: heading),
                    copy,
                  ],
                );
              },
            ),
            const Divider(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.xl,
              runSpacing: AppSpacing.md,
              children: [
                _TicketFact(label: 'Proyecto', value: '$project'),
                _TicketFact(
                  label: 'Estado en Redmine',
                  value: '$status',
                  valueColor: AppColors.info,
                ),
                _TicketFact(
                  label: 'Cerrado',
                  value: ticket['closed'] == true
                      ? 'Sí'
                      : ticket['closed'] == false
                      ? 'No'
                      : '—',
                ),
                _TicketFact(
                  label: 'Última actualización',
                  value: formatTicketTimestamp(ticket['updatedAt']),
                ),
              ],
            ),
            if (description != null && description.trim().isNotEmpty) ...[
              const Divider(height: AppSpacing.xxl),
              Text('Descripción', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              SelectableText(description, style: theme.textTheme.bodyMedium),
            ],
            if (fields.isNotEmpty) ...[
              const Divider(height: AppSpacing.xxl),
              Text('Campos personalizados', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              for (final field in fields.whereType<Map>())
                _TicketFieldRow(
                  name: '${field['name'] ?? 'Campo'}',
                  value: '${field['value'] ?? '—'}',
                ),
            ],
            if (journals.isNotEmpty) ...[
              const Divider(height: AppSpacing.xxl),
              Text('Historial del ticket', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              for (final journal in journals.whereType<Map>())
                _TicketJournal(journal: journal),
            ],
          ],
        ),
      ),
    );
  }
}

class _TicketFact extends StatelessWidget {
  const _TicketFact({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _TicketFieldRow extends StatelessWidget {
  const _TicketFieldRow({required this.name, required this.value});
  final String name;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        SizedBox(
          width: 180,
          child: Text(
            name,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        SelectableText(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _TicketJournal extends StatelessWidget {
  const _TicketJournal({required this.journal});
  final Map journal;

  @override
  Widget build(BuildContext context) {
    final notes = journal['notes']?.toString().trim();
    final changes = journal['changes'] as List? ?? const [];
    final author = journal['user'] ?? journal['author'];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.border, width: 2)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  formatTicketTimestamp(journal['createdAt']),
                  if (author != null) author.toString(),
                ].join(' · '),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                SelectableText(notes),
              ],
              for (final change in changes.whereType<Map>())
                _TicketFieldRow(
                  name: '${change['field'] ?? 'Cambio'}',
                  value:
                      '${change['oldValue'] ?? '—'} → ${change['newValue'] ?? '—'}',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuditSection extends StatelessWidget {
  const _AuditSection({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card.outlined(
    color: AppColors.surfaceWhite,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    ),
  );
}

String _applicabilityLabel(Object? value) => switch (value) {
  'APPLIES' => 'Aplica',
  'NOT_APPLICABLE' => 'No aplica',
  'UNDETERMINED' => 'Indeterminada',
  _ => 'Sin determinar',
};

StatusTone _tone(VerificationResultStatus status) => switch (status) {
  VerificationResultStatus.complies => StatusTone.success,
  VerificationResultStatus.doesNotComply => StatusTone.danger,
  VerificationResultStatus.notApplicable => StatusTone.neutral,
  VerificationResultStatus.reviewRequired => StatusTone.warning,
  VerificationResultStatus.unknown => StatusTone.neutral,
};
