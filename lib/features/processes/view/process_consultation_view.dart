import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/status_chip.dart';
import '../model/process_models.dart';

/// Reading surface for a process version. Draft editing remains in the editor.
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
  final Map<String, GlobalKey> _sectionKeys = {};

  void _jumpTo(String key) {
    final target = _sectionKeys[key]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: 0.03,
    );
  }

  @override
  Widget build(BuildContext context) {
    final version = widget.version;
    final macros = [...version.macroActivities]
      ..sort((a, b) => a.order.compareTo(b.order));
    final activityCount = macros.fold<int>(
      0,
      (total, macro) => total + macro.activities.length,
    );
    final evidenceCount = macros.fold<int>(
      0,
      (total, macro) =>
          total +
          macro.inputs.length +
          macro.outputs.length +
          macro.activities.fold<int>(
            0,
            (count, activity) => count + activity.records.length,
          ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1080;
        final content = SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            wide ? AppSpacing.xxl : AppSpacing.lg,
            AppSpacing.xl,
            wide ? AppSpacing.xxl : AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProcessHero(
                    definition: widget.definition,
                    version: version,
                    macroCount: macros.length,
                    activityCount: activityCount,
                    evidenceCount: evidenceCount,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _SectionHeading(
                    eyebrow: '01 / ESTRUCTURA',
                    title: 'Cómo se desarrolla el proceso',
                    description:
                        'Cada macroactividad reúne sus entradas, actividades y salidas. '
                        'Los registros de cada actividad se muestran dentro de ella.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (!wide && macros.isNotEmpty) ...[
                    _CompactOutline(macros: macros, onSelect: _jumpTo),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (macros.isEmpty)
                    const _EmptySection(
                      message:
                          'Esta versión todavía no tiene macroactividades.',
                    ),
                  for (var index = 0; index < macros.length; index++) ...[
                    KeyedSubtree(
                      key: _sectionKeys.putIfAbsent(
                        macros[index].localKey,
                        GlobalKey.new,
                      ),
                      child: _MacroSection(macro: macros[index], index: index),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _SectionHeading(
                    eyebrow: '02 / MARCO DEL PROCESO',
                    title: 'Políticas',
                    description:
                        'Criterios generales que acompañan a esta versión.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _PoliciesCard(policies: version.policies),
                ],
              ),
            ),
          ),
        );

        if (!wide) return content;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 236,
              child: _ProcessOutline(macros: macros, onSelect: _jumpTo),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ],
        );
      },
    );
  }
}

class _ProcessHero extends StatelessWidget {
  const _ProcessHero({
    required this.definition,
    required this.version,
    required this.macroCount,
    required this.activityCount,
    required this.evidenceCount,
  });

  final ProcessDefinition definition;
  final ProcessVersion version;
  final int macroCount;
  final int activityCount;
  final int evidenceCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateFormat('dd/MM/yyyy').format(version.versionDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadii.dialog),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadii.dialog),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FICHA DEL PROCESO',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.lg,
                      runSpacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            definition.displayName,
                            style: theme.textTheme.headlineMedium,
                          ),
                        ),
                        StatusChip(
                          label: version.status.label,
                          tone: version.status == ProcessVersionStatus.published
                              ? StatusTone.success
                              : version.status == ProcessVersionStatus.draft
                              ? StatusTone.warning
                              : StatusTone.neutral,
                        ),
                        const StatusChip(
                          label: 'Modo consulta',
                          tone: StatusTone.neutral,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'OBJETIVO',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _display(version.objective),
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Divider(),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.xxxl,
                      runSpacing: AppSpacing.lg,
                      children: [
                        _MetaItem(
                          label: 'Versión oficial',
                          value: version.officialVersion,
                        ),
                        _MetaItem(label: 'Fecha de versión', value: date),
                        _MetaItem(
                          label: 'Responsable',
                          value: _display(version.owner),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _Metric(
              value: macroCount,
              label: 'Macroactividades',
              icon: Icons.account_tree_outlined,
            ),
            _Metric(
              value: activityCount,
              label: 'Actividades',
              icon: Icons.view_agenda_outlined,
            ),
            _Metric(
              value: evidenceCount,
              label: 'Registros esperados',
              icon: Icons.inventory_2_outlined,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 150, maxWidth: 260),
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
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, required this.icon});
  final int value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 188),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    decoration: BoxDecoration(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(AppRadii.card),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: AppSpacing.md),
        Text('$value', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
  });
  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.primary,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        description,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    ],
  );
}

class _ProcessOutline extends StatelessWidget {
  const _ProcessOutline({required this.macros, required this.onSelect});
  final List<ProcessMacroActivity> macros;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.surfaceWhite,
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'EN ESTA VERSIÓN',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < macros.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: TextButton(
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.md,
                  ),
                ),
                onPressed: () => onSelect(macros[i].localKey),
                child: Text(
                  '${i + 1}. ${_display(macros[i].name)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _CompactOutline extends StatelessWidget {
  const _CompactOutline({required this.macros, required this.onSelect});
  final List<ProcessMacroActivity> macros;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      for (var i = 0; i < macros.length; i++)
        ActionChip(
          label: Text('${i + 1}. ${_display(macros[i].name)}'),
          onPressed: () => onSelect(macros[i].localKey),
        ),
    ],
  );
}

class _MacroSection extends StatelessWidget {
  const _MacroSection({required this.macro, required this.index});
  final ProcessMacroActivity macro;
  final int index;

  @override
  Widget build(BuildContext context) {
    final activities = [...macro.activities]
      ..sort((a, b) => a.order.compareTo(b.order));
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.dialog),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadii.control),
                  ),
                  child: Text(
                    '${index + 1}'.padLeft(2, '0'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MACROACTIVIDAD ${index + 1}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Semantics(
                        header: true,
                        child: Text(
                          _display(macro.name),
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      if (macro.description.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          macro.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EvidenceGroup(
                  title: 'Entradas',
                  icon: Icons.login_rounded,
                  items: macro.inputs,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'ACTIVIDADES',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (activities.isEmpty)
                  const _EmptySection(
                    message: 'No hay actividades configuradas.',
                  ),
                for (var i = 0; i < activities.length; i++) ...[
                  _ActivitySection(activity: activities[i], index: i),
                  if (i + 1 < activities.length)
                    const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.xl),
                _EvidenceGroup(
                  title: 'Salidas',
                  icon: Icons.logout_rounded,
                  items: macro.outputs,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.activity, required this.index});
  final ProcessActivity activity;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${index + 1}'.padLeft(2, '0'),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    _display(activity.name),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
            ],
          ),
          if (activity.instructions.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(activity.instructions, style: theme.textTheme.bodyMedium),
          ],
          if (activity.responsible.trim().isNotEmpty ||
              activity.etaText.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xl,
              runSpacing: AppSpacing.sm,
              children: [
                if (activity.responsible.trim().isNotEmpty)
                  _InlineFact(
                    icon: Icons.person_outline,
                    label: 'Responsable',
                    value: activity.responsible,
                  ),
                if (activity.etaText.trim().isNotEmpty)
                  _InlineFact(
                    icon: Icons.schedule_outlined,
                    label: 'Plazo informativo',
                    value: activity.etaText,
                  ),
              ],
            ),
          ],
          if (activity.records.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            _EvidenceGroup(
              title: 'Registros de la actividad',
              icon: Icons.description_outlined,
              items: activity.records,
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineFact extends StatelessWidget {
  const _InlineFact({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 250),
    child: Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    ),
  );
}

class _EvidenceGroup extends StatelessWidget {
  const _EvidenceGroup({
    required this.title,
    required this.icon,
    required this.items,
  });
  final String title;
  final IconData icon;
  final List<EvidenceExpectation> items;

  @override
  Widget build(BuildContext context) {
    final sorted = [...items]..sort((a, b) => a.order.compareTo(b.order));
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${sorted.length}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (sorted.isEmpty)
          Text(
            'Sin registros configurados.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        for (final item in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadii.control),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _display(item.displayName),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${item.evidenceType.label} · ${item.applicability.label} · ${item.cardinality.label}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (item.officialNomenclature?.trim().isNotEmpty == true)
                    Text(
                      'Nomenclatura: ${item.officialNomenclature}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PoliciesCard extends StatelessWidget {
  const _PoliciesCard({required this.policies});
  final List<ProcessPolicy> policies;

  @override
  Widget build(BuildContext context) {
    final sorted = [...policies]..sort((a, b) => a.order.compareTo(b.order));
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.dialog),
      ),
      child: sorted.isEmpty
          ? const Text('No hay políticas configuradas.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < sorted.length; i++) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          sorted[i].text,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  if (i + 1 < sorted.length) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ],
              ],
            ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: BoxDecoration(
      color: AppColors.surfaceWhite,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(AppRadii.card),
    ),
    child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
  );
}

String _display(String value) =>
    value.trim().isEmpty ? 'Sin completar' : value.trim();
