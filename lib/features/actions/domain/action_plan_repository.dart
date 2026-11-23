import 'action_plan.dart';

abstract interface class ActionPlanRepository {
  Future<ActionPlan?> findByOccurrence(String occurrenceId);
  Future<ActionPlan> create(NewActionPlan plan);
}
