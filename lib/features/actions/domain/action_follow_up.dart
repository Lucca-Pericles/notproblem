enum ActionFollowUpStatus {
  notStarted('not_started', 'Não iniciada'),
  inProgress('in_progress', 'Em andamento'),
  completed('completed', 'Concluída'),
  cancelled('cancelled', 'Cancelada');

  const ActionFollowUpStatus(this.value, this.label);

  final String value;
  final String label;

  static ActionFollowUpStatus fromValue(String value) =>
      ActionFollowUpStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => ActionFollowUpStatus.notStarted,
      );
}

enum ActionOutcome {
  worked('worked', 'Funcionou'),
  partiallyWorked('partially_worked', 'Funcionou parcialmente'),
  didNotWork('did_not_work', 'Não funcionou');

  const ActionOutcome(this.value, this.label);

  final String value;
  final String label;

  static ActionOutcome? fromValue(String? value) {
    if (value == null) return null;
    return ActionOutcome.values.firstWhere(
      (outcome) => outcome.value == value,
      orElse: () => ActionOutcome.didNotWork,
    );
  }
}

class ActionFollowUp {
  const ActionFollowUp({
    required this.id,
    required this.actionPlanId,
    required this.occurrenceId,
    required this.status,
    required this.observedResult,
    required this.outcome,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String actionPlanId;
  final String occurrenceId;
  final ActionFollowUpStatus status;
  final String? observedResult;
  final ActionOutcome? outcome;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ActionFollowUpNote {
  const ActionFollowUpNote({
    required this.id,
    required this.followUpId,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String followUpId;
  final String note;
  final DateTime createdAt;
}
