import 'dart:async';

import 'package:agile_knowledge/app/agile_knowledge_app.dart';
import 'package:agile_knowledge/app/app_routes.dart';
import 'package:agile_knowledge/features/auth/domain/app_user.dart';
import 'package:agile_knowledge/features/auth/domain/auth_repository.dart';
import 'package:agile_knowledge/features/auth/presentation/pages/sign_in_page.dart';
import 'package:agile_knowledge/features/auth/presentation/pages/email_confirmed_page.dart';
import 'package:agile_knowledge/features/occurrences/domain/occurrence.dart';
import 'package:agile_knowledge/features/occurrences/domain/occurrence_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('usuário sem sessão visualiza a página de entrada',
      (tester) async {
    await tester.pumpWidget(
      AgileKnowledgeApp(authRepository: FakeAuthRepository()),
    );

    expect(find.text('Entrar'), findsWidgets);
    expect(find.byKey(const Key('signInEmail')), findsOneWidget);
    expect(find.text('Olá, Gustavo'), findsNothing);
  });

  testWidgets('rota privada mantém usuário sem sessão na página de entrada',
      (tester) async {
    await tester.pumpWidget(
      AgileKnowledgeApp(authRepository: FakeAuthRepository()),
    );

    final context = tester.element(find.byType(SignInPage));
    Navigator.of(context).pushNamed(AppRoutes.occurrences);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('signInEmail')), findsOneWidget);
    expect(find.text('Ocorrências'), findsNothing);
  });

  testWidgets('conta sem e-mail confirmado não acessa rota privada',
      (tester) async {
    await tester.pumpWidget(
      AgileKnowledgeApp(
        authRepository: FakeAuthRepository(
          initialUser: const AppUser(
            id: 'user-pending',
            name: 'Ana',
            email: 'ana@exemplo.com',
            isEmailConfirmed: false,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('signInEmail')), findsOneWidget);
    expect(find.text('Olá, Ana'), findsNothing);
  });

  testWidgets('login válido abre a página inicial com o nome do usuário',
      (tester) async {
    final repository = FakeAuthRepository();
    await tester.pumpWidget(AgileKnowledgeApp(authRepository: repository));

    await tester.enterText(
      find.byKey(const Key('signInEmail')),
      'gustavo@exemplo.com',
    );
    await tester.enterText(
      find.byKey(const Key('signInPassword')),
      'Senha123',
    );
    await tester.tap(find.byKey(const Key('signInSubmit')));
    await tester.pumpAndSettle();

    expect(find.text('Olá, Gustavo'), findsOneWidget);
    expect(find.text('Registrar atraso'), findsOneWidget);
  });

  testWidgets('logout remove a sessão e volta para a página de entrada',
      (tester) async {
    final repository = FakeAuthRepository(
      initialUser: const AppUser(
        id: 'user-1',
        name: 'Gustavo',
        email: 'gustavo@exemplo.com',
        isEmailConfirmed: true,
      ),
    );

    await tester.pumpWidget(AgileKnowledgeApp(authRepository: repository));
    expect(find.text('Olá, Gustavo'), findsOneWidget);

    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('signInEmail')), findsOneWidget);
    expect(find.text('Olá, Gustavo'), findsNothing);
  });

  testWidgets('cadastro exige nome, e-mail e senha válidos', (tester) async {
    await tester.pumpWidget(
      AgileKnowledgeApp(authRepository: FakeAuthRepository()),
    );

    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('signUpSubmit')));
    await tester.tap(find.byKey(const Key('signUpSubmit')));
    await tester.pump();

    expect(find.text('Informe seu nome.'), findsOneWidget);
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(find.text('Use pelo menos 8 caracteres.'), findsOneWidget);
  });

  testWidgets('cadastro válido cria a sessão e exibe o nome informado',
      (tester) async {
    await tester.pumpWidget(
      AgileKnowledgeApp(authRepository: FakeAuthRepository()),
    );

    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('signUpName')),
      'Ana Silva',
    );
    await tester.enterText(
      find.byKey(const Key('signUpEmail')),
      'ana@exemplo.com',
    );
    await tester.enterText(
      find.byKey(const Key('signUpPassword')),
      'Senha123',
    );
    await tester.enterText(
      find.byKey(const Key('signUpPasswordConfirmation')),
      'Senha123',
    );
    await tester.ensureVisible(find.byKey(const Key('signUpSubmit')));
    await tester.tap(find.byKey(const Key('signUpSubmit')));
    await tester.pumpAndSettle();

    expect(find.text('Olá, Ana Silva'), findsOneWidget);
  });

  testWidgets('cadastro pendente informa confirmação e não autentica',
      (tester) async {
    await tester.pumpWidget(
      AgileKnowledgeApp(
        authRepository: FakeAuthRepository(requiresEmailConfirmation: true),
      ),
    );

    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('signUpName')), 'Ana Silva');
    await tester.enterText(
      find.byKey(const Key('signUpEmail')),
      'ana@exemplo.com',
    );
    await tester.enterText(
      find.byKey(const Key('signUpPassword')),
      'Senha123',
    );
    await tester.enterText(
      find.byKey(const Key('signUpPasswordConfirmation')),
      'Senha123',
    );
    await tester.tap(find.byKey(const Key('signUpSubmit')));
    await tester.pumpAndSettle();

    expect(find.text('Confirme seu e-mail'), findsOneWidget);
    await tester.tap(find.text('Entendi'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('signInEmail')), findsOneWidget);
  });

  testWidgets('tela de e-mail confirmado leva ao login', (tester) async {
    await tester.pumpWidget(
      AgileKnowledgeApp(authRepository: FakeAuthRepository()),
    );

    final context = tester.element(find.byType(SignInPage));
    Navigator.of(context).pushNamed(AppRoutes.emailConfirmed);
    await tester.pumpAndSettle();

    expect(find.byType(EmailConfirmedPage), findsOneWidget);
    await tester.tap(find.byKey(const Key('emailConfirmedGoToSignIn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('signInEmail')), findsOneWidget);
  });

  testWidgets(
      'callback de confirmação exibe notificação para conta autenticada',
      (tester) async {
    await tester.pumpWidget(
      AgileKnowledgeApp(
        authRepository: FakeAuthRepository(
          initialUser: const AppUser(
            id: 'user-confirmed',
            name: 'Ana',
            email: 'ana@exemplo.com',
            isEmailConfirmed: true,
          ),
        ),
        showEmailConfirmationNotification: true,
      ),
    );
    await tester.pump();

    expect(
      find.text('E-mail confirmado com sucesso. Você já pode usar o sistema.'),
      findsOneWidget,
    );
    expect(find.text('Olá, Ana'), findsOneWidget);
  });

  test('ocorrência nova começa como Registrada', () async {
    final occurrences = FakeOccurrenceRepository();
    final occurrence = await occurrences.create(
      NewOccurrence(
        title: 'Corrigir API',
        project: 'Sprint 17',
        occurredOn: DateTime(2026, 11, 15),
        context: 'Dependência indisponível',
        impact: 'Entrega atrasada',
      ),
    );

    expect(occurrence.status, OccurrenceStatus.registered);
    expect(occurrence.title, 'Corrigir API');
  });
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    AppUser? initialUser,
    this.requiresEmailConfirmation = false,
  }) : _currentUser = initialUser;

  final _controller = StreamController<AppUser?>.broadcast();
  final bool requiresEmailConfirmation;
  AppUser? _currentUser;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    _currentUser = AppUser(
      id: 'user-1',
      name: 'Gustavo',
      email: email,
      isEmailConfirmed: true,
    );
    _controller.add(_currentUser);
  }

  @override
  Future<SignUpResult> signUp({
    required String name,
    required String email,
    required String password,
    String? emailRedirectTo,
  }) async {
    if (requiresEmailConfirmation) {
      return const SignUpResult(requiresEmailConfirmation: true);
    }
    _currentUser = AppUser(
      id: 'user-1',
      name: name,
      email: email,
      isEmailConfirmed: true,
    );
    _controller.add(_currentUser);
    return const SignUpResult(requiresEmailConfirmation: false);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }
}

class FakeOccurrenceRepository implements OccurrenceRepository {
  Occurrence? lastCreated;
  final List<Occurrence> items = [];

  @override
  Future<Occurrence> create(NewOccurrence occurrence) async {
    lastCreated = Occurrence(
      id: 'occurrence-1',
      title: occurrence.title.trim(),
      project: occurrence.project.trim(),
      occurredOn: occurrence.occurredOn,
      context: occurrence.context.trim(),
      impact: occurrence.impact.trim(),
      status: OccurrenceStatus.registered,
    );
    items.add(lastCreated!);
    return lastCreated!;
  }

  @override
  Future<Occurrence?> getById(String id) async {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<List<Occurrence>> listMine() async => items;

  @override
  Future<Occurrence> updateContext(String id, String context) async {
    final item = await getById(id);
    if (item == null || item.status == OccurrenceStatus.completed) {
      throw StateError('not found');
    }
    final updated = Occurrence(
      id: item.id,
      title: item.title,
      project: item.project,
      occurredOn: item.occurredOn,
      context: context.trim(),
      impact: item.impact,
      status: item.status,
    );
    items[items.indexWhere((item) => item.id == id)] = updated;
    return updated;
  }
}
