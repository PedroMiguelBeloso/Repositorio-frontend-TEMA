import 'package:flutter/material.dart';

import '../model/service_models.dart';

class ProcessVersionSelector extends StatelessWidget {
  const ProcessVersionSelector({
    super.key,
    required this.groups,
    required this.selectedVersions,
    required this.onVersionSelected,
    required this.onProcessRemoved,
  });

  final List<AssignableProcessGroup> groups;
  final List<ProcessVersionOption> selectedVersions;
  final ValueChanged<ProcessVersionOption?> onVersionSelected;
  final ValueChanged<String> onProcessRemoved;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final group in groups) ...[
          _buildGroup(context, group),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildGroup(BuildContext context, AssignableProcessGroup group) {
    final selected = _selectedFor(group.process.id);
    final versions = group.publishedVersions;

    if (versions.isEmpty) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.account_tree_outlined),
          title: Text(group.process.name),
          subtitle: const Text(
            'No hay versiones publicadas. Primero publicá una versión en Procesos.',
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.process.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: selected?.id,
              decoration: const InputDecoration(
                labelText: 'Versión publicada',
              ),
              items: [
                for (final version in versions)
                  DropdownMenuItem(
                    value: version.id,
                    child: Text(version.officialVersion),
                  ),
              ],
              onChanged: (value) {
                final version = value == null
                    ? null
                    : versions.firstWhere((item) => item.id == value);
                onVersionSelected(version);
              },
            ),
            if (selected != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Asignada: versión ${selected.officialVersion}',
                    ),
                  ),
                  TextButton(
                    onPressed: () => onProcessRemoved(group.process.id),
                    child: const Text('Quitar'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  ProcessVersionOption? _selectedFor(String processId) {
    for (final version in selectedVersions) {
      if (version.processId == processId) return version;
    }
    return null;
  }
}
