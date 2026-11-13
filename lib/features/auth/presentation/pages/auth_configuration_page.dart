import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../widgets/auth_form_shell.dart';

class AuthConfigurationPage extends StatelessWidget {
  const AuthConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthFormShell(
      title: 'Configuração necessária',
      subtitle: 'Conecte o aplicativo ao projeto Supabase antes de entrar.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Inicie o Flutter informando SUPABASE_URL e '
            'SUPABASE_PUBLISHABLE_KEY por --dart-define ou '
            '--dart-define-from-file.',
          ),
          SizedBox(height: AppSpacing.md),
          SelectableText(
            'flutter run --dart-define-from-file=config/dev.json',
            style: TextStyle(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
