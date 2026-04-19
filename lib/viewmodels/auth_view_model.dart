import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthViewModel extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;

  bool get isLoggedIn => _auth.currentUser != null;
  String errorMessage = '';

  AuthViewModel() {
    _auth.authStateChanges().listen((_) => notifyListeners());
  }

  Future<void> signIn(String email, String password) async {
    errorMessage = '';
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      errorMessage = _localizedError(e.code);
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password) async {
    errorMessage = '';
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      errorMessage = _localizedError(e.code);
      notifyListeners();
    }
  }

  void signOut() => _auth.signOut();

  String _localizedError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'メールアドレスまたはパスワードが正しくありません';
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています';
      case 'weak-password':
        return 'パスワードは6文字以上で設定してください';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      default:
        return 'エラーが発生しました ($code)';
    }
  }
}
