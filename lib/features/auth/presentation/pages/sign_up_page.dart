import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_form_shell.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({required this.controller, super.key});

  final AuthController controller;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return AuthFormShell(
          title: 'Criar conta',
          subtitle: 'Salve suas investigações com segurança.',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.controller.errorMessage != null) ...[
                  AuthErrorBanner(message: widget.controller.errorMessage!),
                  const SizedBox(height: AppSpacing.md),
                ],
                TextFormField(
                  key: const Key('signUpName'),
                  controller: _nameController,
                  enabled: !widget.controller.isSubmitting,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) => (value?.trim().length ?? 0) < 2
                      ? 'Informe seu nome.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('signUpEmail'),
                  controller: _emailController,
                  enabled: !widget.controller.isSubmitting,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('signUpPassword'),
                  controller: _passwordController,
                  enabled: !widget.controller.isSubmitting,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    helperText: 'Mínimo de 8 caracteres, com letra e número.',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('signUpPasswordConfirmation'),
                  controller: _confirmPasswordController,
                  enabled: !widget.controller.isSubmitting,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(
                    labelText: 'Confirmar senha',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (value) => value != _passwordController.text
                      ? 'As senhas não coincidem.'
                      : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  key: const Key('signUpSubmit'),
                  onPressed: widget.controller.isSubmitting ? null : _submit,
                  child: widget.controller.isSubmitting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Criar conta'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: widget.controller.isSubmitting
                      ? null
                      : () {
                          widget.controller.clearError();
                          Navigator.of(context).pop();
                        },
                  child: const Text('Já tenho uma conta'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    return valid ? null : 'Informe um e-mail válido.';
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 8) return 'Use pelo menos 8 caracteres.';
    if (!RegExp('[A-Za-z]').hasMatch(password) ||
        !RegExp('[0-9]').hasMatch(password)) {
      return 'Inclua pelo menos uma letra e um número.';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final result = await widget.controller.signUp(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted || result == null) return;

    if (result.requiresEmailConfirmation) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirme seu e-mail'),
          content: const Text(
            'Enviamos um link de confirmação. Depois de confirmar, volte para entrar.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );

      if (mounted) Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.dashboard,
        (route) => false,
      );
    }
  }
}
