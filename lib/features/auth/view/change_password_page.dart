import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/app_error_view.dart';
import '../viewmodel/change_password_view_model.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref
          .read(changePasswordViewModelProvider.notifier)
          .changePassword(_currentController.text, _newController.text);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña actualizada. Inicie sesión nuevamente.'),
          ),
        );
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar mi contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (state.hasError)
                AppErrorView(
                  failure: safeAppFailure(
                    state.error,
                    fallbackMessage: 'No se pudo cambiar la contraseña.',
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _currentController,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Contraseña actual',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _newController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Requerido';
                  }
                  if (v.length < 8) return 'Debe tener al menos 8 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureNew,
                decoration: const InputDecoration(
                  labelText: 'Confirmar nueva contraseña',
                ),
                validator: (v) {
                  if (v != _newController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
              state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton(
                      onPressed: _submit,
                      child: const Text('Guardar contraseña'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
