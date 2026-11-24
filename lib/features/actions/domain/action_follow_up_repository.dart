import 'action_follow_up.dart';

abstract interface class ActionFollowUpRepository {
  Future<ActionFollowUp> getOrCreate({
    required String actionPlanId,
    required String occurrenceId,
  });

  Future<ActionFollowUp> update({
    required String followUpId,
    required ActionFollowUpStatus status,
    String? observedResult,
    ActionOutcome? outcome,
  });

  Future<List<ActionFollowUpNote>> listNotes(String followUpId);

  Future<ActionFollowUpNote> addNote({
    required String followUpId,
    required String note,
  });
}
