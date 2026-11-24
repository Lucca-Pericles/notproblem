enum ActionPlanStatus {
  draft('draft', 'Em revisão'),
  planned('planned', 'Planejada');

  const ActionPlanStatus(this.value, this.label);

  final String value;
  final String label;

  static ActionPlanStatus fromValue(String value) =>
      ActionPlanStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => ActionPlanStatus.draft,
      );
}

class ActionPlan {
  const ActionPlan({
    required this.id,
    required this.occurrenceId,
    required this.investigationId,
    required this.probableCause,
    required this.action,
    required this.responsible,
    required this.dueDate,
    required this.expectedResult,
    required this.indicator,
    required this.status,
  });

  final String id;
  final String occurrenceId;
  final String investigationId;
  final String probableCause;
  final String action;
  final String responsible;
  final DateTime dueDate;
  final String expectedResult;
  final String indicator;
  final ActionPlanStatus status;

  bool get isFinalized => status == ActionPlanStatus.planned;
}

class NewActionPlan {
  const NewActionPlan({
    required this.occurrenceId,
    required this.investigationId,
    required this.probableCause,
    required this.action,
    required this.responsible,
    required this.dueDate,
    required this.expectedResult,
    required this.indicator,
  });

  final String occurrenceId;
  final String investigationId;
  final String probableCause;
  final String action;
  final String responsible;
  final DateTime dueDate;
  final String expectedResult;
  final String indicator;
}
