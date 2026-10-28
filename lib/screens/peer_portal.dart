import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'messages_screen.dart';

class PeerPortal extends StatefulWidget {
  const PeerPortal({super.key});

  @override
  State<PeerPortal> createState() => _PeerPortalState();
}

class _PeerPortalState extends State<PeerPortal> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final me = state.currentUser!;
    final caseload =
        state.participants.where((person) => person.peerId == me.id).toList();
    final selected = _selectedId ?? (caseload.isEmpty ? null : caseload.first.id);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 960;
        final list = _Caseload(
          me: me,
          people: caseload,
          selectedId: wide ? selected : null,
          onOpen: (id) {
            if (wide) {
              setState(() => _selectedId = id);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PeerDetailScreen(participantId: id),
                ),
              );
            }
          },
        );
        if (!wide) return list;
        return Scaffold(
          body: Row(
            children: [
              SizedBox(width: 380, child: list),
              const VerticalDivider(width: 1),
              Expanded(
                child: selected == null
                    ? const Center(child: Text('No participants on this caseload yet.'))
                    : PeerDetailScreen(participantId: selected, embedded: true),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Caseload extends StatelessWidget {
  const _Caseload({
    required this.me,
    required this.people,
    required this.onOpen,
    this.selectedId,
  });

  final AppUser me;
  final List<AppUser> people;
  final String? selectedId;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final alerts = state.alertsFor(me.id);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peer portal'),
        actions: [
          TextButton(
            onPressed: () => leaveAndSignOut(context),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(me.name, style: Theme.of(context).textTheme.titleLarge),
          Text('${people.length} on your caseload', style: const TextStyle(color: muted)),
          const SizedBox(height: 12),
          if (alerts.isNotEmpty) ...[
            const Text('Location alerts', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final alert in alerts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SoftCard(
                  color: alert.read ? Colors.white : const Color(0xFFFFF6F1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${state.userById(alert.participantId)?.name ?? 'Participant'} entered ${alert.placeName}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${shortDate(alert.at)} ${friendlyTime(alert.at)}',
                        style: const TextStyle(color: muted),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            state.markAlertRead(alert.id);
                            onOpen(alert.participantId);
                          },
                          child: const Text('Open'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 8),
          for (final person in people)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SoftCard(
                color: person.id == selectedId ? const Color(0x140E6B62) : Colors.white,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(person.email),
                  trailing: StatusPill(active: person.active),
                  onTap: () => onOpen(person.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PeerDetailScreen extends StatelessWidget {
  const PeerDetailScreen({
    required this.participantId,
    this.embedded = false,
    super.key,
  });

  final String participantId;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final person = state.userById(participantId);
    if (person == null) {
      return const Scaffold(body: Center(child: Text('This participant is no longer here.')));
    }
    final summary = state.summaryFor(person.id);
    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(person.name, style: Theme.of(context).textTheme.headlineMedium),
        Text(person.email, style: const TextStyle(color: muted)),
        const SizedBox(height: 8),
        StatusPill(active: person.active),
        const SizedBox(height: 16),
        Text('This week', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MiniStat('Daily surveys', '${summary.dailyCount}'),
            _MiniStat('Reported use', '${summary.useDays} days'),
            _MiniStat('Location surveys', '${summary.locationCount}'),
          ],
        ),
        const SizedBox(height: 16),
        Text('Goal', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(state.goalFor(person.id)),
        const SizedBox(height: 16),
        Text('Flagged places', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final place in state.placesFor(person.id))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SoftCard(
              child: Text(
                '${place.name} · ${place.isHighRisk ? 'High-risk' : 'Supportive'}',
              ),
            ),
          ),
        const SizedBox(height: 8),
        PrimaryButton(
          label: 'Message',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => MessagesScreen(
                participantId: person.id,
                peerId: state.currentUser!.id,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => _schedule(context, state, person),
          child: const Text('Schedule a message'),
        ),
      ],
    );
    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(person.name)),
      body: body,
    );
  }

  Future<void> _schedule(BuildContext context, dynamic state, AppUser person) async {
    final header = TextEditingController();
    final body = TextEditingController();
    var when = DateTime.now().add(const Duration(days: 1));
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: header,
              maxLength: 48,
              decoration: const InputDecoration(labelText: 'Header'),
            ),
            TextField(
              controller: body,
              maxLength: 240,
              decoration: const InputDecoration(labelText: 'Body'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Schedule')),
        ],
      ),
    );
    if (saved != true) return;
    state.sendMessage(
      participantId: person.id,
      peerId: state.currentUser.id,
      senderId: state.currentUser.id,
      senderRole: UserRole.peer,
      body: body.text,
      header: header.text,
      scheduledFor: when,
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: muted, fontSize: 12)),
        ],
      ),
    );
  }
}
