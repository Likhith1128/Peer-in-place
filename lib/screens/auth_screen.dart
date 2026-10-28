import 'package:flutter/material.dart';

import '../content.dart';
import '../theme.dart';
import '../widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _create = false;
  bool _forgot = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final state = StateScope.of(context);
    setState(() => _error = null);
    if (_forgot) {
      final error = state.resetPassword(_email.text);
      setState(() {
        _error = error ??
            'Password reset for this prototype. Use $demoPassword to sign in.';
        _forgot = error != null;
      });
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_create) {
      final error = state.beginSignUp(
        _email.text,
        _password.text,
        _confirm.text,
      );
      if (error != null) setState(() => _error = error);
      return;
    }
    final ok = state.signIn(_email.text, _password.text);
    if (!ok) {
      setState(() => _error = 'Email or password does not match an active account.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Mark(),
                    const SizedBox(height: 18),
                    Text(
                      _forgot
                          ? 'Reset password'
                          : _create
                              ? 'Create account'
                              : 'Peer in Place',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _forgot
                          ? 'Prototype accounts are reset to the shared demo password.'
                          : 'Support that meets you at the places that matter. Android, iOS, and web.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                    const SizedBox(height: 22),
                    TextFormField(
                      key: const Key('email-field'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (!text.contains('@')) return 'Enter your email';
                        return null;
                      },
                    ),
                    if (!_forgot) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('password-field'),
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password'),
                        validator: (value) {
                          if ((value ?? '').length < 8) return 'At least 8 characters';
                          return null;
                        },
                      ),
                    ],
                    if (_create) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('confirm-field'),
                        controller: _confirm,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Confirm password'),
                        validator: (value) {
                          if (value != _password.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: clay)),
                    ],
                    const SizedBox(height: 16),
                    PrimaryButton(
                      key: Key(_create
                          ? 'sign-up-button'
                          : _forgot
                              ? 'reset-button'
                              : 'sign-in-button'),
                      label: _forgot
                          ? 'Reset password'
                          : _create
                              ? 'Create account'
                              : 'Sign in',
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => setState(() {
                            if (_create || _forgot) {
                              _create = false;
                              _forgot = false;
                            } else {
                              _create = true;
                            }
                            _error = null;
                          }),
                          child: Text(_create || _forgot ? 'Sign in' : 'Create account'),
                        ),
                        if (!_create)
                          TextButton(
                            onPressed: () => setState(() {
                              _forgot = !_forgot;
                              _create = false;
                              _error = null;
                            }),
                            child: Text(_forgot ? 'Back' : 'Forgot password?'),
                          ),
                      ],
                    ),
                    if (!_create && !_forgot) ...[
                      const Divider(height: 32),
                      Text(
                        'Prototype accounts',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Password for each sample account is $demoPassword.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      _DemoButton(
                        buttonKey: const Key('demo-participant'),
                        label: 'Continue as participant',
                        detail: 'jordan@peerinplace.app',
                        email: 'jordan@peerinplace.app',
                      ),
                      _DemoButton(
                        buttonKey: const Key('demo-peer'),
                        label: 'Continue as peer',
                        detail: 'morgan@peerinplace.app',
                        email: 'morgan@peerinplace.app',
                      ),
                      _DemoButton(
                        buttonKey: const Key('demo-admin'),
                        label: 'Continue as admin',
                        detail: 'alex@peerinplace.app',
                        email: 'alex@peerinplace.app',
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoButton extends StatelessWidget {
  const _DemoButton({
    required this.buttonKey,
    required this.label,
    required this.detail,
    required this.email,
  });

  final Key buttonKey;
  final String label;
  final String detail;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton(
          key: buttonKey,
          onPressed: () {
            StateScope.of(context).signIn(email, demoPassword);
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: line),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            backgroundColor: Colors.white,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: ink, fontWeight: FontWeight.w700)),
                Text(detail, style: const TextStyle(color: muted, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: pine,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.place, color: Colors.white),
    );
  }
}
