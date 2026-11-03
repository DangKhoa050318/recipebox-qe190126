import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import '../utils/validators.dart';
import '../widgets/common.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitted = false;
  bool _busy = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = context.read<AuthService>();
    try {
      await auth.register(_email.text, _password.text);
      if (!mounted) return;
      setState(() => _success = true);
      // Firebase signs the new user in; show the message briefly, then let
      // the router continue to the List screen.
      await Future<void>.delayed(const Duration(milliseconds: 2500));
      auth.finishRegistration();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = e.message ?? e.code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Form(
        key: _formKey,
        autovalidateMode:
            _submitted ? AutovalidateMode.always : AutovalidateMode.disabled,
        child: AutofillGroup(
          child: FormPage(
            children: [
              Text(
                'Create your account',
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
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.registerPassword,
              ),
              const SizedBox(height: Gap.md),
              AppTextField(
                controller: _confirm,
                label: 'Confirm password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (v) => Validators.confirmPassword(v, _password.text),
              ),
              const SizedBox(height: Gap.lg),
              PrimaryButton(
                label: 'Register',
                icon: Icons.person_add_alt,
                busy: _busy || _success,
                onPressed: _submit,
              ),
              if (_success)
                const FormMessage(text: 'Registration successful', isError: false),
              if (_error != null) FormMessage(text: _error!),
              const SizedBox(height: Gap.md),
              TextButton(
                onPressed: () => context.pushReplacement('/login'),
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
