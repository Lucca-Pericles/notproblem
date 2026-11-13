import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.history,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Histórico',
            subtitle:
                'Consulte investigações concluídas e aprendizados registrados.',
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionCard(
            child: Column(
              children: const [
                _HistoryTile(
                  title: 'Corrigir fluxo do checkout',
                  cause: 'Critérios de aceite estavam incompletos',
                  result: 'Funcionou',
                  tone: BadgeTone.success,
                  date: '03 nov',
                ),
                Divider(height: 32),
                _HistoryTile(
                  title: 'Criar relatório de indicadores',
                  cause: 'Dependência externa não foi refinada',
                  result: 'Parcialmente',
                  tone: BadgeTone.warning,
                  date: '25 out',
                ),
                Divider(height: 32),
                _HistoryTile(
                  title: 'Atualizar documentação da API',
                  cause: 'Responsabilidade não estava definida',
                  result: 'Não funcionou',
                  tone: BadgeTone.danger,
                  date: '18 out',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.title,
    required this.cause,
    required this.result,
    required this.tone,
    required this.date,
  });

  final String title;
  final String cause;
  final String result;
  final BadgeTone tone;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(child: Icon(Icons.history_rounded)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.xs),
              Text(cause, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        StatusBadge(label: result, tone: tone),
        const SizedBox(width: AppSpacing.md),
        Text(date, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
