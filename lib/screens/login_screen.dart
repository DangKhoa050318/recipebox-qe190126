import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import '../utils/validators.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitted = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      // On success the router moves to the List screen.
      await context.read<AuthService>().signIn(_email.text, _password.text);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = e.message ?? e.code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Form(
        key: _formKey,
        autovalidateMode:
            _submitted ? AutovalidateMode.always : AutovalidateMode.disabled,
        child: AutofillGroup(
          child: FormPage(
            children: [
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: Gap.lg),
              AppTextField(
                controller: _email,
                label: 'Email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
              ),
              const SizedBox(height: Gap.md),
              AppTextField(
                controller: _password,
                label: 'Password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: Validators.loginPassword,
              ),
              const SizedBox(height: Gap.lg),
              PrimaryButton(
                label: 'Login',
                icon: Icons.login,
                busy: _busy,
                onPressed: _submit,
              ),
              if (_error != null) FormMessage(text: _error!),
              const SizedBox(height: Gap.md),
              TextButton(
                onPressed: () => context.pushReplacement('/register'),
                child: const Text("Don't have an account? Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
