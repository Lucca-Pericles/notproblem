import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_form_shell.dart';

class EmailConfirmedPage extends StatelessWidget {
  const EmailConfirmedPage({required this.controller, super.key});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return AuthFormShell(
      title: 'E-mail confirmado',
      subtitle: 'Sua conta foi confirmada com sucesso.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.mark_email_read_outlined,
            size: 56,
            color: Colors.green,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Agora você pode entrar com seu e-mail e senha.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            key: const Key('emailConfirmedGoToSignIn'),
            onPressed: () async {
              await controller.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.signIn,
                (route) => false,
              );
            },
            child: const Text('Ir para login'),
          ),
        ],
      ),
    );
  }
}
