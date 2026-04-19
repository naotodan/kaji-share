import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;

  bool get _isValid =>
      _emailCtrl.text.isNotEmpty && _passwordCtrl.text.length >= 6;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthViewModel>();
    if (_isSignUp) {
      await auth.signUp(_emailCtrl.text.trim(), _passwordCtrl.text);
    } else {
      await auth.signIn(_emailCtrl.text.trim(), _passwordCtrl.text);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.family_restroom, size: 72, color: Colors.blue),
              const SizedBox(height: 12),
              const Text(
                '夫婦分担アプリ',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('家事を公平に、仲良く',
                  style: TextStyle(color: Colors.grey, fontSize: 15)),
              const Spacer(),
              TextField(
                controller: _emailCtrl,
                decoration: _inputDeco('メールアドレス'),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                decoration: _inputDeco('パスワード（6文字以上）'),
                obscureText: true,
                onChanged: (_) => setState(() {}),
              ),
              if (auth.errorMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  auth.errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isValid ? Colors.blue : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isValid && !_isLoading ? _submit : null,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _isSignUp ? 'アカウント作成' : 'ログイン',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _isSignUp = !_isSignUp;
                  auth.errorMessage = '';
                }),
                child: Text(_isSignUp ? 'ログインはこちら' : '新規登録はこちら'),
              ),
              const Spacer(),
              const Text(
                '夫婦で同じアカウントを共有してください',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );
}
