import 'package:flutter/material.dart';

import 'app_state.dart';
import 'models.dart';
import 'screens/admin_portal.dart';
import 'screens/auth_screen.dart';
import 'screens/participant_shell.dart';
import 'screens/peer_portal.dart';
import 'screens/verify_screen.dart';
import 'theme.dart';
import 'widgets.dart';

void main() {
  runApp(const PeerInPlaceApp());
}

class PeerInPlaceApp extends StatefulWidget {
  const PeerInPlaceApp({super.key, this.state});

  final AppState? state;

  @override
  State<PeerInPlaceApp> createState() => _PeerInPlaceAppState();
}

class _PeerInPlaceAppState extends State<PeerInPlaceApp> {
  late final AppState state = widget.state ?? AppState();

  @override
  void dispose() {
    if (widget.state == null) state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StateScope(
      state: state,
      child: MaterialApp(
        title: 'Peer in Place',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final user = state.currentUser;
    if (user == null) {
      if (state.pending != null) return const VerifyScreen();
      return const AuthScreen();
    }
    return switch (user.role) {
      UserRole.participant => const PhoneFrame(child: ParticipantShell()),
      UserRole.peer => const PeerPortal(),
      UserRole.admin => const AdminPortal(),
    };
  }
}
