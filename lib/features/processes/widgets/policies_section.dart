import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../model/process_models.dart';
import '../viewmodel/process_editor_view_model.dart';

class PoliciesSection extends StatelessWidget {
  const PoliciesSection({
    super.key,
    required this.policies,
    required this.readOnly,
    required this.validationErrors,
    required this.onAdd,
    required this.onTextChanged,
    required this.onDelete,
    required this.onMove,
  });

  final List<ProcessPolicy> policies;
  final bool readOnly;
  final Map<String, String> validationErrors;
  final VoidCallback onAdd;
  final void Function(String localKey, String value) onTextChanged;
  final ValueChanged<String> onDelete;
  final void Function(String localKey, int delta) onMove;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Políticas',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  if (!readOnly)
                    OutlinedButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar política'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              if (policies.isEmpty)
                const EmptyState(
                  message: 'No hay políticas cargadas.',
                  icon: Icons.policy_outlined,
                )
              else
                for (var index = 0; index < policies.length; index++) ...[
                  _PolicyCard(
                    policy: policies[index],
                    index: index,
                    count: policies.length,
                    readOnly: readOnly,
                    errorText: validationErrors[
                      ProcessEditorFieldKeys.policyText(
                        policies[index].localKey,
                      )
                    ],
                    onTextChanged: onTextChanged,
                    onDelete: onDelete,
                    onMove: onMove,
                  ),
                  if (index + 1 < policies.length)
                    const SizedBox(height: AppSpacing.md),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({
    required this.policy,
    required this.index,
    required this.count,
    required this.readOnly,
    required this.errorText,
    required this.onTextChanged,
    required this.onDelete,
    required this.onMove,
  });

  final ProcessPolicy policy;
  final int index;
  final int count;
  final bool readOnly;
  final String? errorText;
  final void Function(String localKey, String value) onTextChanged;
  final ValueChanged<String> onDelete;
  final void Function(String localKey, int delta) onMove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Política ${index + 1}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (!readOnly) ...[
                  IconButton(
                    tooltip: 'Subir política',
                    onPressed: index == 0
                        ? null
                        : () => onMove(policy.localKey, -1),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  IconButton(
                    tooltip: 'Bajar política',
                    onPressed: index + 1 == count
                        ? null
                        : () => onMove(policy.localKey, 1),
                    icon: const Icon(Icons.arrow_downward),
                  ),
                  IconButton(
                    tooltip: 'Eliminar política',
                    onPressed: () => onDelete(policy.localKey),
                    color: theme.colorScheme.error,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (readOnly)
              Text(policy.text.trim().isEmpty ? 'Sin completar' : policy.text)
            else
              TextFormField(
                key: ValueKey('policy-${policy.localKey}-${policy.id ?? 'new'}'),
                initialValue: policy.text,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Texto de la política',
                  alignLabelWithHint: true,
                  errorText: errorText,
                ),
                onChanged: (value) => onTextChanged(policy.localKey, value),
              ),
          ],
        ),
      ),
    );
  }
}
