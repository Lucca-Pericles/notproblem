import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/widgets/auth_scope.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user!;

    return AppShell(
      currentRoute: AppRoutes.dashboard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Olá, ${user.name}',
            subtitle: 'Acompanhe as melhorias da sua equipe.',
            trailing: FilledButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.newOccurrence),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Registrar atraso'),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _MetricsGrid(),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 900;
              final recent = const _RecentInvestigations();
              final next = const _NextAction();

              if (stacked) {
                return const Column(
                  children: [
                    _RecentInvestigations(),
                    SizedBox(height: AppSpacing.lg),
                    _NextAction(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: recent),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: next),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          const _ResultsSummary(),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 600
                ? 2
                : 1;
        final width =
            (constraints.maxWidth - ((columns - 1) * AppSpacing.md)) / columns;

        const cards = [
          StatCard(
            label: 'Ocorrências',
            value: '8',
            icon: Icons.error_outline_rounded,
          ),
          StatCard(
            label: 'Em investigação',
            value: '2',
            icon: Icons.search_rounded,
          ),
          StatCard(
            label: 'Ações em andamento',
            value: '3',
            icon: Icons.bolt_rounded,
            color: AppColors.success,
          ),
          StatCard(
            label: 'Melhorias concluídas',
            value: '5',
            icon: Icons.check_rounded,
            color: AppColors.success,
          ),
        ];

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: cards.map((card) => SizedBox(width: width, child: card)).toList(),
        );
      },
    );
  }
}

class _RecentInvestigations extends StatelessWidget {
  const _RecentInvestigations();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Investigações recentes',
      child: Column(
        children: const [
          _InvestigationRow(
            title: 'API de autenticação',
            date: '07 nov',
            status: StatusBadge(label: 'Em investigação'),
          ),
          Divider(height: 32),
          _InvestigationRow(
            title: 'Tela de relatórios',
            date: '10 nov',
            status: StatusBadge(
              label: 'Ação planejada',
              tone: BadgeTone.warning,
            ),
          ),
          Divider(height: 32),
          _InvestigationRow(
            title: 'Correção do checkout',
            date: '03 nov',
            status: StatusBadge(
              label: 'Concluída',
              tone: BadgeTone.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvestigationRow extends StatelessWidget {
  const _InvestigationRow({
    required this.title,
    required this.date,
    required this.status,
  });

  final String title;
  final String date;
  final Widget status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.description_outlined, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        status,
        const SizedBox(width: AppSpacing.md),
        Text(date, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _NextAction extends StatelessWidget {
  const _NextAction();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Próxima ação',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Definir revisor no início da Sprint',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          const LinearProgressIndicator(
            value: .6,
            minHeight: 8,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _DetailRow(icon: Icons.person_outline, text: 'Marina'),
          const SizedBox(height: AppSpacing.md),
          const _DetailRow(icon: Icons.calendar_today_outlined, text: '15 nov'),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.actions),
              child: const Text('Ver acompanhamento'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(text),
      ],
    );
  }
}

class _ResultsSummary extends StatelessWidget {
  const _ResultsSummary();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Resultados das ações',
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const Row(
              children: [
                Expanded(
                  flex: 62,
                  child: ColoredBox(
                    color: AppColors.success,
                    child: SizedBox(height: 32),
                  ),
                ),
                Expanded(
                  flex: 25,
                  child: ColoredBox(
                    color: AppColors.warning,
                    child: SizedBox(height: 32),
                  ),
                ),
                Expanded(
                  flex: 13,
                  child: ColoredBox(
                    color: AppColors.danger,
                    child: SizedBox(height: 32),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _Legend(color: AppColors.success, label: 'Funcionou · 62%'),
              _Legend(color: AppColors.warning, label: 'Parcialmente · 25%'),
              _Legend(color: AppColors.danger, label: 'Não funcionou · 13%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
