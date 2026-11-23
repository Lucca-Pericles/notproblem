import 'dart:async';

import 'package:agile_knowledge/app/agile_knowledge_app.dart';
import 'package:agile_knowledge/app/app_routes.dart';
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
    project: 'Sprint 19',
    occurredOn: DateTime(2026, 11, 19),
    context: 'O relatório não ficou pronto no prazo.',
    impact: 'A demonstração foi adiada.',
    status: OccurrenceStatus.registered,
  );

  test('cada pergunta usa a resposta anterior como contexto', () {
    final investigation = FiveWhysInvestigation.empty(
      id: 'investigation-1',
      occurrenceId: occurrence.id,
    ).withAnswer(1, 'A revisão começou tarde.');

    expect(investigation.currentStep, 2);
    expect(
      investigation.questionFor(2, occurrence.title),
      contains('A revisão começou tarde.'),
    );
  });

  testWidgets('explica o método e exige resposta antes de avançar',
      (tester) async {
    final investigations = FakeFiveWhysRepository();
    await _openInvestigation(tester, occurrence, investigations);

    expect(find.text('Para que servem os 5 Porquês?'), findsOneWidget);
    expect(find.textContaining('não comprova'), findsOneWidget);
    expect(find.text('Pergunta 1 de 5'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('fiveWhysSaveAndContinue')),
    );
    await tester.tap(find.byKey(const Key('fiveWhysSaveAndContinue')));
    await tester.pump();

    expect(
        find.text('Informe uma resposta antes de continuar.'), findsOneWidget);
    expect(investigations.saveCalls, 0);
  });

  testWidgets('salva uma resposta e retoma na pergunta seguinte',
      (tester) async {
    final investigations = FakeFiveWhysRepository();
    await _openInvestigation(tester, occurrence, investigations);

    await tester.enterText(
      find.byKey(const Key('fiveWhysAnswer')),
      'A revisão começou tarde.',
    );
    await tester.ensureVisible(
      find.byKey(const Key('fiveWhysSaveAndContinue')),
    );
    await tester.tap(find.byKey(const Key('fiveWhysSaveAndContinue')));
    await tester.pumpAndSettle();

    expect(investigations.saveCalls, 1);
    expect(find.text('Pergunta 2 de 5'), findsOneWidget);
    expect(find.textContaining('A revisão começou tarde.'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await _openInvestigation(tester, occurrence, investigations);

    expect(find.text('Pergunta 2 de 5'), findsOneWidget);
  });

  testWidgets('revisa, edita e finaliza as cinco respostas', (tester) async {
    final investigations = FakeFiveWhysRepository(
      initialAnswers: const [
        'A revisão começou tarde.',
        'O revisor não foi definido.',
        'A equipe não combinou responsáveis.',
        'O planejamento não incluiu essa decisão.',
        'Não havia uma lista de verificação.',
      ],
    );
    await _openInvestigation(tester, occurrence, investigations);

    expect(find.text('Revise as respostas'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('fiveWhysReviewAnswer1')),
      'A revisão foi iniciada somente no fim.',
    );
    await tester.ensureVisible(find.byKey(const Key('fiveWhysComplete')));
    await tester.tap(find.byKey(const Key('fiveWhysComplete')));
    await tester.pumpAndSettle();

    expect(investigations.completeCalls, 1);
    expect(
      investigations.current.answers.first,
      'A revisão foi iniciada somente no fim.',
    );
    expect(find.text('5 Porquês concluídos'), findsOneWidget);
  });

  testWidgets('contexto fica bloqueado após concluir os 5 Porquês',
      (tester) async {
    final investigations = FakeFiveWhysRepository(
      initialAnswers: const [
        'Resposta 1',
        'Resposta 2',
        'Resposta 3',
        'Resposta 4',
        'Resposta 5',
      ],
    );
    investigations.current = investigations.current.asCompleted();

    await tester.pumpWidget(
      AgileKnowledgeApp(
        authRepository: FakeConfirmedAuthRepository(),
        occurrenceRepository: FakeOccurrenceRepository(occurrence),
        fiveWhysRepository: investigations,
      ),
    );
    final context = tester.element(find.byType(Scaffold).first);
    Navigator.of(context).pushNamed(
      AppRoutes.occurrenceDetail,
      arguments: occurrence.id,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('editContext')), findsNothing);
    expect(find.byKey(const Key('openFiveWhys')), findsOneWidget);
    expect(find.text('Ver análise dos 5 Porquês'), findsOneWidget);
    expect(
      find.text(
        'A análise foi concluída e o contexto não pode mais ser editado.',
      ),
      findsOneWidget,
    );
  });
}

Future<void> _openInvestigation(
  WidgetTester tester,
  Occurrence occurrence,
  FakeFiveWhysRepository investigations,
) async {
  await tester.pumpWidget(
    AgileKnowledgeApp(
      authRepository: FakeConfirmedAuthRepository(),
      occurrenceRepository: FakeOccurrenceRepository(occurrence),
      fiveWhysRepository: investigations,
    ),
  );
  final context = tester.element(find.byType(Scaffold).first);
  Navigator.of(context).pushNamed(
    AppRoutes.investigations,
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
  FakeFiveWhysRepository({List<String>? initialAnswers})
      : current = FiveWhysInvestigation(
          id: 'investigation-1',
          occurrenceId: 'occurrence-1',
          answers: initialAnswers == null
              ? List<String?>.filled(5, null)
              : List<String?>.from(initialAnswers),
          status: FiveWhysStatus.draft,
        );

  FiveWhysInvestigation current;
  int saveCalls = 0;
  int completeCalls = 0;

  @override
  Future<FiveWhysInvestigation?> findByOccurrence(String occurrenceId) async =>
      current.occurrenceId == occurrenceId ? current : null;

  @override
  Future<FiveWhysInvestigation> getOrCreate(String occurrenceId) async =>
      current;

  @override
  Future<FiveWhysInvestigation> saveAnswer({
    required String investigationId,
    required int step,
    required String answer,
  }) async {
    saveCalls++;
    current = current.withAnswer(step, answer);
    return current;
  }

  @override
  Future<FiveWhysInvestigation> saveAnswers({
    required String investigationId,
    required List<String> answers,
  }) async {
    current = current.withAnswers(answers);
    return current;
  }

  @override
  Future<FiveWhysInvestigation> complete({
    required String investigationId,
    required List<String> answers,
  }) async {
    completeCalls++;
    current = current.withAnswers(answers).asCompleted();
    return current;
  }
}
