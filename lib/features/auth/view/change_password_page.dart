import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
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
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(changePasswordViewModelProvider.notifier)
        .changePassword(_currentController.text, _newController.text);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada. Iniciá sesión nuevamente.'),
        ),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Seguridad de la cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'MI CUENTA',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Cambiar mi contraseña',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Usá una contraseña nueva de al menos 8 caracteres. '
                    'Al guardarla, tendrás que iniciar sesión nuevamente.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (state.hasError) ...[
                              AppErrorView(
                                failure: safeAppFailure(
                                  state.error,
                                  fallbackMessage:
                                      'No se pudo cambiar la contraseña.',
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                            ],
                            Text(
                              'Verificación de identidad',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _currentController,
                              obscureText: _obscureCurrent,
                              autofillHints: const [AutofillHints.password],
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Contraseña actual',
                                suffixIcon: IconButton(
                                  tooltip: _obscureCurrent
                                      ? 'Mostrar contraseña actual'
                                      : 'Ocultar contraseña actual',
                                  icon: Icon(
                                    _obscureCurrent
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureCurrent = !_obscureCurrent,
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Ingresá tu contraseña actual'
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            const Divider(),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Nueva contraseña',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _newController,
                              obscureText: _obscureNew,
                              autofillHints: const [AutofillHints.newPassword],
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Contraseña nueva',
                                helperText: 'Mínimo 8 caracteres',
                                suffixIcon: IconButton(
                                  tooltip: _obscureNew
                                      ? 'Mostrar contraseña nueva'
                                      : 'Ocultar contraseña nueva',
                                  icon: Icon(
                                    _obscureNew
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureNew = !_obscureNew,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresá una contraseña nueva';
                                }
                                if (value.length < 8) {
                                  return 'Debe tener al menos 8 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            TextFormField(
                              controller: _confirmController,
                              obscureText: _obscureConfirm,
                              autofillHints: const [AutofillHints.newPassword],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) {
                                if (!state.isLoading) _submit();
                              },
                              decoration: InputDecoration(
                                labelText: 'Confirmar contraseña nueva',
                                suffixIcon: IconButton(
                                  tooltip: _obscureConfirm
                                      ? 'Mostrar confirmación'
                                      : 'Ocultar confirmación',
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                ),
                              ),
                              validator: (value) => value != _newController.text
                                  ? 'Las contraseñas no coinciden'
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                TextButton(
                                  onPressed: state.isLoading
                                      ? null
                                      : () => context.go(RouteNames.homePath),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton.icon(
                                  onPressed: state.isLoading ? null : _submit,
                                  icon: state.isLoading
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.lock_reset_outlined),
                                  label: Text(
                                    state.isLoading
                                        ? 'Guardando…'
                                        : 'Guardar contraseña',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
