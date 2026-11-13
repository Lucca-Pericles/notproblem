import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/app_user.dart';
import '../../domain/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repository) : _user = _repository.currentUser {
    _isLoadingSession = false;
    _subscription = _repository.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  final AuthRepository _repository;
  late final StreamSubscription<AppUser?> _subscription;

  AppUser? _user;
  bool _isLoadingSession = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoadingSession => _isLoadingSession;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<bool> signIn({required String email, required String password}) async {
    return _run(() async {
      await _repository.signIn(email: email, password: password);
      _user = _repository.currentUser;
    });
  }

  Future<SignUpResult?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    SignUpResult? result;
    final success = await _run(() async {
      result = await _repository.signUp(
        name: name,
        email: email,
        password: password,
      );
      _user = _repository.currentUser;
    });

    return success ? result : null;
  }

  Future<void> signOut() async {
    await _run(() async {
      await _repository.signOut();
      _user = null;
    });
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (error) {
      _errorMessage = _friendlyMessage(error);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  String _friendlyMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (message.contains('user already registered')) {
      return 'Já existe uma conta com este e-mail.';
    }
    if (message.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }
    if (message.contains('network') || message.contains('socket')) {
      return 'Não foi possível conectar. Verifique sua internet.';
    }

    return 'Não foi possível concluir a operação. Tente novamente.';
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
