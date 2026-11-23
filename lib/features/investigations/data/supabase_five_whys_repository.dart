import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/five_whys_investigation.dart';
import '../domain/five_whys_repository.dart';

class SupabaseFiveWhysRepository implements FiveWhysRepository {
  SupabaseFiveWhysRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<FiveWhysInvestigation?> findByOccurrence(String occurrenceId) async {
    final row = await _client
        .from('five_why_investigations')
        .select()
        .eq('occurrence_id', occurrenceId)
        .maybeSingle();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<FiveWhysInvestigation> getOrCreate(String occurrenceId) async {
    final existing = await findByOccurrence(occurrenceId);
    if (existing != null) return existing;

    try {
      final created = await _client
          .from('five_why_investigations')
          .insert({'occurrence_id': occurrenceId})
          .select()
          .single();
      return _fromRow(created);
    } on PostgrestException catch (error) {
      if (error.code != '23505') rethrow;
      final concurrent = await findByOccurrence(occurrenceId);
      if (concurrent == null) rethrow;
      return concurrent;
    }
  }

  @override
  Future<FiveWhysInvestigation> saveAnswer({
    required String investigationId,
    required int step,
    required String answer,
  }) async {
    if (step < 1 || step > 5) {
      throw RangeError.range(step, 1, 5, 'step');
    }
    final normalized = _validatedAnswer(answer);
    return _update(
      investigationId,
      {'answer_$step': normalized},
    );
  }

  @override
  Future<FiveWhysInvestigation> saveAnswers({
    required String investigationId,
    required List<String> answers,
  }) =>
      _update(investigationId, _answerValues(answers));

  @override
  Future<FiveWhysInvestigation> complete({
    required String investigationId,
    required List<String> answers,
  }) =>
      _update(
        investigationId,
        {..._answerValues(answers), 'status': FiveWhysStatus.completed.value},
      );

  Future<FiveWhysInvestigation> _update(
    String investigationId,
    Map<String, dynamic> values,
  ) async {
    final row = await _client
        .from('five_why_investigations')
        .update(values)
        .eq('id', investigationId)
        .select()
        .maybeSingle();
    if (row == null) {
      throw StateError('A investigação não pode ser atualizada.');
    }
    return _fromRow(row);
  }

  Map<String, dynamic> _answerValues(List<String> answers) {
    if (answers.length != 5) {
      throw ArgumentError.value(answers, 'answers', 'Informe cinco respostas.');
    }
    return {
      for (var index = 0; index < answers.length; index++)
        'answer_${index + 1}': _validatedAnswer(answers[index]),
    };
  }

  String _validatedAnswer(String value) {
    final normalized = value.trim();
    if (normalized.length < 2 || normalized.length > 4000) {
      throw ArgumentError.value(
        value,
        'answer',
        'Use entre 2 e 4000 caracteres.',
      );
    }
    return normalized;
  }

  FiveWhysInvestigation _fromRow(Map<String, dynamic> row) =>
      FiveWhysInvestigation(
        id: row['id'] as String,
        occurrenceId: row['occurrence_id'] as String,
        answers: [
          for (var step = 1; step <= 5; step++) row['answer_$step'] as String?,
        ],
        status: FiveWhysStatus.fromValue(row['status'] as String),
      );
}
