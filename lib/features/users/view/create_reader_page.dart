import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/app_error_view.dart';
import '../viewmodel/create_reader_view_model.dart';

class CreateReaderPage extends ConsumerStatefulWidget {
  const CreateReaderPage({super.key});

  @override
  ConsumerState<CreateReaderPage> createState() => _CreateReaderPageState();
}

class _CreateReaderPageState extends ConsumerState<CreateReaderPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref
          .read(createReaderViewModelProvider.notifier)
          .createReader(
            _emailController.text.trim(),
            _nameController.text.trim(),
            _passwordController.text,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Lector creado. Comunique la contraseña inicial de forma segura.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
        context.pop(); // Volver al listado
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createReaderViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Crear Usuario Lector')),
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
                    fallbackMessage: 'No se pudo crear el usuario.',
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre visible'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty || !v.contains('@')) {
                    return 'Correo inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña inicial',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
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
                obscureText: _obscurePassword,
                decoration: const InputDecoration(
                  labelText: 'Confirmar contraseña inicial',
                ),
                validator: (v) {
                  if (v != _passwordController.text) {
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
                      child: const Text('Crear Usuario'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
