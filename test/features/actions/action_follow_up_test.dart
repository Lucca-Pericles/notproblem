import 'dart:async';

import 'package:agile_knowledge/app/agile_knowledge_app.dart';
import 'package:agile_knowledge/app/app_routes.dart';
import 'package:agile_knowledge/features/actions/domain/action_follow_up.dart';
import 'package:agile_knowledge/features/actions/domain/action_follow_up_repository.dart';
import 'package:agile_knowledge/features/actions/domain/action_plan.dart';
import 'package:agile_knowledge/features/actions/domain/action_plan_repository.dart';
import 'package:agile_knowledge/features/auth/domain/app_user.dart';
import 'package:agile_knowledge/features/auth/domain/auth_repository.dart';
import 'package:agile_knowledge/features/investigations/domain/five_whys_investigation.dart';
import 'package:agile_knowledge/features/investigations/domain/five_whys_repository.dart';
import 'package:agile_knowledge/features/occurrences/domain/occurrence.dart';
import 'package:agile_knowledge/features/occurrences/domain/occurrence_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mapeia os quatro estados e as três classificações', () {
    expect(ActionFollowUpStatus.values.map((value) => value.label), [
      'Não iniciada',
      'Em andamento',
      'Concluída',
      'Cancelada',
    ]);
    expect(ActionOutcome.values.map((value) => value.label), [
      'Funcionou',
      'Funcionou parcialmente',
      'Não funcionou',
    ]);
  });

  testWidgets('inicia acompanhamento sem afirmar causalidade', (tester) async {
    final followUps = FakeActionFollowUpRepository();
    await _openFollowUp(tester, followUps);

    expect(find.text('Acompanhar ação planejada'), findsOneWidget);
    expect(find.text('Não iniciada'), findsWidgets);
    expect(find.text(plan.expectedResult), findsWidgets);
    expect(find.textContaining('não comprova'), findsOneWidget);
    expect(followUps.createCalls, 1);
  });

  testWidgets('altera a ação para em andamento', (tester) async {
    final followUps = FakeActionFollowUpRepository();
    await _openFollowUp(tester, followUps);

    await tester.ensureVisible(find.byKey(const Key('actionFollowUpStatus')));
    await tester.tap(find.byKey(const Key('actionFollowUpStatus')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Em andamento').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('actionFollowUpSave')));
    await tester.tap(find.byKey(const Key('actionFollowUpSave')));
    await tester.pumpAndSettle();

    expect(followUps.updateCalls, 1);
    expect(followUps.current!.status, ActionFollowUpStatus.inProgress);
  });

  testWidgets('exige resultado e classificação para concluir', (tester) async {
    final followUps = FakeActionFollowUpRepository();
    await _openFollowUp(tester, followUps);

    await tester.ensureVisible(find.byKey(const Key('actionFollowUpStatus')));
    await tester.tap(find.byKey(const Key('actionFollowUpStatus')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluída').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('actionFollowUpSave')));
    await tester.tap(find.byKey(const Key('actionFollowUpSave')));
    await tester.pump();

    expect(find.text('Informe o resultado observado.'), findsOneWidget);
    expect(find.text('Classifique o resultado.'), findsOneWidget);
    expect(followUps.updateCalls, 0);

    await tester.enterText(
      find.byKey(const Key('observedResult')),
      'As revisões começaram no mesmo dia em quatro de cinco tarefas.',
    );
    await tester.ensureVisible(find.byKey(const Key('actionOutcome')));
    await tester.tap(find.byKey(const Key('actionOutcome')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Funcionou parcialmente').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('actionFollowUpSave')));
    await tester.tap(find.byKey(const Key('actionFollowUpSave')));
    await tester.pumpAndSettle();

    expect(followUps.current!.status, ActionFollowUpStatus.completed);
    expect(followUps.current!.outcome, ActionOutcome.partiallyWorked);
    expect(find.text('Resultado esperado'), findsWidgets);
    expect(find.text('Resultado observado'), findsOneWidget);
  });

  testWidgets('mantém observações cronológicas sem sobrescrever',
      (tester) async {
    final followUps = FakeActionFollowUpRepository();
    await _openFollowUp(tester, followUps);

    await tester.enterText(
      find.byKey(const Key('actionFollowUpNote')),
      'A lista foi apresentada à equipe.',
    );
    await tester.ensureVisible(find.byKey(const Key('addActionFollowUpNote')));
    await tester.tap(find.byKey(const Key('addActionFollowUpNote')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('actionFollowUpNote')),
      'A primeira revisão começou no prazo.',
    );
    await tester.tap(find.byKey(const Key('addActionFollowUpNote')));
    await tester.pumpAndSettle();

    expect(followUps.addNoteCalls, 2);
    expect(find.text('A lista foi apresentada à equipe.'), findsOneWidget);
    expect(find.text('A primeira revisão começou no prazo.'), findsOneWidget);
  });

  testWidgets('cancelamento remove a classificação anterior', (tester) async {
    final followUps = FakeActionFollowUpRepository();
    await followUps.getOrCreate(
      actionPlanId: plan.id,
      occurrenceId: occurrence.id,
    );
    final current = followUps.current!;
    followUps.current = ActionFollowUp(
      id: current.id,
      actionPlanId: current.actionPlanId,
      occurrenceId: current.occurrenceId,
      status: ActionFollowUpStatus.completed,
      observedResult: 'As revisões começaram no mesmo dia.',
      outcome: ActionOutcome.worked,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
    );
    await _openFollowUp(tester, followUps);

    await tester.ensureVisible(find.byKey(const Key('actionFollowUpStatus')));
    await tester.tap(find.byKey(const Key('actionFollowUpStatus')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelada').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('actionFollowUpSave')));
    await tester.tap(find.byKey(const Key('actionFollowUpSave')));
    await tester.pumpAndSettle();

    expect(followUps.current!.status, ActionFollowUpStatus.cancelled);
    expect(followUps.current!.outcome, isNull);
  });
}

final occurrence = Occurrence(
  id: 'occurrence-1',
  title: 'Publicar relatório',
  project: 'Sprint 22',
  occurredOn: DateTime(2026, 11, 20),
  context: 'O relatório não ficou pronto no prazo.',
  impact: 'A demonstração foi adiada.',
  status: OccurrenceStatus.actionPlanned,
);

final investigation = FiveWhysInvestigation(
  id: 'investigation-1',
  occurrenceId: occurrence.id,
  answers: const [
    'A revisão começou tarde.',
    'O revisor não foi definido.',
    'A equipe não combinou responsáveis.',
    'O planejamento não incluiu essa decisão.',
    'Não havia uma lista de verificação.',
  ],
  status: FiveWhysStatus.completed,
);

final plan = ActionPlan(
  id: 'plan-1',
  occurrenceId: occurrence.id,
  investigationId: investigation.id,
  probableCause: 'Não havia uma lista de verificação.',
  action: 'Definir uma lista de verificação antes da Sprint.',
  responsible: 'Marina',
  dueDate: DateTime(2026, 12, 10),
  expectedResult: 'Revisões iniciadas no mesmo dia.',
  indicator: 'Tempo até a primeira revisão',
  status: ActionPlanStatus.planned,
);

Future<void> _openFollowUp(
  WidgetTester tester,
  FakeActionFollowUpRepository followUps,
) async {
  await tester.pumpWidget(
    AgileKnowledgeApp(
      authRepository: FakeAuthRepository(),
      occurrenceRepository: FakeOccurrenceRepository(),
      fiveWhysRepository: FakeFiveWhysRepository(),
      actionPlanRepository: FakeActionPlanRepository(),
      actionFollowUpRepository: followUps,
    ),
  );
  final context = tester.element(find.byType(Scaffold).first);
  Navigator.of(context).pushNamed(AppRoutes.actions, arguments: occurrence.id);
  await tester.pumpAndSettle();
}

class FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  static const user = AppUser(
    id: 'user-1',
    name: 'Gustavo',
    email: 'gustavo@exemplo.com',
    isEmailConfirmed: true,
  );
  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;
  @override
  AppUser? get currentUser => user;
  @override
  Future<void> signIn(
      {required String email, required String password}) async {}
  @override
  Future<void> signOut() async => _controller.add(null);
  @override
  Future<SignUpResult> signUp({
    required String name,
    required String email,
    required String password,
    String? emailRedirectTo,
  }) async =>
      const SignUpResult(requiresEmailConfirmation: false);
}

class FakeOccurrenceRepository implements OccurrenceRepository {
  @override
  Future<Occurrence> create(NewOccurrence occurrence) =>
      throw UnimplementedError();
  @override
  Future<Occurrence?> getById(String id) async =>
      id == occurrence.id ? occurrence : null;
  @override
  Future<List<Occurrence>> listMine() async => [occurrence];
  @override
  Future<Occurrence> updateContext(String id, String context) =>
      throw UnimplementedError();
}

class FakeFiveWhysRepository implements FiveWhysRepository {
  @override
  Future<FiveWhysInvestigation?> findByOccurrence(String occurrenceId) async =>
      investigation;
  @override
  Future<FiveWhysInvestigation> getOrCreate(String occurrenceId) async =>
      investigation;
  @override
  Future<FiveWhysInvestigation> saveAnswer(
          {required String investigationId,
          required int step,
          required String answer}) =>
      throw UnimplementedError();
  @override
  Future<FiveWhysInvestigation> saveAnswers(
          {required String investigationId, required List<String> answers}) =>
      throw UnimplementedError();
  @override
  Future<FiveWhysInvestigation> complete(
          {required String investigationId, required List<String> answers}) =>
      throw UnimplementedError();
}

class FakeActionPlanRepository implements ActionPlanRepository {
  @override
  Future<ActionPlan?> findByOccurrence(String occurrenceId) async => plan;
  @override
  Future<ActionPlan> create(NewActionPlan plan) => throw UnimplementedError();
  @override
  Future<ActionPlan> updateDraft(
          {required String planId, required NewActionPlan plan}) =>
      throw UnimplementedError();
  @override
  Future<ActionPlan> conclude(String occurrenceId) =>
      throw UnimplementedError();
}

class FakeActionFollowUpRepository implements ActionFollowUpRepository {
  ActionFollowUp? current;
  final notes = <ActionFollowUpNote>[];
  int createCalls = 0;
  int updateCalls = 0;
  int addNoteCalls = 0;

  @override
  Future<ActionFollowUp> getOrCreate({
    required String actionPlanId,
    required String occurrenceId,
  }) async {
    if (current != null) return current!;
    createCalls++;
    final now = DateTime(2026, 11, 24, 12);
    current = ActionFollowUp(
      id: 'follow-up-1',
      actionPlanId: actionPlanId,
      occurrenceId: occurrenceId,
      status: ActionFollowUpStatus.notStarted,
      observedResult: null,
      outcome: null,
      createdAt: now,
      updatedAt: now,
    );
    return current!;
  }

  @override
  Future<ActionFollowUp> update({
    required String followUpId,
    required ActionFollowUpStatus status,
    String? observedResult,
    ActionOutcome? outcome,
  }) async {
    updateCalls++;
    final value = current!;
    current = ActionFollowUp(
      id: value.id,
      actionPlanId: value.actionPlanId,
      occurrenceId: value.occurrenceId,
      status: status,
      observedResult: observedResult,
      outcome: outcome,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt.add(const Duration(minutes: 1)),
    );
    return current!;
  }

  @override
  Future<List<ActionFollowUpNote>> listNotes(String followUpId) async =>
      List<ActionFollowUpNote>.of(notes);

  @override
  Future<ActionFollowUpNote> addNote({
    required String followUpId,
    required String note,
  }) async {
    addNoteCalls++;
    final created = ActionFollowUpNote(
      id: 'note-$addNoteCalls',
      followUpId: followUpId,
      note: note.trim(),
      createdAt: DateTime(2026, 11, 24, 12, addNoteCalls),
    );
    notes.add(created);
    return created;
  }
}
