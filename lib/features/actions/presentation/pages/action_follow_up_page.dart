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
import '../../domain/action_follow_up.dart';
import '../../domain/action_follow_up_repository.dart';
import '../../domain/action_plan.dart';
import '../../domain/action_plan_repository.dart';

class ActionFollowUpPage extends StatefulWidget {
  const ActionFollowUpPage({
    this.occurrenceId = '',
    this.occurrenceRepository,
    this.fiveWhysRepository,
    this.actionPlanRepository,
    this.actionFollowUpRepository,
    super.key,
  });

  final String occurrenceId;
  final OccurrenceRepository? occurrenceRepository;
  final FiveWhysRepository? fiveWhysRepository;
  final ActionPlanRepository? actionPlanRepository;
  final ActionFollowUpRepository? actionFollowUpRepository;

  @override
  State<ActionFollowUpPage> createState() => _ActionFollowUpPageState();
}

class _ActionFollowUpPageState extends State<ActionFollowUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _followUpFormKey = GlobalKey<FormState>();
  final _noteFormKey = GlobalKey<FormState>();
  final _dateFieldKey = GlobalKey<FormFieldState<DateTime>>();
  final _cause = TextEditingController();
  final _action = TextEditingController();
  final _responsible = TextEditingController();
  final _expectedResult = TextEditingController();
  final _indicator = TextEditingController();
  final _observedResult = TextEditingController();
  final _note = TextEditingController();
  Occurrence? _occurrence;
  FiveWhysInvestigation? _investigation;
  ActionPlan? _plan;
  ActionFollowUp? _followUp;
  List<ActionFollowUpNote> _notes = [];
  ActionFollowUpStatus _selectedFollowUpStatus =
      ActionFollowUpStatus.notStarted;
  ActionOutcome? _selectedOutcome;
  DateTime? _dueDate;
  bool _loading = true;
  bool _saving = false;
  bool _savingFollowUp = false;
  bool _savingNote = false;
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
    _observedResult.dispose();
    _note.dispose();
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
      ActionFollowUp? followUp;
      var notes = <ActionFollowUpNote>[];
      if (plan?.isFinalized == true &&
          widget.actionFollowUpRepository != null) {
        followUp = await widget.actionFollowUpRepository!.getOrCreate(
          actionPlanId: plan!.id,
          occurrenceId: occurrence.id,
        );
        notes = await widget.actionFollowUpRepository!.listNotes(followUp.id);
      }
      if (!mounted) return;
      setState(() {
        _occurrence = occurrence;
        _investigation = investigation;
        _plan = plan;
        _followUp = followUp;
        _notes = notes;
        _loading = false;
        if (plan == null && investigation?.isCompleted == true) {
          _cause.text = investigation!.answers[4] ?? '';
        } else if (plan != null && !plan.isFinalized) {
          _populatePlan(plan);
        }
        if (followUp != null) {
          _selectedFollowUpStatus = followUp.status;
          _selectedOutcome = followUp.outcome;
          _observedResult.text = followUp.observedResult ?? '';
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
          PageHeader(
            title: _plan?.isFinalized == true
                ? 'Acompanhar ação planejada'
                : 'Registrar causa provável e plano de ação',
            subtitle: _plan?.isFinalized == true
                ? 'Registre o andamento e compare o resultado observado com o esperado.'
                : 'Transforme o aprendizado em uma mudança concreta.',
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
    if (_plan?.isFinalized == true) return _buildSummary(_plan!);
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
        if (_plan != null) ...[
          _DraftNotice(
            onReview: _saving ? null : _saveAndReview,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
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
              validator: _validateDueDate,
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
                label: Text(
                  _plan == null ? 'Salvar plano de ação' : 'Salvar alterações',
                ),
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
        if (_followUp != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildFollowUp(plan),
        ],
      ],
    );
  }

  Widget _buildFollowUp(ActionPlan plan) {
    return Column(
      children: [
        const _CausalityNotice(),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: 'Status e resultado da ação',
          child: Form(
            key: _followUpFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<ActionFollowUpStatus>(
                  key: const Key('actionFollowUpStatus'),
                  initialValue: _selectedFollowUpStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    for (final status in ActionFollowUpStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                  ],
                  onChanged: _savingFollowUp
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedFollowUpStatus = value;
                            if (value != ActionFollowUpStatus.completed) {
                              _selectedOutcome = null;
                            }
                          });
                        },
                ),
                const SizedBox(height: AppSpacing.lg),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final expected = _ResultPanel(
                      title: 'Resultado esperado',
                      child: Text(plan.expectedResult),
                    );
                    final observed = _ResultPanel(
                      title: 'Resultado observado',
                      child: TextFormField(
                        key: const Key('observedResult'),
                        controller: _observedResult,
                        enabled: !_savingFollowUp,
                        maxLines: 5,
                        maxLength: 4000,
                        decoration: const InputDecoration(
                          hintText: 'O que foi observado ao executar a ação?',
                        ),
                        validator: _validateObservedResult,
                      ),
                    );
                    if (constraints.maxWidth < 760) {
                      return Column(
                        children: [
                          expected,
                          const SizedBox(height: AppSpacing.md),
                          observed,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: expected),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: observed),
                      ],
                    );
                  },
                ),
                if (_selectedFollowUpStatus ==
                    ActionFollowUpStatus.completed) ...[
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<ActionOutcome>(
                    key: const Key('actionOutcome'),
                    initialValue: _selectedOutcome,
                    decoration: const InputDecoration(
                      labelText: 'Classificação do resultado',
                    ),
                    items: [
                      for (final outcome in ActionOutcome.values)
                        DropdownMenuItem(
                          value: outcome,
                          child: Text(outcome.label),
                        ),
                    ],
                    validator: (value) =>
                        value == null ? 'Classifique o resultado.' : null,
                    onChanged: _savingFollowUp
                        ? null
                        : (value) => setState(() => _selectedOutcome = value),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusBadge(
                      label: _followUp!.status.label,
                      tone: _followUpTone(_followUp!.status),
                    ),
                    FilledButton.icon(
                      key: const Key('actionFollowUpSave'),
                      onPressed: _savingFollowUp ? null : _saveFollowUp,
                      icon: _savingFollowUp
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Salvar acompanhamento'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildNotes(),
      ],
    );
  }

  Widget _buildNotes() {
    return SectionCard(
      title: 'Observações do acompanhamento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Form(
            key: _noteFormKey,
            child: TextFormField(
              key: const Key('actionFollowUpNote'),
              controller: _note,
              enabled: !_savingNote,
              maxLines: 3,
              maxLength: 4000,
              decoration: const InputDecoration(
                hintText: 'Registre um fato, decisão ou aprendizado.',
              ),
              validator: (value) {
                final length = value?.trim().length ?? 0;
                if (length < 2) return 'Informe uma observação.';
                if (length > 4000) return 'Use no máximo 4000 caracteres.';
                return null;
              },
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              key: const Key('addActionFollowUpNote'),
              onPressed: _savingNote ? null : _addNote,
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Adicionar observação'),
            ),
          ),
          if (_notes.isEmpty) ...[
            const Divider(height: AppSpacing.xl),
            const Text('Nenhuma observação registrada.'),
          ] else ...[
            const Divider(height: AppSpacing.xl),
            for (var index = 0; index < _notes.length; index++) ...[
              _NoteTile(note: _notes[index]),
              if (index < _notes.length - 1)
                const Divider(height: AppSpacing.lg),
            ],
          ],
        ],
      ),
    );
  }

  String? _validateObservedResult(String? value) {
    final length = value?.trim().length ?? 0;
    if (_selectedFollowUpStatus == ActionFollowUpStatus.completed &&
        length < 2) {
      return 'Informe o resultado observado.';
    }
    if (length == 1) return 'Use pelo menos 2 caracteres.';
    if (length > 4000) return 'Use no máximo 4000 caracteres.';
    return null;
  }

  Future<void> _saveFollowUp() async {
    if (!_followUpFormKey.currentState!.validate()) return;
    setState(() => _savingFollowUp = true);
    try {
      final updated = await widget.actionFollowUpRepository!.update(
        followUpId: _followUp!.id,
        status: _selectedFollowUpStatus,
        observedResult: _observedResult.text,
        outcome: _selectedOutcome,
      );
      if (!mounted) return;
      setState(() {
        _followUp = updated;
        _selectedFollowUpStatus = updated.status;
        _selectedOutcome = updated.outcome;
        _observedResult.text = updated.observedResult ?? '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acompanhamento atualizado.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível salvar o acompanhamento.')),
      );
    } finally {
      if (mounted) setState(() => _savingFollowUp = false);
    }
  }

  Future<void> _addNote() async {
    if (!_noteFormKey.currentState!.validate()) return;
    setState(() => _savingNote = true);
    try {
      final created = await widget.actionFollowUpRepository!.addNote(
        followUpId: _followUp!.id,
        note: _note.text,
      );
      if (!mounted) return;
      setState(() {
        _notes = [..._notes, created];
        _note.clear();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível adicionar a observação.')),
      );
    } finally {
      if (mounted) setState(() => _savingNote = false);
    }
  }

  BadgeTone _followUpTone(ActionFollowUpStatus status) => switch (status) {
        ActionFollowUpStatus.notStarted => BadgeTone.warning,
        ActionFollowUpStatus.inProgress => BadgeTone.info,
        ActionFollowUpStatus.completed => BadgeTone.success,
        ActionFollowUpStatus.cancelled => BadgeTone.danger,
      };

  Future<void> _selectDueDate() async {
    final today = saoPauloToday();
    final value = await showDatePicker(
      context: context,
      initialDate:
          _dueDate != null && !_dueDate!.isBefore(today) ? _dueDate! : today,
      firstDate: today,
      lastDate: DateTime(today.year + 5, today.month, today.day),
    );
    if (value != null && mounted) {
      setState(() => _dueDate = value);
      _dateFieldKey.currentState?.didChange(value);
    }
  }

  Future<void> _save() async => _persist();

  Future<void> _saveAndReview() async {
    final saved = await _persist(showSuccessMessage: false);
    if (saved == null || !mounted) return;
    await Navigator.of(context).pushNamed(
      AppRoutes.investigationReview,
      arguments: _occurrence!.id,
    );
    if (mounted) await _load();
  }

  Future<ActionPlan?> _persist({bool showSuccessMessage = true}) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return null;
    setState(() => _saving = true);
    try {
      final values = NewActionPlan(
        occurrenceId: _occurrence!.id,
        investigationId: _investigation!.id,
        probableCause: _cause.text,
        action: _action.text,
        responsible: _responsible.text,
        dueDate: _dueDate!,
        expectedResult: _expectedResult.text,
        indicator: _indicator.text,
      );
      final plan = _plan == null
          ? await widget.actionPlanRepository!.create(values)
          : await widget.actionPlanRepository!.updateDraft(
              planId: _plan!.id,
              plan: values,
            );
      if (!mounted) return null;
      setState(() {
        _plan = plan;
        _populatePlan(plan);
      });
      if (showSuccessMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Plano salvo. Revise a investigação para concluí-la.',
            ),
          ),
        );
      }
      return plan;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar o plano de ação.'),
          ),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validateDueDate(DateTime? _) {
    final value = _dueDate;
    if (value == null) return 'Informe o prazo.';
    final date = DateTime(value.year, value.month, value.day);
    if (date.isBefore(saoPauloToday())) {
      return 'Escolha uma data a partir de hoje.';
    }
    return null;
  }

  String? Function(String?) _required(String message, int maxLength) =>
      (value) {
        final length = value?.trim().length ?? 0;
        if (length < 2) return message;
        if (length > maxLength) return 'Use no máximo $maxLength caracteres.';
        return null;
      };

  void _populatePlan(ActionPlan plan) {
    _cause.text = plan.probableCause;
    _action.text = plan.action;
    _responsible.text = plan.responsible;
    _dueDate = plan.dueDate;
    _expectedResult.text = plan.expectedResult;
    _indicator.text = plan.indicator;
  }

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

class _CausalityNotice extends StatelessWidget {
  const _CausalityNotice();

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
                  'Compare resultados sem assumir causalidade',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'A comparação ajuda a avaliar a hipótese, mas não comprova que a ação causou o resultado observado.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note});

  final ActionFollowUpNote note;

  @override
  Widget build(BuildContext context) {
    final date = note.createdAt.toLocal();
    final formatted = '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(note.note),
              const SizedBox(height: AppSpacing.xs),
              Text(formatted, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
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

class _DraftNotice extends StatelessWidget {
  const _DraftNotice({required this.onReview});

  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.rate_review_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plano em revisão',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Você ainda pode corrigir o contexto, as respostas e o plano antes de concluir.',
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          FilledButton.icon(
            key: const Key('investigationReviewFromAction'),
            onPressed: onReview,
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Revisar investigação'),
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
