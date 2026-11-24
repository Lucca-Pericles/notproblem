import 'dart:async';

import 'package:agile_knowledge/app/agile_knowledge_app.dart';
import 'package:agile_knowledge/app/app_routes.dart';
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
  final occurrence = Occurrence(
    id: 'occurrence-1',
    title: 'Publicar relatório',
    project: 'Sprint 21',
    occurredOn: DateTime(2026, 11, 20),
    context: 'O relatório não ficou pronto no prazo.',
    impact: 'A demonstração foi adiada.',
    status: OccurrenceStatus.investigating,
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
    id: 'action-1',
    occurrenceId: occurrence.id,
    investigationId: investigation.id,
    probableCause: 'Não havia uma lista de verificação.',
    action: 'Definir uma lista de verificação antes da Sprint.',
    responsible: 'Marina',
    dueDate: DateTime(2026, 12, 10),
    expectedResult: 'Revisões iniciadas em até um dia.',
    indicator: 'Tempo até a primeira revisão',
    status: ActionPlanStatus.draft,
  );

  testWidgets('reúne toda a investigação e permite voltar às etapas',
      (tester) async {
    final actions = FakeActionPlanRepository(plan);
    await _openReview(tester, occurrence, investigation, actions);

    expect(find.text('Revisar e concluir a investigação'), findsOneWidget);
    expect(find.text(occurrence.context), findsOneWidget);
    expect(find.text('A revisão começou tarde.'), findsOneWidget);
    expect(find.text(plan.probableCause), findsWidgets);
    expect(find.text(plan.action), findsOneWidget);
    expect(find.byKey(const Key('editReviewContext')), findsOneWidget);
    expect(find.byKey(const Key('editReviewFiveWhys')), findsOneWidget);
    expect(find.byKey(const Key('editReviewActionPlan')), findsOneWidget);
  });

  testWidgets('não permite concluir quando faltam dados obrigatórios',
      (tester) async {
    await _openReview(
      tester,
      occurrence,
      investigation,
      FakeActionPlanRepository(null),
    );

    expect(find.textContaining('complete todas as etapas'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('concludeInvestigation')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('não permite concluir com prazo vencido', (tester) async {
    final expired = ActionPlan(
      id: plan.id,
      occurrenceId: plan.occurrenceId,
      investigationId: plan.investigationId,
      probableCause: plan.probableCause,
      action: plan.action,
      responsible: plan.responsible,
      dueDate: DateTime(2020, 1, 1),
      expectedResult: plan.expectedResult,
      indicator: plan.indicator,
      status: ActionPlanStatus.draft,
    );
    await _openReview(
      tester,
      occurrence,
      investigation,
      FakeActionPlanRepository(expired),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('concludeInvestigation')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('conclui e direciona ao acompanhamento da ação', (tester) async {
    final actions = FakeActionPlanRepository(plan);
    await _openReview(tester, occurrence, investigation, actions);

    await tester.ensureVisible(find.byKey(const Key('concludeInvestigation')));
    await tester.tap(find.byKey(const Key('concludeInvestigation')));
    await tester.pumpAndSettle();

    expect(actions.concludeCalls, 1);
    expect(find.text('Plano de ação registrado'), findsOneWidget);
  });
}

Future<void> _openReview(
  WidgetTester tester,
  Occurrence occurrence,
  FiveWhysInvestigation investigation,
  FakeActionPlanRepository actions,
) async {
  await tester.pumpWidget(
    AgileKnowledgeApp(
      authRepository: FakeConfirmedAuthRepository(),
      occurrenceRepository: FakeOccurrenceRepository(occurrence),
      fiveWhysRepository: FakeFiveWhysRepository(investigation),
      actionPlanRepository: actions,
    ),
  );
  final context = tester.element(find.byType(Scaffold).first);
  Navigator.of(context).pushNamed(
    AppRoutes.investigationReview,
    arguments: occurrence.id,
  );
  await tester.pumpAndSettle();
}

class FakeConfirmedAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  static const _user = AppUser(
    id: 'user-1',
    name: 'Gustavo',
    email: 'gustavo@exemplo.com',
    isEmailConfirmed: true,
  );

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;
  @override
  AppUser? get currentUser => _user;
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
  FakeOccurrenceRepository(this.occurrence);
  Occurrence occurrence;
  @override
  Future<Occurrence> create(NewOccurrence occurrence) =>
      throw UnimplementedError();
  @override
  Future<Occurrence?> getById(String id) async =>
      id == occurrence.id ? occurrence : null;
  @override
  Future<List<Occurrence>> listMine() async => [occurrence];
  @override
  Future<Occurrence> updateContext(String id, String context) async =>
      occurrence;
}

class FakeFiveWhysRepository implements FiveWhysRepository {
  FakeFiveWhysRepository(this.investigation);
  FiveWhysInvestigation investigation;
  @override
  Future<FiveWhysInvestigation?> findByOccurrence(String occurrenceId) async =>
      investigation.occurrenceId == occurrenceId ? investigation : null;
  @override
  Future<FiveWhysInvestigation> getOrCreate(String occurrenceId) async =>
      investigation;
  @override
  Future<FiveWhysInvestigation> saveAnswer({
    required String investigationId,
    required int step,
    required String answer,
  }) =>
      throw UnimplementedError();
  @override
  Future<FiveWhysInvestigation> saveAnswers({
    required String investigationId,
    required List<String> answers,
  }) =>
      throw UnimplementedError();
  @override
  Future<FiveWhysInvestigation> complete({
    required String investigationId,
    required List<String> answers,
  }) =>
      throw UnimplementedError();
}

class FakeActionPlanRepository implements ActionPlanRepository {
  FakeActionPlanRepository(this.current);
  ActionPlan? current;
  int concludeCalls = 0;
  @override
  Future<ActionPlan?> findByOccurrence(String occurrenceId) async => current;
  @override
  Future<ActionPlan> create(NewActionPlan plan) => throw UnimplementedError();
  @override
  Future<ActionPlan> updateDraft({
    required String planId,
    required NewActionPlan plan,
  }) =>
      throw UnimplementedError();
  @override
  Future<ActionPlan> conclude(String occurrenceId) async {
    concludeCalls++;
    final value = current!;
    current = ActionPlan(
      id: value.id,
      occurrenceId: value.occurrenceId,
      investigationId: value.investigationId,
      probableCause: value.probableCause,
      action: value.action,
      responsible: value.responsible,
      dueDate: value.dueDate,
      expectedResult: value.expectedResult,
      indicator: value.indicator,
      status: ActionPlanStatus.planned,
    );
    return current!;
  }
}
