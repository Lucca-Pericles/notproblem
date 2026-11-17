import 'occurrence.dart';

abstract interface class OccurrenceRepository {
  Future<Occurrence> create(NewOccurrence occurrence);
}
