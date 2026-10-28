import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _goal;

  @override
  void initState() {
    super.initState();
    _goal = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = StateScope.of(context);
    final user = state.currentUser;
    if (user != null && _goal.text.isEmpty) {
      _goal.text = state.goalFor(user.id);
    }
  }

  @override
  void dispose() {
    _goal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final user = state.currentUser;
    if (user == null) return const SizedBox.shrink();
    final peer = user.peerId == null ? null : state.userById(user.peerId!);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(user.name, style: Theme.of(context).textTheme.headlineMedium),
          Text(user.email, style: const TextStyle(color: muted)),
          const SizedBox(height: 4),
          Text(user.roleLabel, style: const TextStyle(color: pine, fontWeight: FontWeight.w700)),
          if (peer != null) ...[
            const SizedBox(height: 8),
            Text('Peer: ${peer.name}'),
          ],
          const SizedBox(height: 16),
          const Text(
            'The active trial keeps location surveys on for two weeks. A flagged place asks again on every entry.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _goal,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Goal to reduce use'),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Save goal',
            onPressed: () {
              state.setGoal(user.id, _goal.text);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Goal saved for this session.')),
              );
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => leaveAndSignOut(context),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
