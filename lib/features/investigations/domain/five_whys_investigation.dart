enum FiveWhysStatus {
  draft('draft'),
  completed('completed');

  const FiveWhysStatus(this.value);

  final String value;

  static FiveWhysStatus fromValue(String value) =>
      FiveWhysStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => FiveWhysStatus.draft,
      );
}

class FiveWhysInvestigation {
  FiveWhysInvestigation({
    required this.id,
    required this.occurrenceId,
    required List<String?> answers,
    required this.status,
  }) : answers = List<String?>.unmodifiable(answers) {
    if (answers.length != 5) {
      throw ArgumentError.value(answers, 'answers', 'Informe cinco respostas.');
    }
  }

  factory FiveWhysInvestigation.empty({
    required String id,
    required String occurrenceId,
  }) =>
      FiveWhysInvestigation(
        id: id,
        occurrenceId: occurrenceId,
        answers: List<String?>.filled(5, null),
        status: FiveWhysStatus.draft,
      );

  final String id;
  final String occurrenceId;
  final List<String?> answers;
  final FiveWhysStatus status;

  bool get isCompleted => status == FiveWhysStatus.completed;

  bool get isReadyForReview => answers.every(_isValidAnswer);

  int get answeredCount => answers.where(_isValidAnswer).length;

  int get currentStep {
    final firstEmpty = answers.indexWhere((answer) => !_isValidAnswer(answer));
    return firstEmpty == -1 ? 6 : firstEmpty + 1;
  }

  String questionFor(int step, String occurrenceTitle) {
    _validateStep(step);
    if (step == 1) {
      return 'Por que a tarefa “$occurrenceTitle” atrasou?';
    }

    final previousAnswer = answers[step - 2]?.trim();
    if (previousAnswer == null || previousAnswer.isEmpty) {
      return 'Por que isso aconteceu?';
    }
    return 'Por que isso aconteceu: “$previousAnswer”?';
  }

  FiveWhysInvestigation withAnswer(int step, String answer) {
    _validateStep(step);
    final normalized = _normalizeAnswer(answer);
    final updated = List<String?>.from(answers);
    updated[step - 1] = normalized;
    return FiveWhysInvestigation(
      id: id,
      occurrenceId: occurrenceId,
      answers: updated,
      status: status,
    );
  }

  FiveWhysInvestigation withAnswers(List<String> values) {
    if (values.length != 5) {
      throw ArgumentError.value(values, 'values', 'Informe cinco respostas.');
    }
    return FiveWhysInvestigation(
      id: id,
      occurrenceId: occurrenceId,
      answers: values.map(_normalizeAnswer).toList(),
      status: status,
    );
  }

  FiveWhysInvestigation asCompleted() {
    if (!isReadyForReview) {
      throw StateError('A análise exige cinco respostas antes de finalizar.');
    }
    return FiveWhysInvestigation(
      id: id,
      occurrenceId: occurrenceId,
      answers: answers,
      status: FiveWhysStatus.completed,
    );
  }

  static bool _isValidAnswer(String? value) =>
      value != null && value.trim().length >= 2 && value.trim().length <= 4000;

  static String _normalizeAnswer(String value) {
    final normalized = value.trim();
    if (!_isValidAnswer(normalized)) {
      throw ArgumentError.value(
        value,
        'answer',
        'Use entre 2 e 4000 caracteres.',
      );
    }
    return normalized;
  }

  static void _validateStep(int step) {
    if (step < 1 || step > 5) {
      throw RangeError.range(step, 1, 5, 'step');
    }
  }
}
