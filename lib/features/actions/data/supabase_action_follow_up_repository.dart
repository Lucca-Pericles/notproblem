import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/action_follow_up.dart';
import '../domain/action_follow_up_repository.dart';

class SupabaseActionFollowUpRepository implements ActionFollowUpRepository {
  SupabaseActionFollowUpRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<ActionFollowUp> getOrCreate({
    required String actionPlanId,
    required String occurrenceId,
  }) async {
    final existing = await _findByPlan(actionPlanId);
    if (existing != null) return existing;

    try {
      final row = await _client
          .from('action_follow_ups')
          .insert({
            'action_plan_id': actionPlanId,
            'occurrence_id': occurrenceId,
          })
          .select()
          .single();
      return _followUpFromRow(row);
    } on PostgrestException catch (error) {
      if (error.code != '23505') rethrow;
      final concurrent = await _findByPlan(actionPlanId);
      if (concurrent == null) rethrow;
      return concurrent;
    }
  }

  @override
  Future<ActionFollowUp> update({
    required String followUpId,
    required ActionFollowUpStatus status,
    String? observedResult,
    ActionOutcome? outcome,
  }) async {
    final normalizedResult = _optionalText(observedResult, 4000);
    if (status == ActionFollowUpStatus.completed) {
      if (normalizedResult == null || outcome == null) {
        throw ArgumentError(
          'Uma ação concluída exige resultado observado e classificação.',
        );
      }
    } else {
      outcome = null;
    }

    final row = await _client
        .from('action_follow_ups')
        .update({
          'status': status.value,
          'observed_result': normalizedResult,
          'outcome': outcome?.value,
        })
        .eq('id', followUpId)
        .select()
        .maybeSingle();
    if (row == null) {
      throw StateError('O acompanhamento não pode ser atualizado.');
    }
    return _followUpFromRow(row);
  }

  @override
  Future<List<ActionFollowUpNote>> listNotes(String followUpId) async {
    final rows = await _client
        .from('action_follow_up_notes')
        .select()
        .eq('follow_up_id', followUpId)
        .order('created_at');
    return rows.map(_noteFromRow).toList();
  }

  @override
  Future<ActionFollowUpNote> addNote({
    required String followUpId,
    required String note,
  }) async {
    final normalized = _requiredText(note, 4000);
    final row = await _client
        .from('action_follow_up_notes')
        .insert({'follow_up_id': followUpId, 'note': normalized})
        .select()
        .single();
    return _noteFromRow(row);
  }

  Future<ActionFollowUp?> _findByPlan(String actionPlanId) async {
    final row = await _client
        .from('action_follow_ups')
        .select()
        .eq('action_plan_id', actionPlanId)
        .maybeSingle();
    return row == null ? null : _followUpFromRow(row);
  }

  String _requiredText(String value, int maxLength) {
    final normalized = value.trim();
    if (normalized.length < 2 || normalized.length > maxLength) {
      throw ArgumentError.value(value, 'value', 'Conteúdo inválido.');
    }
    return normalized;
  }

  String? _optionalText(String? value, int maxLength) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return _requiredText(normalized, maxLength);
  }

  ActionFollowUp _followUpFromRow(Map<String, dynamic> row) => ActionFollowUp(
        id: row['id'] as String,
        actionPlanId: row['action_plan_id'] as String,
        occurrenceId: row['occurrence_id'] as String,
        status: ActionFollowUpStatus.fromValue(row['status'] as String),
        observedResult: row['observed_result'] as String?,
        outcome: ActionOutcome.fromValue(row['outcome'] as String?),
        createdAt: DateTime.parse(row['created_at'] as String),
        updatedAt: DateTime.parse(row['updated_at'] as String),
      );

  ActionFollowUpNote _noteFromRow(Map<String, dynamic> row) =>
      ActionFollowUpNote(
        id: row['id'] as String,
        followUpId: row['follow_up_id'] as String,
        note: row['note'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}
