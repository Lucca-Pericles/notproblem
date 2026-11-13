import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';

class InvestigationPage extends StatelessWidget {
  const InvestigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.investigations,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Investigação com 5 Porquês',
            subtitle: 'Encontre uma causa provável, uma pergunta de cada vez.',
          ),
          const SizedBox(height: AppSpacing.lg),
          const _ProgressCard(),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 850) {
                return const Column(
                  children: [
                    _ContextCard(),
                    SizedBox(height: AppSpacing.lg),
                    _QuestionCard(),
                  ],
                );
              }

              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 260, child: _ContextCard()),
                  SizedBox(width: AppSpacing.lg),
                  Expanded(child: _QuestionCard()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Text(
              'Pergunta 3 de 5',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: AppSpacing.lg),
            const Expanded(
              child: LinearProgressIndicator(
                value: .6,
                minHeight: 10,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '60%',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Contexto',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ContextItem(
            icon: Icons.assignment_outlined,
            label: 'Tarefa',
            value: 'Implementar autenticação',
          ),
          const Divider(height: 32),
          const _ContextItem(
            icon: Icons.layers_outlined,
            label: 'Sprint',
            value: 'Sprint 04',
          ),
          const Divider(height: 32),
          const Text(
            'Status',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const StatusBadge(
            label: 'Em investigação',
            tone: BadgeTone.success,
          ),
          const Divider(height: 32),
          Text(
            'A tarefa foi concluída com 3 dias de atraso, impactando a entrega da Sprint.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ContextItem extends StatelessWidget {
  const _ContextItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusBadge(label: 'TERCEIRO PORQUÊ'),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Por que a revisão só aconteceu no fim da Sprint?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          const TextField(
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Escreva a resposta da equipe...',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _PreviousAnswers(),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.primary),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Não procure culpados',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'Concentre a resposta no processo e no que a equipe pode melhorar.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Voltar'),
              ),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Salvar e continuar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviousAnswers extends StatelessWidget {
  const _PreviousAnswers();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Respostas anteriores',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: AppSpacing.md),
          _AnswerItem(
            number: '1',
            question: 'Por que a tarefa atrasou?',
            answer: 'O código ficou aguardando revisão por vários dias.',
          ),
          Divider(height: 24),
          _AnswerItem(
            number: '2',
            question: 'Por que o código aguardou revisão?',
            answer: 'A revisão só aconteceu no fim da Sprint.',
          ),
        ],
      ),
    );
  }
}

class _AnswerItem extends StatelessWidget {
  const _AnswerItem({
    required this.number,
    required this.question,
    required this.answer,
  });

  final String number;
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.successSoft,
          foregroundColor: AppColors.success,
          child: Text(number),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(question, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.xs),
              Text(answer, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
