import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/time/app_date.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../actions/domain/action_plan.dart';
import '../../../actions/domain/action_plan_repository.dart';
import '../../../occurrences/domain/occurrence.dart';
import '../../../occurrences/domain/occurrence_repository.dart';
import '../../domain/five_whys_investigation.dart';
import '../../domain/five_whys_repository.dart';

class InvestigationReviewPage extends StatefulWidget {
  const InvestigationReviewPage({
    required this.occurrenceId,
    this.occurrenceRepository,
    this.fiveWhysRepository,
    this.actionPlanRepository,
    super.key,
  });

  final String occurrenceId;
  final OccurrenceRepository? occurrenceRepository;
  final FiveWhysRepository? fiveWhysRepository;
  final ActionPlanRepository? actionPlanRepository;

  @override
  State<InvestigationReviewPage> createState() =>
      _InvestigationReviewPageState();
}

class _InvestigationReviewPageState extends State<InvestigationReviewPage> {
  Occurrence? _occurrence;
  FiveWhysInvestigation? _investigation;
  ActionPlan? _plan;
  bool _loading = true;
  bool _concluding = false;
  String? _error;

  bool get _isReady =>
      _occurrence?.status == OccurrenceStatus.investigating &&
      _investigation?.isCompleted == true &&
      _investigation?.isReadyForReview == true &&
      _planIsComplete;

  bool get _planIsComplete {
    final plan = _plan;
    if (plan == null || plan.status != ActionPlanStatus.draft) return false;
    bool valid(String value, int maxLength) {
      final length = value.trim().length;
      return length >= 2 && length <= maxLength;
    }

    return valid(plan.probableCause, 4000) &&
        valid(plan.action, 4000) &&
        valid(plan.responsible, 120) &&
        valid(plan.expectedResult, 4000) &&
        valid(plan.indicator, 500) &&
        !DateTime(plan.dueDate.year, plan.dueDate.month, plan.dueDate.day)
            .isBefore(saoPauloToday());
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final occurrenceRepository = widget.occurrenceRepository;
    final fiveWhysRepository = widget.fiveWhysRepository;
    final actionPlanRepository = widget.actionPlanRepository;
    if (widget.occurrenceId.isEmpty ||
        occurrenceRepository == null ||
        fiveWhysRepository == null ||
        actionPlanRepository == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final occurrence =
          await occurrenceRepository.getById(widget.occurrenceId);
      final investigation =
          await fiveWhysRepository.findByOccurrence(widget.occurrenceId);
      final plan =
          await actionPlanRepository.findByOccurrence(widget.occurrenceId);
      if (!mounted) return;
      setState(() {
        _occurrence = occurrence;
        _investigation = investigation;
        _plan = plan;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível carregar a revisão da investigação.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.investigations,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Revisar e concluir a investigação',
            subtitle:
                'Confirme se o registro representa a decisão da equipe antes de concluir.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return SectionCard(
        child: Column(
          children: [
            Text(_error!),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
                onPressed: _load, child: const Text('Tentar novamente')),
          ],
        ),
      );
    }
    if (_occurrence == null) {
      return const SectionCard(child: Text('Ocorrência não encontrada.'));
    }

    return Column(
      children: [
        _occurrenceCard(),
        const SizedBox(height: AppSpacing.lg),
        _fiveWhysCard(),
        const SizedBox(height: AppSpacing.lg),
        _actionPlanCard(),
        const SizedBox(height: AppSpacing.lg),
        _conclusionCard(),
      ],
    );
  }

  Widget _occurrenceCard() {
    final occurrence = _occurrence!;
    return SectionCard(
      title: 'Ocorrência',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  occurrence.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              StatusBadge(label: occurrence.status.label),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('${occurrence.project} · ${_formatDate(occurrence.occurredOn)}'),
          const Divider(height: AppSpacing.xl),
          _field('Contexto', occurrence.context),
          const Divider(height: AppSpacing.xl),
          _field('Impacto', occurrence.impact),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              key: const Key('editReviewContext'),
              onPressed:
                  _isEditable ? () => _open(AppRoutes.occurrenceDetail) : null,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar contexto'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fiveWhysCard() {
    final investigation = _investigation;
    return SectionCard(
      title: 'Respostas dos 5 Porquês',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (investigation == null || !investigation.isReadyForReview)
            const Text('As cinco respostas ainda não foram concluídas.')
          else
            for (var index = 0; index < 5; index++) ...[
              Text(
                '${index + 1}º porquê',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                investigation.questionFor(index + 1, _occurrence!.title),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(investigation.answers[index] ?? 'Não informado'),
              if (index < 4) const Divider(height: AppSpacing.xl),
            ],
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              key: const Key('editReviewFiveWhys'),
              onPressed:
                  _isEditable ? () => _open(AppRoutes.investigations) : null,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar respostas'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionPlanCard() {
    final plan = _plan;
    return SectionCard(
      title: 'Causa provável e plano de ação',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (plan == null)
            const Text(
                'A causa provável e o plano ainda não foram registrados.')
          else ...[
            const Text(
              'A causa é uma hipótese da equipe, não uma certeza do sistema.',
              style: TextStyle(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            _field('Causa provável', plan.probableCause),
            const Divider(height: AppSpacing.xl),
            _field('Ação', plan.action),
            const Divider(height: AppSpacing.xl),
            _field('Responsável', plan.responsible),
            const Divider(height: AppSpacing.xl),
            _field('Prazo', _formatDate(plan.dueDate)),
            const Divider(height: AppSpacing.xl),
            _field('Resultado esperado', plan.expectedResult),
            const Divider(height: AppSpacing.xl),
            _field('Indicador', plan.indicator),
          ],
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              key: const Key('editReviewActionPlan'),
              onPressed: _isEditable ? () => _open(AppRoutes.actions) : null,
              icon: const Icon(Icons.edit_outlined),
              label: Text(plan == null ? 'Registrar plano' : 'Editar plano'),
            ),
          ),
        ],
      ),
    );
  }

  bool get _isEditable =>
      _occurrence?.status == OccurrenceStatus.investigating &&
      _plan?.isFinalized != true;

  Widget _conclusionCard() {
    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _isReady ? Icons.fact_check_outlined : Icons.info_outline,
            color: _isReady ? AppColors.success : AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              _isReady
                  ? 'Tudo pronto. Ao concluir, a ocorrência passará para “Ação planejada”.'
                  : 'Para concluir, complete todas as etapas obrigatórias da investigação.',
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          FilledButton.icon(
            key: const Key('concludeInvestigation'),
            onPressed: _isReady && !_concluding ? _conclude : null,
            icon: _concluding
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: const Text('Concluir investigação'),
          ),
        ],
      ),
    );
  }

  Future<void> _open(String route) async {
    await Navigator.of(context).pushNamed(route, arguments: _occurrence!.id);
    if (mounted) await _load();
  }

  Future<void> _conclude() async {
    setState(() => _concluding = true);
    try {
      await widget.actionPlanRepository!.conclude(_occurrence!.id);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.actions,
        arguments: _occurrence!.id,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível concluir. Revise os dados e o prazo do plano.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _concluding = false);
    }
  }

  Widget _field(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text(value),
        ],
      );

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
