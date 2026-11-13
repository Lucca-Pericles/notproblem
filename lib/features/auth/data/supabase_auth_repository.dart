import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  AppUser? get currentUser => _mapUser(_client.auth.currentUser);

  @override
  Stream<AppUser?> get authStateChanges => _client.auth.onAuthStateChange
      .map((state) => _mapUser(state.session?.user));

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  @override
  Future<SignUpResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {'name': name.trim()},
    );

    return SignUpResult(requiresEmailConfirmation: response.session == null);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  AppUser? _mapUser(User? user) {
    if (user == null) return null;

    final name = (user.userMetadata?['name'] as String?)?.trim();
    final email = user.email ?? '';

    return AppUser(
      id: user.id,
      name: name?.isNotEmpty == true ? name! : _nameFromEmail(email),
      email: email,
    );
  }

  String _nameFromEmail(String email) {
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) return 'Usuário';

    return localPart[0].toUpperCase() + localPart.substring(1);
  }
}
