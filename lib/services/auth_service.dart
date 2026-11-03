import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Wraps Firebase Authentication and exposes the login state to the app.
class AuthService extends ChangeNotifier {
  AuthService(this._auth) {
    _sub = _auth.authStateChanges().listen((user) {
      _user = user;
      _initializing = false;
      notifyListeners();
    });
  }

  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _sub;

  User? _user;
  bool _initializing = true;
  bool _holdOnRegister = false;

  User? get user => _user;

  /// True until Firebase has told us whether someone is already logged in.
  bool get initializing => _initializing;

  /// While true, a freshly registered user stays on the Register screen so the
  /// success message can be seen before moving on to the List screen.
  bool get holdOnRegister => _holdOnRegister;

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> register(String email, String password) async {
    _holdOnRegister = true;
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (_) {
      _holdOnRegister = false;
      rethrow;
    }
  }

  void finishRegistration() {
    if (!_holdOnRegister) return;
    _holdOnRegister = false;
    notifyListeners();
  }

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
