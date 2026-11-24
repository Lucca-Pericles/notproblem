import 'action_plan.dart';

abstract interface class ActionPlanRepository {
  Future<ActionPlan?> findByOccurrence(String occurrenceId);
  Future<ActionPlan> create(NewActionPlan plan);
  Future<ActionPlan> updateDraft({
    required String planId,
    required NewActionPlan plan,
  });
  Future<ActionPlan> conclude(String occurrenceId);
}
