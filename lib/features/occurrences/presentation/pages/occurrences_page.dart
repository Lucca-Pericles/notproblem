import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';

class OccurrencesPage extends StatelessWidget {
  const OccurrencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.occurrences,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Ocorrências',
            subtitle: 'Registros de tarefas que sofreram atraso.',
            trailing: FilledButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.newOccurrence),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nova ocorrência'),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionCard(
            child: Column(
              children: const [
                _OccurrenceTile(
                  title: 'Implementar autenticação de usuários',
                  project: 'Sprint 04',
                  date: '07 nov',
                  badge: StatusBadge(label: 'Em investigação'),
                ),
                Divider(height: 32),
                _OccurrenceTile(
                  title: 'Criar tela de relatórios',
                  project: 'Sprint 03',
                  date: '02 nov',
                  badge: StatusBadge(
                    label: 'Ação planejada',
                    tone: BadgeTone.warning,
                  ),
                ),
                Divider(height: 32),
                _OccurrenceTile(
                  title: 'Corrigir fluxo do checkout',
                  project: 'Sprint 02',
                  date: '28 out',
                  badge: StatusBadge(
                    label: 'Concluída',
                    tone: BadgeTone.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OccurrenceTile extends StatelessWidget {
  const _OccurrenceTile({
    required this.title,
    required this.project,
    required this.date,
    required this.badge,
  });

  final String title;
  final String project;
  final String date;
  final Widget badge;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.assignment_outlined)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('$project · $date'),
      trailing: badge,
    );
  }
}
