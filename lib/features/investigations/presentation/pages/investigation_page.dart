import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../occurrences/domain/occurrence.dart';
import '../../../occurrences/domain/occurrence_repository.dart';
import '../../domain/five_whys_investigation.dart';
import '../../domain/five_whys_repository.dart';

class InvestigationPage extends StatefulWidget {
  const InvestigationPage({
    this.occurrenceId = '',
    this.occurrenceRepository,
    this.fiveWhysRepository,
    super.key,
  });

  final String occurrenceId;
  final OccurrenceRepository? occurrenceRepository;
  final FiveWhysRepository? fiveWhysRepository;

  @override
  State<InvestigationPage> createState() => _InvestigationPageState();
}

class _InvestigationPageState extends State<InvestigationPage> {
  final _answerFormKey = GlobalKey<FormState>();
  final _reviewFormKey = GlobalKey<FormState>();
  final _answerController = TextEditingController();
  List<TextEditingController> _reviewControllers = [];
  Occurrence? _occurrence;
  FiveWhysInvestigation? _investigation;
  int _stepIndex = 0;
  bool _loading = true;
  bool _saving = false;
  bool _reviewing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _disposeReviewControllers();
    super.dispose();
  }

  Future<void> _load() async {
    final occurrences = widget.occurrenceRepository;
    final investigations = widget.fiveWhysRepository;
    if (widget.occurrenceId.isEmpty ||
        occurrences == null ||
        investigations == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final occurrence = await occurrences.getById(widget.occurrenceId);
      if (occurrence == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final investigation = await investigations.getOrCreate(occurrence.id);
      if (!mounted) return;
      _occurrence = occurrence;
      _applyInvestigation(investigation);
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível carregar a investigação.';
      });
    }
  }

  void _applyInvestigation(FiveWhysInvestigation investigation) {
    _investigation = investigation;
    _reviewing = investigation.isReadyForReview && !investigation.isCompleted;
    _stepIndex =
        investigation.currentStep > 5 ? 4 : investigation.currentStep - 1;
    _answerController.text = investigation.answers[_stepIndex] ?? '';
    if (_reviewing) _prepareReviewControllers(investigation.answers);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.investigations,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Investigação com 5 Porquês',
            subtitle:
                'Investigue uma possível causa, uma pergunta de cada vez.',
          ),
          const SizedBox(height: AppSpacing.lg),
          const _MethodExplanation(),
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
    if (_occurrence == null || _investigation == null) {
      return SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escolha uma ocorrência para iniciar ou retomar a análise.',
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
    if (_reviewing) return _buildReview();
    if (_investigation!.isCompleted) return _buildCompleted();
    return _buildQuestion();
  }

  Widget _buildQuestion() {
    final investigation = _investigation!;
    final step = _stepIndex + 1;
    return Column(
      children: [
        _ProgressCard(step: step),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final contextCard = _OccurrenceContext(occurrence: _occurrence!);
            final questionCard = _QuestionCard(
              step: step,
              question: investigation.questionFor(step, _occurrence!.title),
              previousAnswers: investigation.answers.take(_stepIndex).toList(),
              controller: _answerController,
              formKey: _answerFormKey,
              saving: _saving,
              onBack: _stepIndex == 0 ? null : _goBack,
              onSave: _saveAndContinue,
            );
            if (constraints.maxWidth < 850) {
              return Column(
                children: [
                  contextCard,
                  const SizedBox(height: AppSpacing.lg),
                  questionCard,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 280, child: contextCard),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: questionCard),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Revise as respostas',
          subtitle: 'Confira e edite o raciocínio completo antes de finalizar.',
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          child: Form(
            key: _reviewFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                    _reviewQuestion(index),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    key: Key('fiveWhysReviewAnswer${index + 1}'),
                    controller: _reviewControllers[index],
                    enabled: !_saving,
                    maxLines: 3,
                    maxLength: 4000,
                    validator: _validateAnswer,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (index < 4) const Divider(height: AppSpacing.xl),
                ],
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _returnToLastQuestion,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Voltar'),
                    ),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        OutlinedButton(
                          key: const Key('fiveWhysSaveReview'),
                          onPressed: _saving ? null : _saveReview,
                          child: const Text('Salvar alterações'),
                        ),
                        FilledButton.icon(
                          key: const Key('fiveWhysComplete'),
                          onPressed: _saving ? null : _complete,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Finalizar análise'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleted() {
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
                      '5 Porquês concluídos',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'As cinco respostas foram registradas. A causa encontrada é uma hipótese e ainda deve ser validada com evidências.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      key: const Key('actionPlanFromFiveWhys'),
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.actions,
                        arguments: _occurrence!.id,
                      ),
                      icon: const Icon(Icons.task_alt_rounded),
                      label: const Text('Registrar causa e plano de ação'),
                    ),
                    if (_occurrence!.status != OccurrenceStatus.actionPlanned &&
                        _occurrence!.status != OccurrenceStatus.completed) ...[
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        key: const Key('editFiveWhysAnswers'),
                        onPressed: _editCompletedAnswers,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar respostas'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: _occurrence!.title,
          child: Column(
            children: [
              for (var index = 0; index < 5; index++) ...[
                _CompletedAnswer(
                  number: index + 1,
                  question: _investigation!.questionFor(
                    index + 1,
                    _occurrence!.title,
                  ),
                  answer: _investigation!.answers[index]!,
                ),
                if (index < 4) const Divider(height: AppSpacing.xl),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveAndContinue() async {
    if (!_answerFormKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = await widget.fiveWhysRepository!.saveAnswer(
        investigationId: _investigation!.id,
        step: _stepIndex + 1,
        answer: _answerController.text,
      );
      if (!mounted) return;
      setState(() {
        _investigation = updated;
        if (_stepIndex == 4) {
          _reviewing = true;
          _prepareReviewControllers(updated.answers);
        } else {
          _stepIndex++;
          _answerController.text = updated.answers[_stepIndex] ?? '';
        }
      });
    } catch (_) {
      _showError('Não foi possível salvar a resposta. Tente novamente.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _goBack() {
    setState(() {
      _stepIndex--;
      _answerController.text = _investigation!.answers[_stepIndex] ?? '';
    });
  }

  Future<void> _returnToLastQuestion() async {
    final answers = _validatedReviewAnswers();
    if (answers == null) return;
    setState(() => _saving = true);
    try {
      final updated = await widget.fiveWhysRepository!.saveAnswers(
        investigationId: _investigation!.id,
        answers: answers,
      );
      if (!mounted) return;
      setState(() {
        _investigation = updated;
        _reviewing = false;
        _stepIndex = 4;
        _answerController.text = updated.answers[4] ?? '';
      });
    } catch (_) {
      _showError('Não foi possível salvar a análise. Tente novamente.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveReview() async {
    final answers = _validatedReviewAnswers();
    if (answers == null) return;
    await _runReviewSave(
      () => widget.fiveWhysRepository!.saveAnswers(
        investigationId: _investigation!.id,
        answers: answers,
      ),
      successMessage: 'Alterações salvas.',
    );
  }

  Future<void> _complete() async {
    final answers = _validatedReviewAnswers();
    if (answers == null) return;
    await _runReviewSave(
      () => widget.fiveWhysRepository!.complete(
        investigationId: _investigation!.id,
        answers: answers,
      ),
      closeReview: true,
    );
  }

  List<String>? _validatedReviewAnswers() {
    if (!_reviewFormKey.currentState!.validate()) return null;
    return _reviewControllers
        .map((controller) => controller.text.trim())
        .toList();
  }

  Future<void> _runReviewSave(
    Future<FiveWhysInvestigation> Function() operation, {
    String? successMessage,
    bool closeReview = false,
  }) async {
    setState(() => _saving = true);
    try {
      final updated = await operation();
      if (!mounted) return;
      setState(() {
        _investigation = updated;
        if (closeReview) _reviewing = false;
      });
      if (successMessage != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (_) {
      _showError('Não foi possível salvar a análise. Tente novamente.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _editCompletedAnswers() {
    _prepareReviewControllers(_investigation!.answers);
    setState(() => _reviewing = true);
  }

  String _reviewQuestion(int index) {
    if (index == 0) {
      return 'Por que a tarefa “${_occurrence!.title}” atrasou?';
    }
    final previous = _reviewControllers[index - 1].text.trim();
    return previous.isEmpty
        ? 'Por que isso aconteceu?'
        : 'Por que isso aconteceu: “$previous”?';
  }

  void _prepareReviewControllers(List<String?> answers) {
    _disposeReviewControllers();
    _reviewControllers = [
      for (final answer in answers) TextEditingController(text: answer ?? ''),
    ];
  }

  void _disposeReviewControllers() {
    for (final controller in _reviewControllers) {
      controller.dispose();
    }
    _reviewControllers = [];
  }

  String? _validateAnswer(String? value) {
    final length = value?.trim().length ?? 0;
    if (length < 2) return 'Informe uma resposta antes de continuar.';
    if (length > 4000) return 'Use no máximo 4000 caracteres.';
    return null;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MethodExplanation extends StatelessWidget {
  const _MethodExplanation();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'Para que servem os 5 Porquês?',
      child: Text(
        'O método ajuda a explorar relações de causa e efeito repetindo a pergunta “por quê?”. Ele orienta uma hipótese, mas não comprova a causa sozinho: valide as conclusões com a equipe e com evidências do trabalho.',
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Text(
              'Pergunta $step de 5',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: LinearProgressIndicator(
                value: step / 5,
                minHeight: 10,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '${step * 20}%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OccurrenceContext extends StatelessWidget {
  const _OccurrenceContext({required this.occurrence});

  final Occurrence occurrence;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Contexto',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            occurrence.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(occurrence.project),
          const Divider(height: AppSpacing.xl),
          const StatusBadge(label: 'Em investigação', tone: BadgeTone.info),
          const Divider(height: AppSpacing.xl),
          Text(occurrence.context),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.step,
    required this.question,
    required this.previousAnswers,
    required this.controller,
    required this.formKey,
    required this.saving,
    required this.onBack,
    required this.onSave,
  });

  final int step;
  final String question;
  final List<String?> previousAnswers;
  final TextEditingController controller;
  final GlobalKey<FormState> formKey;
  final bool saving;
  final VoidCallback? onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusBadge(label: '$stepº PORQUÊ'),
            const SizedBox(height: AppSpacing.md),
            Text(question, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              key: const Key('fiveWhysAnswer'),
              controller: controller,
              enabled: !saving,
              maxLines: 5,
              maxLength: 4000,
              decoration: const InputDecoration(
                hintText: 'Descreva o que pode ter causado isso...',
              ),
              validator: (value) {
                final length = value?.trim().length ?? 0;
                if (length < 2) {
                  return 'Informe uma resposta antes de continuar.';
                }
                if (length > 4000) return 'Use no máximo 4000 caracteres.';
                return null;
              },
            ),
            if (previousAnswers.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _PreviousAnswers(answers: previousAnswers),
            ],
            const SizedBox(height: AppSpacing.lg),
            const _NoBlameTip(),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: saving ? null : onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Voltar'),
                ),
                FilledButton.icon(
                  key: const Key('fiveWhysSaveAndContinue'),
                  onPressed: saving ? null : onSave,
                  icon: saving
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    step == 5 ? 'Revisar respostas' : 'Salvar e continuar',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviousAnswers extends StatelessWidget {
  const _PreviousAnswers({required this.answers});

  final List<String?> answers;

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
          const Text(
            'Respostas anteriores',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var index = 0; index < answers.length; index++)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text('${index + 1}. ${answers[index]}'),
            ),
        ],
      ),
    );
  }
}

class _NoBlameTip extends StatelessWidget {
  const _NoBlameTip();

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: Text(
              'Evite procurar culpados. Concentre a resposta no processo e no que a equipe pode aprender.',
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedAnswer extends StatelessWidget {
  const _CompletedAnswer({
    required this.number,
    required this.question,
    required this.answer,
  });

  final int number;
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 14, child: Text('$number')),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(answer),
            ],
          ),
        ),
      ],
    );
  }
}
