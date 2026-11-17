import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/occurrence.dart';
import '../domain/occurrence_repository.dart';

class SupabaseOccurrenceRepository implements OccurrenceRepository {
  SupabaseOccurrenceRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Occurrence> create(NewOccurrence occurrence) async {
    final row = await _client
        .from('occurrences')
        .insert({
          'title': occurrence.title.trim(),
          'project': occurrence.project.trim(),
          'occurred_on': _dateOnly(occurrence.occurredOn),
          'context': occurrence.context.trim(),
          'impact': occurrence.impact.trim(),
        })
        .select()
        .single();

    return _fromRow(row);
  }

  Occurrence _fromRow(Map<String, dynamic> row) => Occurrence(
        id: row['id'] as String,
        title: row['title'] as String,
        project: row['project'] as String,
        occurredOn: DateTime.parse(row['occurred_on'] as String),
        context: row['context'] as String,
        impact: row['impact'] as String,
        status: OccurrenceStatus.fromValue(row['status'] as String),
      );

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
