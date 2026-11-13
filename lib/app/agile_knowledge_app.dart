import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/actions/presentation/pages/action_follow_up_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/history/presentation/pages/history_page.dart';
import '../features/investigations/presentation/pages/investigation_page.dart';
import '../features/occurrences/presentation/pages/new_occurrence_page.dart';
import '../features/occurrences/presentation/pages/occurrences_page.dart';
import 'app_routes.dart';

class AgileKnowledgeApp extends StatelessWidget {
  const AgileKnowledgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agile Knowledge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.dashboard,
      routes: {
        AppRoutes.dashboard: (_) => const DashboardPage(),
        AppRoutes.occurrences: (_) => const OccurrencesPage(),
        AppRoutes.newOccurrence: (_) => const NewOccurrencePage(),
        AppRoutes.investigations: (_) => const InvestigationPage(),
        AppRoutes.actions: (_) => const ActionFollowUpPage(),
        AppRoutes.history: (_) => const HistoryPage(),
      },
    );
  }
}
