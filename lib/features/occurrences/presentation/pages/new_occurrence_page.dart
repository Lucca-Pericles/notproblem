import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/section_card.dart';

class NewOccurrencePage extends StatelessWidget {
  const NewOccurrencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.newOccurrence,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Registrar novo atraso',
            subtitle:
                'Conte o que aconteceu. Você poderá investigar as causas na próxima etapa.',
          ),
          const SizedBox(height: AppSpacing.xl),
          const _FlowSteps(active: 0),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 900;
              const form = _OccurrenceForm();
              const tips = _TipsCard();

              if (stacked) {
                return const Column(
                  children: [
                    _OccurrenceForm(),
                    SizedBox(height: AppSpacing.lg),
                    _TipsCard(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: form),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: tips),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FlowSteps extends StatelessWidget {
  const _FlowSteps({required this.active});

  final int active;

  @override
  Widget build(BuildContext context) {
    const labels = ['Contexto', 'Investigação', 'Plano de ação', 'Resultado'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: List.generate(labels.length, (index) {
            final selected = index == active;
            return Expanded(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        selected ? AppColors.primary : AppColors.infoSoft,
                    foregroundColor:
                        selected ? Colors.white : AppColors.textSecondary,
                    child: Text('${index + 1}'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (index < labels.length - 1)
                    const Expanded(
                      child: Divider(indent: 12, endIndent: 12),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _OccurrenceForm extends StatelessWidget {
  const _OccurrenceForm();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('Título da tarefa'),
          const TextField(
            decoration: InputDecoration(
              hintText: 'Ex.: Implementar autenticação de usuários',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Sprint ou projeto'),
                    TextField(
                      decoration: InputDecoration(hintText: 'Ex.: Sprint 04'),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Quando aconteceu?'),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Selecione uma data',
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _FieldLabel('O que estava previsto?'),
          const TextField(
            decoration: InputDecoration(
              hintText: 'Descreva a entrega e o prazo esperado.',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _FieldLabel('O que causou impacto?'),
          const TextField(
            decoration: InputDecoration(
              hintText: 'Ex.: Dependência de outra tarefa',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _FieldLabel('Conte o contexto'),
          const TextField(
            maxLines: 5,
            decoration: InputDecoration(
              hintText:
                  'Explique o que aconteceu, incluindo decisões e dependências.',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.maybePop(context),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: () {},
                child: const Text('Salvar e investigar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'O que registrar?',
      child: Column(
        children: const [
          _Tip(
            icon: Icons.gps_fixed_rounded,
            title: 'Seja específico',
            text: 'Descreva a tarefa, o esperado e quando o atraso ocorreu.',
          ),
          SizedBox(height: AppSpacing.lg),
          _Tip(
            icon: Icons.layers_outlined,
            title: 'Aponte o impacto',
            text: 'Registre o que mudou no prazo, escopo ou entrega.',
          ),
          SizedBox(height: AppSpacing.lg),
          _Tip(
            icon: Icons.notes_rounded,
            title: 'Traga o contexto',
            text: 'Inclua somente informações úteis para a investigação.',
          ),
          SizedBox(height: AppSpacing.xl),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.success),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Seus registros são privados.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.success),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.xs),
              Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
