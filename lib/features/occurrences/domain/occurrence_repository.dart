import 'occurrence.dart';

abstract interface class OccurrenceRepository {
  Future<Occurrence> create(NewOccurrence occurrence);
  Future<List<Occurrence>> listMine();
  Future<Occurrence?> getById(String id);
  Future<Occurrence> updateContext(String id, String context);
}
