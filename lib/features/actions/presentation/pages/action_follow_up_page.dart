import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';

class ActionFollowUpPage extends StatelessWidget {
  const ActionFollowUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.actions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Acompanhar plano de ação',
            subtitle: 'Registre o resultado observado e o aprendizado da equipe.',
          ),
          const SizedBox(height: AppSpacing.lg),
          const _ActionSummary(),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 950) {
                return const Column(
                  children: [
                    _ActionTimeline(),
                    SizedBox(height: AppSpacing.lg),
                    _ResultCard(),
                    SizedBox(height: AppSpacing.lg),
                    _ActionDetails(),
                  ],
                );
              }

              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 240, child: _ActionTimeline()),
                  SizedBox(width: AppSpacing.lg),
                  Expanded(child: _ResultCard()),
                  SizedBox(width: AppSpacing.lg),
                  SizedBox(width: 250, child: _ActionDetails()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionSummary extends StatelessWidget {
  const _ActionSummary();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.md,
        children: const [
          _SummaryBlock(
            label: 'Ação',
            value: 'Definir revisor no início da Sprint',
          ),
          _SummaryBlock(
            label: 'Causa provável',
            value: 'Não havia responsável definido para revisar o código',
          ),
          _SummaryBlock(
            label: 'Status da ação',
            badge: StatusBadge(
              label: 'Em andamento',
              tone: BadgeTone.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.label, this.value, this.badge});

  final String label;
  final String? value;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          if (value != null)
            Text(value!, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (badge != null) badge!,
        ],
      ),
    );
  }
}

class _ActionTimeline extends StatelessWidget {
  const _ActionTimeline();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        children: const [
          _TimelineItem(
            title: 'Planejada',
            caption: 'Ação definida com a equipe',
            complete: true,
          ),
          _TimelineDivider(complete: true),
          _TimelineItem(
            title: 'Em andamento',
            caption: 'Aplicada na Sprint atual',
            complete: true,
          ),
          _TimelineDivider(),
          _TimelineItem(
            title: 'Avaliar resultado',
            caption: 'Registrar impacto e aprendizado',
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.caption,
    this.complete = false,
  });

  final String title;
  final String caption;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: complete ? AppColors.success : AppColors.infoSoft,
          foregroundColor: complete ? Colors.white : AppColors.primary,
          child: Icon(complete ? Icons.check : Icons.circle_outlined, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.xs),
              Text(caption, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineDivider extends StatelessWidget {
  const _TimelineDivider({this.complete = false});

  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 2,
        height: 34,
        margin: const EdgeInsets.only(left: 14),
        color: complete ? AppColors.success : AppColors.border,
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Resultado da ação',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Essa mudança ajudou?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 560;
              if (narrow) {
                return const Column(
                  children: [
                    _ResultChoice(
                      icon: Icons.check_rounded,
                      label: 'Funcionou',
                      tone: AppColors.success,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _ResultChoice(
                      icon: Icons.remove_rounded,
                      label: 'Parcialmente',
                      tone: AppColors.primary,
                      selected: true,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _ResultChoice(
                      icon: Icons.close_rounded,
                      label: 'Não funcionou',
                      tone: AppColors.danger,
                    ),
                  ],
                );
              }

              return const Row(
                children: [
                  Expanded(
                    child: _ResultChoice(
                      icon: Icons.check_rounded,
                      label: 'Funcionou',
                      tone: AppColors.success,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ResultChoice(
                      icon: Icons.remove_rounded,
                      label: 'Parcialmente',
                      tone: AppColors.primary,
                      selected: true,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ResultChoice(
                      icon: Icons.close_rounded,
                      label: 'Não funcionou',
                      tone: AppColors.danger,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'O que a equipe aprendeu?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          const TextField(
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Registre o aprendizado desta tentativa...',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.check_rounded),
              label: const Text('Concluir acompanhamento'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultChoice extends StatelessWidget {
  const _ResultChoice({
    required this.icon,
    required this.label,
    required this.tone,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final Color tone;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: selected ? AppColors.infoSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: tone, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ActionDetails extends StatelessWidget {
  const _ActionDetails();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Detalhes da ação',
      child: Column(
        children: const [
          _Detail(icon: Icons.person_outline, text: 'Marina'),
          Divider(height: 32),
          _Detail(icon: Icons.calendar_today_outlined, text: '15 nov'),
          Divider(height: 32),
          _Detail(
            icon: Icons.bar_chart_rounded,
            text: 'Tempo até a primeira revisão',
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text)),
      ],
    );
  }
}
