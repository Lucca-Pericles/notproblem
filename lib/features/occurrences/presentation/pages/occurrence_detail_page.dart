import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/occurrence.dart';

class OccurrenceDetailPage extends StatelessWidget {
  const OccurrenceDetailPage({required this.occurrence, super.key});

  final Occurrence occurrence;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.occurrences,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: occurrence.title,
            subtitle:
                '${occurrence.project} · ${_formatDate(occurrence.occurredOn)}',
            trailing: StatusBadge(label: occurrence.status.label),
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailField(label: 'Contexto', value: occurrence.context),
                const SizedBox(height: AppSpacing.lg),
                _DetailField(label: 'Impacto', value: occurrence.impact),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text(value),
        ],
      );
}
