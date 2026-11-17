import 'package:flutter/material.dart';
import '../../../../app/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/occurrence.dart';
import '../../domain/occurrence_repository.dart';

class OccurrencesPage extends StatefulWidget {
  const OccurrencesPage({this.repository, super.key});
  final OccurrenceRepository? repository;
  @override
  State<OccurrencesPage> createState() => _OccurrencesPageState();
}

class _OccurrencesPageState extends State<OccurrencesPage> {
  late Future<List<Occurrence>> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Occurrence>> _load() =>
      widget.repository?.listMine() ?? Future.error(StateError('Repository unavailable'));
  void _reload() => setState(() => _future = _load());
  @override
  Widget build(BuildContext context) => AppShell(
      currentRoute: AppRoutes.occurrences,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeader(
            title: 'Ocorrências',
            subtitle: 'Registros de tarefas que sofreram atraso.',
            trailing: FilledButton.icon(
                onPressed: () async {
                  await Navigator.pushNamed(context, AppRoutes.newOccurrence);
                  if (mounted) _reload();
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nova ocorrência'))),
        const SizedBox(height: AppSpacing.xl),
        FutureBuilder<List<Occurrence>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError)
                return SectionCard(
                    child: Column(children: [
                  const Text('Não foi possível carregar as ocorrências.'),
                  TextButton(
                      onPressed: _reload, child: const Text('Tentar novamente'))
                ]));
              final items = snapshot.data!;
              if (items.isEmpty)
                return SectionCard(
                    child: Column(children: [
                  const Text('Você ainda não registrou ocorrências.'),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.newOccurrence),
                      child: const Text('Nova ocorrência'))
                ]));
              return SectionCard(
                  child: Column(children: [
                for (final item in items)
                  _Tile(
                      item: item,
                      onTap: () async {
                        await Navigator.pushNamed(
                            context, AppRoutes.occurrenceDetail,
                            arguments: item.id);
                        if (mounted) _reload();
                      })
              ]));
            })
      ]));
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item, required this.onTap});
  final Occurrence item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
      key: Key('occurrence-${item.id}'),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.assignment_outlined)),
      title:
          Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('${item.project} · ${_date(item.occurredOn)}'),
      trailing:
          StatusBadge(label: item.status.label, tone: _tone(item.status)));
  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  BadgeTone _tone(OccurrenceStatus s) => switch (s) {
        OccurrenceStatus.actionPlanned => BadgeTone.warning,
        OccurrenceStatus.completed => BadgeTone.success,
        _ => BadgeTone.info
      };
}
