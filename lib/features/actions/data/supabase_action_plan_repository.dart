import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/time/app_date.dart';
import '../domain/action_plan.dart';
import '../domain/action_plan_repository.dart';

class SupabaseActionPlanRepository implements ActionPlanRepository {
  SupabaseActionPlanRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<ActionPlan?> findByOccurrence(String occurrenceId) async {
    final row = await _client
        .from('action_plans')
        .select()
        .eq('occurrence_id', occurrenceId)
        .maybeSingle();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<ActionPlan> create(NewActionPlan plan) async {
    final values = _values(plan, includeReferences: true);

    try {
      final row =
          await _client.from('action_plans').insert(values).select().single();
      return _fromRow(row);
    } on PostgrestException catch (error) {
      if (error.code != '23505') rethrow;
      final existing = await findByOccurrence(plan.occurrenceId);
      if (existing == null) rethrow;
      return existing;
    }
  }

  @override
  Future<ActionPlan> updateDraft({
    required String planId,
    required NewActionPlan plan,
  }) async {
    final row = await _client
        .from('action_plans')
        .update(_values(plan))
        .eq('id', planId)
        .eq('status', ActionPlanStatus.draft.value)
        .select()
        .maybeSingle();
    if (row == null) {
      throw StateError('O plano de ação não pode ser atualizado.');
    }
    return _fromRow(row);
  }

  @override
  Future<ActionPlan> conclude(String occurrenceId) async {
    final row = await _client.rpc(
      'conclude_investigation',
      params: {'p_occurrence_id': occurrenceId},
    ).single();
    return _fromRow(row);
  }

  Map<String, dynamic> _values(
    NewActionPlan plan, {
    bool includeReferences = false,
  }) =>
      {
        if (includeReferences) ...{
          'occurrence_id': plan.occurrenceId,
          'investigation_id': plan.investigationId,
        },
        'probable_cause': _text(plan.probableCause, 4000),
        'action': _text(plan.action, 4000),
        'responsible': _text(plan.responsible, 120),
        'due_date': _dateOnly(_validDueDate(plan.dueDate)),
        'expected_result': _text(plan.expectedResult, 4000),
        'indicator': _text(plan.indicator, 500),
      };

  String _text(String value, int maxLength) {
    final normalized = value.trim();
    if (normalized.length < 2 || normalized.length > maxLength) {
      throw ArgumentError.value(value, 'value', 'Conteúdo inválido.');
    }
    return normalized;
  }

  DateTime _validDueDate(DateTime value) {
    final dueDate = DateTime(value.year, value.month, value.day);
    final today = saoPauloToday();
    if (dueDate.isBefore(today)) {
      throw ArgumentError.value(value, 'dueDate', 'Prazo inválido.');
    }
    return dueDate;
  }

  String _dateOnly(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  ActionPlan _fromRow(Map<String, dynamic> row) => ActionPlan(
        id: row['id'] as String,
        occurrenceId: row['occurrence_id'] as String,
        investigationId: row['investigation_id'] as String,
        probableCause: row['probable_cause'] as String,
        action: row['action'] as String,
        responsible: row['responsible'] as String,
        dueDate: DateTime.parse(row['due_date'] as String),
        expectedResult: row['expected_result'] as String,
        indicator: row['indicator'] as String,
        status: ActionPlanStatus.fromValue(row['status'] as String),
      );
}
