import 'dart:async';

import 'package:agile_knowledge/app/agile_knowledge_app.dart';
import 'package:agile_knowledge/app/app_routes.dart';
import 'package:agile_knowledge/core/time/app_date.dart';
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
    project: 'Sprint 20',
    occurredOn: DateTime(2026, 11, 20),
    context: 'O relatório não ficou pronto no prazo.',
    impact: 'A demonstração foi adiada.',
    status: OccurrenceStatus.investigating,
  );

  test('data de referência usa o dia de São Paulo', () {
    expect(
      saoPauloToday(now: DateTime.utc(2026, 11, 24, 1)),
      DateTime(2026, 11, 23),
    );
  });

  testWidgets('apresenta a causa como hipótese baseada no quinto porquê',
      (tester) async {
    final actions = FakeActionPlanRepository();
    await _openActionPlan(tester, occurrence, actions);

    expect(
        find.text('Registrar causa provável e plano de ação'), findsOneWidget);
    expect(find.textContaining('hipótese da equipe'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Não havia uma lista de verificação.'),
      findsOneWidget,
    );
    expect(find.text('Respostas dos 5 Porquês'), findsOneWidget);
  });

  testWidgets('investigação incompleta não permite criar o plano',
      (tester) async {
    final actions = FakeActionPlanRepository();
    await _openActionPlan(
      tester,
      occurrence,
      actions,
      investigation: FiveWhysInvestigation.empty(
        id: 'investigation-1',
        occurrenceId: occurrence.id,
      ).withAnswer(1, 'A revisão começou tarde.'),
    );

    expect(find.byKey(const Key('actionPlanSubmit')), findsNothing);
    expect(find.textContaining('conclua os 5 Porquês'), findsOneWidget);
  });

  testWidgets('valida campos obrigatórios e prazo antes de salvar',
      (tester) async {
    final actions = FakeActionPlanRepository();
    await _openActionPlan(tester, occurrence, actions);

    await tester.enterText(find.byKey(const Key('probableCause')), '');
    await tester.ensureVisible(find.byKey(const Key('actionPlanSubmit')));
    await tester.tap(find.byKey(const Key('actionPlanSubmit')));
    await tester.pump();

    expect(find.text('Informe a causa provável.'), findsOneWidget);
    expect(find.text('Informe a ação de melhoria.'), findsOneWidget);
    expect(find.text('Informe o responsável.'), findsOneWidget);
    expect(find.text('Informe o prazo.'), findsOneWidget);
    expect(find.text('Informe o resultado esperado.'), findsOneWidget);
    expect(find.text('Informe o indicador.'), findsOneWidget);
    expect(actions.createCalls, 0);
  });

  testWidgets('salva plano vinculado à ocorrência e à investigação',
      (tester) async {
    final actions = FakeActionPlanRepository();
    await _openActionPlan(tester, occurrence, actions);

    await tester.enterText(
      find.byKey(const Key('actionDescription')),
      'Definir uma lista de verificação antes da Sprint.',
    );
    await tester.enterText(
      find.byKey(const Key('actionResponsible')),
      'Marina',
    );
    await tester.enterText(
      find.byKey(const Key('actionExpectedResult')),
      'Revisões iniciadas em até um dia.',
    );
    await tester.enterText(
      find.byKey(const Key('actionIndicator')),
      'Tempo até a primeira revisão',
    );
    await tester.ensureVisible(find.byKey(const Key('actionDueDate')));
    await tester.tap(find.byKey(const Key('actionDueDate')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('actionPlanSubmit')));
    await tester.tap(find.byKey(const Key('actionPlanSubmit')));
    await tester.pumpAndSettle();

    expect(actions.createCalls, 1);
    expect(actions.lastCreated!.occurrenceId, occurrence.id);
    expect(actions.lastCreated!.investigationId, 'investigation-1');
    expect(actions.lastCreated!.responsible, 'Marina');
    expect(find.text('Plano de ação registrado'), findsOneWidget);
  });

  testWidgets('plano existente abre no resumo sem criar duplicação',
      (tester) async {
    final actions = FakeActionPlanRepository()
      ..current = ActionPlan(
        id: 'action-1',
        occurrenceId: occurrence.id,
        investigationId: 'investigation-1',
        probableCause: 'Não havia uma lista de verificação.',
        action: 'Definir uma lista de verificação antes da Sprint.',
        responsible: 'Marina',
        dueDate: DateTime(2026, 12, 10),
        expectedResult: 'Revisões iniciadas em até um dia.',
        indicator: 'Tempo até a primeira revisão',
        status: ActionPlanStatus.planned,
      );

    await _openActionPlan(tester, occurrence, actions);

    expect(find.text('Plano de ação registrado'), findsOneWidget);
    expect(find.byKey(const Key('actionPlanSubmit')), findsNothing);
    expect(actions.createCalls, 0);
  });

  testWidgets('acesso direto orienta a escolher uma ocorrência',
      (tester) async {
    await tester.pumpWidget(
      AgileKnowledgeApp(
        authRepository: FakeConfirmedAuthRepository(),
        occurrenceRepository: FakeOccurrenceRepository(occurrence),
        fiveWhysRepository: FakeFiveWhysRepository(
          FiveWhysInvestigation.empty(
            id: 'investigation-1',
            occurrenceId: occurrence.id,
          ),
        ),
        actionPlanRepository: FakeActionPlanRepository(),
      ),
    );
    final context = tester.element(find.byType(Scaffold).first);
    Navigator.of(context).pushNamed(AppRoutes.actions);
    await tester.pumpAndSettle();

    expect(find.textContaining('Escolha uma ocorrência'), findsOneWidget);
  });

  testWidgets('CTA dos 5 Porquês abre o plano da mesma ocorrência',
      (tester) async {
    final investigation = FiveWhysInvestigation(
      id: 'investigation-1',
      occurrenceId: occurrence.id,
      answers: const [
        'Resposta 1',
        'Resposta 2',
        'Resposta 3',
        'Resposta 4',
        'Hipótese da quinta resposta',
      ],
      status: FiveWhysStatus.completed,
    );
    await tester.pumpWidget(
      AgileKnowledgeApp(
        authRepository: FakeConfirmedAuthRepository(),
        occurrenceRepository: FakeOccurrenceRepository(occurrence),
        fiveWhysRepository: FakeFiveWhysRepository(investigation),
        actionPlanRepository: FakeActionPlanRepository(),
      ),
    );
    final context = tester.element(find.byType(Scaffold).first);
    Navigator.of(context).pushNamed(
      AppRoutes.investigations,
      arguments: occurrence.id,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('actionPlanFromFiveWhys')),
    );
    await tester.tap(find.byKey(const Key('actionPlanFromFiveWhys')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('probableCause')), findsOneWidget);
    expect(find.text('Hipótese da quinta resposta'), findsOneWidget);
  });
}

Future<void> _openActionPlan(
  WidgetTester tester,
  Occurrence occurrence,
  FakeActionPlanRepository actions, {
  FiveWhysInvestigation? investigation,
}) async {
  final completed = FiveWhysInvestigation(
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
  await tester.pumpWidget(
    AgileKnowledgeApp(
      authRepository: FakeConfirmedAuthRepository(),
      occurrenceRepository: FakeOccurrenceRepository(occurrence),
      fiveWhysRepository: FakeFiveWhysRepository(investigation ?? completed),
      actionPlanRepository: actions,
    ),
  );
  final context = tester.element(find.byType(Scaffold).first);
  Navigator.of(context).pushNamed(AppRoutes.actions, arguments: occurrence.id);
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
  final Occurrence occurrence;

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
  ActionPlan? current;
  NewActionPlan? lastCreated;
  int createCalls = 0;

  @override
  Future<ActionPlan?> findByOccurrence(String occurrenceId) async => current;

  @override
  Future<ActionPlan> create(NewActionPlan plan) async {
    createCalls++;
    lastCreated = plan;
    current = ActionPlan(
      id: 'action-1',
      occurrenceId: plan.occurrenceId,
      investigationId: plan.investigationId,
      probableCause: plan.probableCause.trim(),
      action: plan.action.trim(),
      responsible: plan.responsible.trim(),
      dueDate: plan.dueDate,
      expectedResult: plan.expectedResult.trim(),
      indicator: plan.indicator.trim(),
      status: ActionPlanStatus.planned,
    );
    return current!;
  }
}
