import 'app_user.dart';

class SignUpResult {
  const SignUpResult({required this.requiresEmailConfirmation});

  final bool requiresEmailConfirmation;
}

class EmailNotConfirmedException implements Exception {
  const EmailNotConfirmedException();
}

abstract interface class AuthRepository {
  AppUser? get currentUser;

  Stream<AppUser?> get authStateChanges;

  Future<void> signIn({required String email, required String password});

  Future<SignUpResult> signUp({
    required String name,
    required String email,
    required String password,
    String? emailRedirectTo,
  });

  Future<void> signOut();
}
