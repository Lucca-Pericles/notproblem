enum OccurrenceStatus {
  registered('registered', 'Registrada'),
  investigating('investigating', 'Em investigação'),
  actionPlanned('action_planned', 'Ação planejada'),
  completed('completed', 'Concluída');

  const OccurrenceStatus(this.value, this.label);

  final String value;
  final String label;

  static OccurrenceStatus fromValue(String value) =>
      OccurrenceStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => OccurrenceStatus.registered,
      );
}

class Occurrence {
  const Occurrence({
    required this.id,
    required this.title,
    required this.project,
    required this.occurredOn,
    required this.context,
    required this.impact,
    required this.status,
  });

  final String id;
  final String title;
  final String project;
  final DateTime occurredOn;
  final String context;
  final String impact;
  final OccurrenceStatus status;
}

class NewOccurrence {
  const NewOccurrence({
    required this.title,
    required this.project,
    required this.occurredOn,
    required this.context,
    required this.impact,
  });

  final String title;
  final String project;
  final DateTime occurredOn;
  final String context;
  final String impact;
}
