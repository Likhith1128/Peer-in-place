import 'package:flutter/material.dart';

import '../content.dart';
import '../theme.dart';
import '../widgets.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final pending = state.pending;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: state.cancelPending,
        ),
        title: const Text('Verify'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confirm your role',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pending == null
                        ? 'Enter the code from the study team.'
                        : 'A code from the study team decides whether ${pending.email} is a participant, peer, or admin.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    key: const Key('verify-field'),
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Verification code',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: const TextStyle(color: clay)),
                  ],
                  const SizedBox(height: 16),
                  PrimaryButton(
                    key: const Key('verify-button'),
                    label: 'Continue',
                    onPressed: () {
                      final error = state.verify(_code.text);
                      if (error != null) setState(() => _error = error);
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Prototype codes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text('Participant: $participantCode'),
                  Text('Peer: $peerCode'),
                  Text('Admin: $adminCode'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
