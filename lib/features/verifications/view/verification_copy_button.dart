import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VerificationCopyButton extends StatelessWidget {
  const VerificationCopyButton({
    super.key,
    required this.text,
    required this.label,
  });

  final String text;
  final String label;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () async {
      await Clipboard.setData(ClipboardData(text: text));
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Copiado al portapapeles.')));
    },
    icon: const Icon(Icons.copy_outlined, size: 18),
    label: Text(label),
  );
}
