import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/time/app_date.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../investigations/domain/five_whys_investigation.dart';
import '../../../investigations/domain/five_whys_repository.dart';
import '../../../occurrences/domain/occurrence.dart';
import '../../../occurrences/domain/occurrence_repository.dart';
import '../../domain/action_plan.dart';
import '../../domain/action_plan_repository.dart';

class ActionFollowUpPage extends StatefulWidget {
  const ActionFollowUpPage({
    this.occurrenceId = '',
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
  State<ActionFollowUpPage> createState() => _ActionFollowUpPageState();
}

class _ActionFollowUpPageState extends State<ActionFollowUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateFieldKey = GlobalKey<FormFieldState<DateTime>>();
  final _cause = TextEditingController();
  final _action = TextEditingController();
  final _responsible = TextEditingController();
  final _expectedResult = TextEditingController();
  final _indicator = TextEditingController();
  Occurrence? _occurrence;
  FiveWhysInvestigation? _investigation;
  ActionPlan? _plan;
  DateTime? _dueDate;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cause.dispose();
    _action.dispose();
    _responsible.dispose();
    _expectedResult.dispose();
    _indicator.dispose();
    super.dispose();
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
      if (occurrence == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final investigation =
          await fiveWhysRepository.findByOccurrence(occurrence.id);
      final plan = await actionPlanRepository.findByOccurrence(occurrence.id);
      if (!mounted) return;
      setState(() {
        _occurrence = occurrence;
        _investigation = investigation;
        _plan = plan;
        _loading = false;
        if (plan == null && investigation?.isCompleted == true) {
          _cause.text = investigation!.answers[4] ?? '';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível carregar o plano de ação.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.actions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Registrar causa provável e plano de ação',
            subtitle: 'Transforme o aprendizado em uma mudança concreta.',
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
              onPressed: _load,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    if (_occurrence == null) return _buildMissingOccurrence();
    if (_investigation?.isCompleted != true) return _buildIncomplete();
    if (_plan != null) return _buildSummary(_plan!);
    return _buildForm();
  }

  Widget _buildMissingOccurrence() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escolha uma ocorrência analisada para registrar a causa e a ação.',
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => Navigator.of(context)
                .pushReplacementNamed(AppRoutes.occurrences),
            child: const Text('Ver ocorrências'),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomplete() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Antes de criar o plano, conclua os 5 Porquês desta ocorrência.',
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed(
              AppRoutes.investigations,
              arguments: _occurrence!.id,
            ),
            child: const Text('Continuar investigação'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        const _HypothesisNotice(),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final answers = _FiveWhysContext(
              occurrence: _occurrence!,
              investigation: _investigation!,
            );
            final form = _formCard();
            if (constraints.maxWidth < 900) {
              return Column(
                children: [
                  answers,
                  const SizedBox(height: AppSpacing.lg),
                  form,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 340, child: answers),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: form),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _formCard() {
    return SectionCard(
      title: 'Hipótese e ação de melhoria',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label('Causa provável'),
            TextFormField(
              key: const Key('probableCause'),
              controller: _cause,
              enabled: !_saving,
              maxLines: 4,
              maxLength: 4000,
              decoration: const InputDecoration(
                hintText: 'Revise a hipótese sugerida pelo quinto porquê.',
              ),
              validator: _required('Informe a causa provável.', 4000),
            ),
            const SizedBox(height: AppSpacing.md),
            _label('Ação de melhoria'),
            TextFormField(
              key: const Key('actionDescription'),
              controller: _action,
              enabled: !_saving,
              maxLines: 4,
              maxLength: 4000,
              decoration: const InputDecoration(
                hintText: 'Qual mudança concreta será testada?',
              ),
              validator: _required('Informe a ação de melhoria.', 4000),
            ),
            const SizedBox(height: AppSpacing.md),
            _label('Responsável'),
            TextFormField(
              key: const Key('actionResponsible'),
              controller: _responsible,
              enabled: !_saving,
              maxLength: 120,
              decoration: const InputDecoration(
                hintText: 'Quem acompanhará a ação?',
              ),
              validator: _required('Informe o responsável.', 120),
            ),
            const SizedBox(height: AppSpacing.md),
            _label('Prazo'),
            FormField<DateTime>(
              key: _dateFieldKey,
              validator: (_) => _dueDate == null ? 'Informe o prazo.' : null,
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    key: const Key('actionDueDate'),
                    onPressed: _saving ? null : _selectDueDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      _dueDate == null
                          ? 'Selecionar prazo'
                          : _formatDate(_dueDate!),
                    ),
                  ),
                  if (field.hasError)
                    Text(
                      field.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _label('Resultado esperado'),
            TextFormField(
              key: const Key('actionExpectedResult'),
              controller: _expectedResult,
              enabled: !_saving,
              maxLines: 3,
              maxLength: 4000,
              decoration: const InputDecoration(
                hintText: 'O que deve mudar se a ação funcionar?',
              ),
              validator: _required('Informe o resultado esperado.', 4000),
            ),
            const SizedBox(height: AppSpacing.md),
            _label('Indicador'),
            TextFormField(
              key: const Key('actionIndicator'),
              controller: _indicator,
              enabled: !_saving,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Como a equipe perceberá a mudança?',
              ),
              validator: _required('Informe o indicador.', 500),
            ),
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: const Key('actionPlanSubmit'),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: const Text('Salvar plano de ação'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(ActionPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plano de ação registrado',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'A hipótese será avaliada ao testar esta ação na prática.',
                    ),
                  ],
                ),
              ),
              StatusBadge(label: plan.status.label, tone: BadgeTone.warning),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: _occurrence!.title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryField('Causa provável', plan.probableCause),
              const Divider(height: AppSpacing.xl),
              _summaryField('Ação', plan.action),
              const Divider(height: AppSpacing.xl),
              Wrap(
                spacing: AppSpacing.xl,
                runSpacing: AppSpacing.md,
                children: [
                  _SummaryDetail(
                    icon: Icons.person_outline,
                    label: 'Responsável',
                    value: plan.responsible,
                  ),
                  _SummaryDetail(
                    icon: Icons.calendar_today_outlined,
                    label: 'Prazo',
                    value: _formatDate(plan.dueDate),
                  ),
                  _SummaryDetail(
                    icon: Icons.bar_chart_rounded,
                    label: 'Indicador',
                    value: plan.indicator,
                  ),
                ],
              ),
              const Divider(height: AppSpacing.xl),
              _summaryField('Resultado esperado', plan.expectedResult),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDueDate() async {
    final today = saoPauloToday();
    final value = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 5, today.month, today.day),
    );
    if (value != null && mounted) {
      setState(() => _dueDate = value);
      _dateFieldKey.currentState?.didChange(value);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final plan = await widget.actionPlanRepository!.create(
        NewActionPlan(
          occurrenceId: _occurrence!.id,
          investigationId: _investigation!.id,
          probableCause: _cause.text,
          action: _action.text,
          responsible: _responsible.text,
          dueDate: _dueDate!,
          expectedResult: _expectedResult.text,
          indicator: _indicator.text,
        ),
      );
      if (!mounted) return;
      setState(() => _plan = plan);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar o plano de ação.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? Function(String?) _required(String message, int maxLength) =>
      (value) {
        final length = value?.trim().length ?? 0;
        if (length < 2) return message;
        if (length > maxLength) return 'Use no máximo $maxLength caracteres.';
        return null;
      };

  Widget _label(String value) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );

  Widget _summaryField(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      );

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _HypothesisNotice extends StatelessWidget {
  const _HypothesisNotice();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.science_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uma hipótese da equipe',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'A causa provável não é uma certeza do sistema. Ela deve ser validada com evidências ao executar a ação de melhoria.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FiveWhysContext extends StatelessWidget {
  const _FiveWhysContext({
    required this.occurrence,
    required this.investigation,
  });

  final Occurrence occurrence;
  final FiveWhysInvestigation investigation;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Respostas dos 5 Porquês',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            occurrence.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const Divider(height: AppSpacing.xl),
          for (var index = 0; index < 5; index++) ...[
            Text(
              '${index + 1}. ${investigation.answers[index]}',
              style: index == 4
                  ? const TextStyle(fontWeight: FontWeight.w700)
                  : null,
            ),
            if (index < 4) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _SummaryDetail extends StatelessWidget {
  const _SummaryDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
