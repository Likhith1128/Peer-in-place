import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../csv_export.dart';
import '../format.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'messages_screen.dart';

class AdminPortal extends StatefulWidget {
  const AdminPortal({super.key});

  @override
  State<AdminPortal> createState() => _AdminPortalState();
}

class _AdminPortalState extends State<AdminPortal> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _Dashboard(),
      const _PeoplePage(peers: false),
      const _PeoplePage(peers: true),
      const _Inbox(),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 900;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (index) => setState(() => _index = index),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: TextButton(
                  onPressed: () => leaveAndSignOut(context),
                  child: const Text('Sign out'),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups),
                  label: Text('Participants'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.badge_outlined),
                  selectedIcon: Icon(Icons.badge),
                  label: Text('Peers'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inbox_outlined),
                  selectedIcon: Icon(Icons.inbox),
                  label: Text('Inbox'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: pages[_index]),
          ],
        ),
      );
    }
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'Participants'),
          NavigationDestination(icon: Icon(Icons.badge_outlined), label: 'Peers'),
          NavigationDestination(icon: Icon(Icons.inbox_outlined), label: 'Inbox'),
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final activeParticipants =
        state.participants.where((person) => person.active).length;
    final activePeers = state.peers.where((person) => person.active).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin portal'),
        actions: [
          if (MediaQuery.sizeOf(context).width < 900)
            TextButton(
              onPressed: () => leaveAndSignOut(context),
              child: const Text('Sign out'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            state.currentUser?.name ?? 'Org admin',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Text('Directory for the Peer in Place feasibility prototype.'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _CountCard('Active participants', '$activeParticipants')),
              const SizedBox(width: 8),
              Expanded(child: _CountCard('Active peers', '$activePeers')),
            ],
          ),
          const SizedBox(height: 12),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active participants over time',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TrendChart(
                  values: state.activeSeries(UserRole.participant).map((n) => n.toDouble()).toList(),
                  color: pine,
                  max: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active peers over time',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TrendChart(
                  values: state.activeSeries(UserRole.peer).map((n) => n.toDouble()).toList(),
                  color: moss,
                  max: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trial shape', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text(
                  'Participants can flag up to five places. Location surveys stay on for the two-week active period and open again on every entry. A high-risk entry alerts the assigned peer. Morning surveys run through the trial. Crisis contacts live in Help, separate from peer messages.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            key: const Key('export-csv'),
            label: 'Export database as CSV',
            icon: Icons.download,
            onPressed: () => _export(context),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final csv = StateScope.of(context).exportCsv();
    final downloaded = downloadTextFile('peer-in-place.csv', csv);
    if (!downloaded) {
      await Clipboard.setData(ClipboardData(text: csv));
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          downloaded
              ? 'Downloaded peer-in-place.csv'
              : 'CSV copied. This device could not start a file download.',
        ),
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: muted)),
        ],
      ),
    );
  }
}

class _PeoplePage extends StatefulWidget {
  const _PeoplePage({required this.peers});

  final bool peers;

  @override
  State<_PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<_PeoplePage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final source = widget.peers ? state.peers : state.participants;
    final people = source.where((person) {
      final haystack = '${person.name} ${person.email} ${person.id}'.toLowerCase();
      return haystack.contains(_query.trim().toLowerCase());
    }).toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.peers ? 'Peers' : 'Participants')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search',
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(flex: 3, child: Text('Name', style: TextStyle(color: muted))),
              Expanded(flex: 4, child: Text('Email', style: TextStyle(color: muted))),
              Expanded(child: Text('Status', style: TextStyle(color: muted))),
            ],
          ),
          const Divider(),
          for (final person in people)
            InkWell(
              onTap: widget.peers
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ParticipantAdminPage(participantId: person.id),
                        ),
                      ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        person.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(person.email, overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(child: StatusPill(active: person.active)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ParticipantAdminPage extends StatelessWidget {
  const ParticipantAdminPage({required this.participantId, super.key});

  final String participantId;

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final person = state.userById(participantId);
    if (person == null || person.role != UserRole.participant) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This participant is no longer in the directory.')),
      );
    }
    final summary = state.summaryFor(person.id);
    final peer = person.peerId == null ? null : state.userById(person.peerId!);
    return Scaffold(
      appBar: AppBar(title: Text(person.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(person.email),
          Text('Created ${shortDate(person.createdAt)}', style: const TextStyle(color: muted)),
          const SizedBox(height: 8),
          StatusPill(active: person.active),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CountCard('Daily surveys', '${summary.dailyCount}'),
              _CountCard('Reported use', '${summary.useDays} days'),
              _CountCard('Location surveys', '${summary.locationCount}'),
              _CountCard('Messages', '${state.threadFor(person.id).length}'),
              _CountCard('Calendar', '${state.eventsFor(person.id).length}'),
            ],
          ),
          const SizedBox(height: 16),
          Text('Assigned peer', style: Theme.of(context).textTheme.titleMedium),
          DropdownButton<String?>(
            value: person.peerId,
            isExpanded: true,
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Unassigned')),
              for (final candidate in state.peers)
                DropdownMenuItem(value: candidate.id, child: Text(candidate.name)),
            ],
            onChanged: (value) => state.assignPeer(person.id, value),
          ),
          if (peer != null)
            PrimaryButton(
              label: 'Open message thread',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => MessagesScreen(
                    participantId: person.id,
                    peerId: peer.id,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _addEvent(context, state, person),
            child: const Text('Add calendar event'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => state.setActive(person.id, !person.active),
            child: Text(person.active ? 'Mark inactive' : 'Mark active'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _confirmRole(context, state, person),
            child: const Text('Set account type to peer'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _confirmDelete(context, state, person),
            child: const Text('Delete participant', style: TextStyle(color: clay)),
          ),
          const SizedBox(height: 12),
          for (final event in state.eventsFor(person.id))
            SoftCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text('${event.title} · ${shortDate(event.start)} ${friendlyTime(event.start)}'),
                  ),
                  IconButton(
                    onPressed: () => state.deleteEvent(event.id),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmRole(BuildContext context, dynamic state, AppUser person) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set account type to peer'),
        content: const Text(
          'Setting a participant account to Peer gives them a caseload login. Proceed with caution.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (ok == true) {
      state.setRole(person.id, UserRole.peer);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _confirmDelete(BuildContext context, dynamic state, AppUser person) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete participant'),
        content: const Text(
          'Deleting a participant account cannot be undone. Proceed with caution.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      final error = state.deleteUser(person.id) as String?;
      if (!context.mounted) return;
      if (error != null) {
        await showNotice(context, error);
      } else {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _addEvent(BuildContext context, dynamic state, AppUser person) async {
    final title = TextEditingController();
    final location = TextEditingController();
    final notes = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: location, decoration: const InputDecoration(labelText: 'Location')),
            TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    if (saved == true && title.text.trim().isNotEmpty) {
      state.addEvent(
        participantId: person.id,
        title: title.text,
        start: DateTime.now().add(const Duration(days: 1, hours: 3)),
        location: location.text,
        notes: notes.text,
        createdBy: state.currentUser.name,
      );
    }
  }
}

class _Inbox extends StatelessWidget {
  const _Inbox();

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final notes = state.contacts.reversed.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: notes.isEmpty
          ? const Center(child: Text('No contact messages yet.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final note in notes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(note.subject, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(note.fromEmail, style: const TextStyle(color: muted)),
                          const SizedBox(height: 6),
                          Text(note.body),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
