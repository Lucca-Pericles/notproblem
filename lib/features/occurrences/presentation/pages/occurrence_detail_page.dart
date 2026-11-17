import 'package:flutter/material.dart';
import '../../../../app/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/occurrence.dart';
import '../../domain/occurrence_repository.dart';

class OccurrenceDetailPage extends StatefulWidget {
  const OccurrenceDetailPage(
      {required this.occurrenceId, this.repository, super.key});
  final String occurrenceId;
  final OccurrenceRepository? repository;
  @override
  State<OccurrenceDetailPage> createState() => _OccurrenceDetailPageState();
}

class _OccurrenceDetailPageState extends State<OccurrenceDetailPage> {
  late Future<Occurrence?> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Occurrence?> _load() =>
      widget.occurrenceId.isEmpty || widget.repository == null
          ? Future.value(null)
          : widget.repository!.getById(widget.occurrenceId);
  @override
  Widget build(BuildContext context) => AppShell(
      currentRoute: AppRoutes.occurrences,
      child: FutureBuilder<Occurrence?>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            if (snap.hasError)
              return const Center(
                  child: Text('Não foi possível carregar a ocorrência.'));
            final item = snap.data;
            if (item == null)
              return const Center(child: Text('Ocorrência não encontrada.'));
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageHeader(
                      title: item.title,
                      subtitle: '${item.project} · ${_date(item.occurredOn)}',
                      trailing: StatusBadge(label: item.status.label)),
                  const SizedBox(height: AppSpacing.xl),
                  SectionCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        _field('Contexto', item.context),
                        const SizedBox(height: AppSpacing.lg),
                        _field('Impacto', item.impact),
                        const SizedBox(height: AppSpacing.lg),
                        if (item.status == OccurrenceStatus.completed)
                          const Text(
                              'A análise foi concluída e o contexto não pode mais ser editado.')
                        else
                          FilledButton(
                              key: const Key('editContext'),
                              onPressed: () => _edit(item),
                              child: const Text('Editar contexto'))
                      ]))
                ]);
          }));
  Widget _field(String l, String v) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.xs),
        Text(v)
      ]);
  Future<void> _edit(Occurrence item) async {
    final controller = TextEditingController(text: item.context);
    final form = GlobalKey<FormState>();
    final value = await showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Editar contexto'),
                content: Form(
                    key: form,
                    child: TextFormField(
                        key: const Key('contextEditor'),
                        controller: controller,
                        maxLines: 5,
                        validator: (v) {
                          final n = v?.trim().length ?? 0;
                          return n < 2 || n > 4000
                              ? 'Use entre 2 e 4000 caracteres.'
                              : null;
                        })),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () {
                        if (form.currentState!.validate())
                          Navigator.pop(c, controller.text);
                      },
                      child: const Text('Salvar'))
                ]));
    controller.dispose();
    if (value == null) return;
    try {
      await widget.repository!.updateContext(item.id, value);
      if (mounted) setState(() => _future = _load());
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível atualizar o contexto.')));
    }
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
