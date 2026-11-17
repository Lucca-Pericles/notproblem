import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../domain/occurrence.dart';
import '../../domain/occurrence_repository.dart';

class NewOccurrencePage extends StatefulWidget {
  const NewOccurrencePage({this.repository, super.key});
  final OccurrenceRepository? repository;

  @override
  State<NewOccurrencePage> createState() => _NewOccurrencePageState();
}

class _NewOccurrencePageState extends State<NewOccurrencePage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _project = TextEditingController();
  final _context = TextEditingController();
  final _impact = TextEditingController();
  DateTime? _date;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _project.dispose();
    _context.dispose();
    _impact.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppShell(
        currentRoute: AppRoutes.occurrences,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const PageHeader(
              title: 'Registrar novo atraso',
              subtitle: 'Registre o contexto para iniciar uma investigação.'),
          const SizedBox(height: AppSpacing.xl),
          SectionCard(
              child: Form(
                  key: _formKey,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null) ...[
                          Text(_error!,
                              key: const Key('occurrenceSaveError'),
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                          const SizedBox(height: AppSpacing.md)
                        ],
                        _label('Título da tarefa'),
                        TextFormField(
                            key: const Key('occurrenceTitle'),
                            controller: _title,
                            enabled: !_saving,
                            decoration: const InputDecoration(
                                hintText: 'Ex.: Implementar autenticação'),
                            validator:
                                _required('Informe o título da tarefa.')),
                        const SizedBox(height: AppSpacing.md),
                        _label('Sprint ou projeto'),
                        TextFormField(
                            key: const Key('occurrenceProject'),
                            controller: _project,
                            enabled: !_saving,
                            decoration: const InputDecoration(
                                hintText: 'Ex.: Sprint 04'),
                            validator:
                                _required('Informe a Sprint ou projeto.')),
                        const SizedBox(height: AppSpacing.md),
                        _label('Quando aconteceu?'),
                        FormField<DateTime>(
                            validator: (_) => _date == null
                                ? 'Informe a data da ocorrência.'
                                : null,
                            builder: (field) => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      OutlinedButton.icon(
                                          key: const Key('occurrenceDate'),
                                          onPressed:
                                              _saving ? null : _selectDate,
                                          icon: const Icon(
                                              Icons.calendar_today_outlined),
                                          label: Text(_date == null
                                              ? 'Selecionar data'
                                              : _formatDate(_date!))),
                                      if (field.hasError)
                                        Text(field.errorText!,
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .error)),
                                    ])),
                        const SizedBox(height: AppSpacing.md),
                        _label('Contexto'),
                        TextFormField(
                            key: const Key('occurrenceContext'),
                            controller: _context,
                            enabled: !_saving,
                            maxLines: 4,
                            decoration: const InputDecoration(
                                hintText:
                                    'Descreva o que estava previsto e o que ocorreu.'),
                            validator: _required('Informe o contexto.')),
                        const SizedBox(height: AppSpacing.md),
                        _label('Impacto'),
                        TextFormField(
                            key: const Key('occurrenceImpact'),
                            controller: _impact,
                            enabled: !_saving,
                            maxLines: 4,
                            decoration: const InputDecoration(
                                hintText: 'Descreva o impacto do atraso.'),
                            validator: _required('Informe o impacto.')),
                        const SizedBox(height: AppSpacing.lg),
                        Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                                key: const Key('occurrenceSubmit'),
                                onPressed: _saving ? null : _save,
                                child: _saving
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Text('Salvar ocorrência'))),
                      ]))),
        ]),
      );

  Widget _label(String value) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)));
  String? Function(String?) _required(String message) =>
      (value) => (value?.trim().length ?? 0) < 2 ? message : null;

  Future<void> _selectDate() async {
    final value = await showDatePicker(
        context: context,
        initialDate: _date ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now());
    if (value != null && mounted) setState(() => _date = value);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final repository = widget.repository;
    if (repository == null) {
      setState(() => _error = 'Não foi possível conectar ao banco de dados.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final occurrence = await repository.create(NewOccurrence(
          title: _title.text,
          project: _project.text,
          occurredOn: _date!,
          context: _context.text,
          impact: _impact.text));
      if (!mounted) return;
      await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
                  title: const Text('Ocorrência registrada'),
                  content: const Text(
                      'A ocorrência foi salva com o status Registrada.'),
                  actions: [
                    FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Ver detalhe'))
                  ]));
      if (mounted)
        Navigator.of(context).pushReplacementNamed(AppRoutes.occurrenceDetail,
            arguments: occurrence.id);
    } catch (_) {
      if (mounted)
        setState(() =>
            _error = 'Não foi possível salvar a ocorrência. Tente novamente.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
