import 'five_whys_investigation.dart';

abstract interface class FiveWhysRepository {
  Future<FiveWhysInvestigation?> findByOccurrence(String occurrenceId);

  Future<FiveWhysInvestigation> getOrCreate(String occurrenceId);

  Future<FiveWhysInvestigation> saveAnswer({
    required String investigationId,
    required int step,
    required String answer,
  });

  Future<FiveWhysInvestigation> saveAnswers({
    required String investigationId,
    required List<String> answers,
  });

  Future<FiveWhysInvestigation> complete({
    required String investigationId,
    required List<String> answers,
  });
}
