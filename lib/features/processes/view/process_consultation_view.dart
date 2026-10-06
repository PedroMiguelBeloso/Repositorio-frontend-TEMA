import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../model/process_models.dart';

/// Read-only presentation of the information saved in a process version.
class ProcessConsultationView extends StatefulWidget {
  const ProcessConsultationView({
    super.key,
    required this.definition,
    required this.version,
  });

  final ProcessDefinition definition;
  final ProcessVersion version;

  @override
  State<ProcessConsultationView> createState() =>
      _ProcessConsultationViewState();
}

class _ProcessConsultationViewState extends State<ProcessConsultationView> {
  final Map<String, GlobalKey> _macroKeys = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final macros = [...widget.version.macroActivities]
      ..sort((a, b) => a.order.compareTo(b.order));
    final policies = [...widget.version.policies]
      ..sort((a, b) => a.order.compareTo(b.order));

    return ColoredBox(
      color: AppColors.canvas,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        thickness: 8,
        radius: const Radius.circular(4),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 64),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProcessHeader(
                    definition: widget.definition,
                    version: widget.version,
                  ),
                  const SizedBox(height: 32),
                  _Policies(policies: policies),
                  const SizedBox(height: 40),
                  _Heading(
                    title: 'Recorrido del proceso',
                    subtitle:
                        'Las entradas alimentan las actividades. Cada actividad puede generar registros; al final aparecen las salidas de la macroactividad.',
                  ),
                  const SizedBox(height: 16),
                  if (macros.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var index = 0; index < macros.length; index++)
                          OutlinedButton(
                            onPressed: () {
                              final target = _macroKeys[macros[index].localKey]
                                  ?.currentContext;
                              if (target == null) return;
                              Scrollable.ensureVisible(
                                target,
                                duration: const Duration(milliseconds: 250),
                                alignment: 0.03,
                              );
                            },
                            child: Text(
                              '${index + 1}. ${_text(macros[index].name)}',
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  if (macros.isEmpty)
                    const _Missing(
                      'Todavía no se configuraron macroactividades en esta versión.',
                    ),
                  for (var index = 0; index < macros.length; index++) ...[
                    KeyedSubtree(
                      key: _macroKeys.putIfAbsent(
                        macros[index].localKey,
                        GlobalKey.new,
                      ),
                      child: _MacroActivity(
                        macro: macros[index],
                        number: index + 1,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProcessHeader extends StatelessWidget {
  const _ProcessHeader({required this.definition, required this.version});

  final ProcessDefinition definition;
  final ProcessVersion version;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Semantics(
              header: true,
              child: Text(
                definition.displayName,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _VersionStatus(status: version.status),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 20,
          runSpacing: 8,
          children: [
            _Meta('Versión', version.officialVersion),
            _Meta(
              'Fecha',
              DateFormat('dd/MM/yyyy').format(version.versionDate),
            ),
            _Meta('Responsable', _text(version.owner)),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Objetivo', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_text(version.objective), style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _VersionStatus extends StatelessWidget {
  const _VersionStatus({required this.status});
  final ProcessVersionStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ProcessVersionStatus.published => AppColors.success,
      ProcessVersionStatus.draft => AppColors.warning,
      _ => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: '$label: ',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        TextSpan(
          text: value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
    style: Theme.of(context).textTheme.bodyMedium,
  );
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Text(
          subtitle!,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    ],
  );
}

class _Policies extends StatelessWidget {
  const _Policies({required this.policies});
  final List<ProcessPolicy> policies;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Heading(title: 'Políticas del proceso'),
      const SizedBox(height: 12),
      if (policies.isEmpty)
        const _Missing('Todavía no se configuraron políticas en esta versión.')
      else
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Column(
            children: [
              for (var index = 0; index < policies.length; index++) ...[
                if (index > 0) const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${index + 1}.',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(color: AppColors.primary),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          policies[index].text,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
    ],
  );
}

class _MacroActivity extends StatelessWidget {
  const _MacroActivity({required this.macro, required this.number});
  final ProcessMacroActivity macro;
  final int number;

  @override
  Widget build(BuildContext context) {
    final activities = [...macro.activities]
      ..sort((a, b) => a.order.compareTo(b.order));
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadii.card),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Macroactividad $number',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Semantics(
                  header: true,
                  child: Text(
                    _text(macro.name),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (macro.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(macro.description),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EvidenceSection(
                  title: 'Entradas',
                  emptyMessage: 'No se configuraron entradas.',
                  items: macro.inputs,
                  icon: Icons.arrow_downward,
                ),
                const SizedBox(height: 26),
                Text(
                  'Actividades',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                if (activities.isEmpty)
                  const _Missing('No se configuraron actividades.')
                else
                  for (var index = 0; index < activities.length; index++) ...[
                    if (index > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Divider(
                          key: Key('activity-divider-$index'),
                          height: 1,
                        ),
                      ),
                    _Activity(activity: activities[index], number: index + 1),
                  ],
                const SizedBox(height: 26),
                _EvidenceSection(
                  title: 'Salidas',
                  emptyMessage: 'No se configuraron salidas.',
                  items: macro.outputs,
                  icon: Icons.arrow_outward,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Activity extends StatelessWidget {
  const _Activity({required this.activity, required this.number});
  final ProcessActivity activity;
  final int number;

  @override
  Widget build(BuildContext context) {
    final instructionText = activity.instructions.trim();
    return Card.outlined(
      key: Key('activity-card-$number'),
      margin: EdgeInsets.zero,
      color: AppColors.surfaceWhite,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            color: AppColors.primary.withValues(alpha: 0.06),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$number',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.surfaceWhite,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actividad $number',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.primary),
                      ),
                      Semantics(
                        header: true,
                        child: Text(
                          _text(activity.name),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    if (activity.responsible.trim().isNotEmpty)
                      _Meta('Responsable', activity.responsible),
                    if (activity.etaText.trim().isNotEmpty)
                      _Meta('Plazo', activity.etaText),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Instrucciones',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (instructionText.isEmpty)
                  const _Missing('No se cargaron instrucciones.')
                else
                  Text(instructionText),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _EvidenceSection(
                  title: 'Registros de esta actividad',
                  emptyMessage:
                      'No se configuraron registros para esta actividad.',
                  items: activity.records,
                  icon: Icons.description_outlined,
                  compact: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceSection extends StatelessWidget {
  const _EvidenceSection({
    required this.title,
    required this.emptyMessage,
    required this.items,
    required this.icon,
    this.compact = false,
  });

  final String title;
  final String emptyMessage;
  final List<EvidenceExpectation> items;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final sorted = [...items]..sort((a, b) => a.order.compareTo(b.order));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (sorted.isEmpty)
          compact
              ? Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: _Missing(emptyMessage)),
                    ],
                  ),
                )
              : _Missing(emptyMessage)
        else
          for (var index = 0; index < sorted.length; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            _EvidenceRow(item: sorted[index]),
          ],
      ],
    );
  }
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({required this.item});
  final EvidenceExpectation item;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: AppColors.canvas,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _text(item.displayName),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 12,
          runSpacing: 3,
          children: [
            _EvidenceFact(
              'Tipo de evidencia',
              item.evidenceType.label,
              AppColors.textPrimary,
            ),
            _EvidenceFact(
              'Cuándo aplica',
              item.applicability.label,
              item.applicability == ApplicabilityMode.caseDependent
                  ? AppColors.warning
                  : AppColors.textSecondary,
            ),
            _EvidenceFact(
              'Cantidad requerida',
              item.cardinality.label,
              AppColors.textSecondary,
            ),
          ],
        ),
        if (item.officialNomenclature?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 5),
          Text(
            'Nomenclatura: ${item.officialNomenclature}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    ),
  );
}

class _EvidenceFact extends StatelessWidget {
  const _EvidenceFact(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: '$label: ',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        TextSpan(
          text: value,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    ),
    style: Theme.of(context).textTheme.labelMedium,
  );
}

class _Missing extends StatelessWidget {
  const _Missing(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Text(
    message,
    style: Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
  );
}

String _text(String value) =>
    value.trim().isEmpty ? 'Sin completar' : value.trim();
