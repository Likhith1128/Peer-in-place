import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'help_screen.dart';
import 'messages_screen.dart';
import 'places_screen.dart';
import 'profile_screen.dart';
import 'survey_flow.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final user = state.currentUser!;
    final done = state.completedDailyOn(user.id);
    final recent = state
        .surveysFor(user.id)
        .where((survey) => survey.kind == SurveyKind.daily)
        .toList();
    final peer = user.peerId == null ? null : state.userById(user.peerId!);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peer in Place'),
        actions: [
          IconButton(
            tooltip: 'Help',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const HelpScreen()),
            ),
            icon: const Icon(Icons.health_and_safety_outlined),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            ),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text('Welcome back', style: Theme.of(context).textTheme.bodyMedium),
          Text(user.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            user.roleLabel,
            style: const TextStyle(color: pine, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Today is ${friendlyDate(state.now)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          const _WeekStrip(),
          const SizedBox(height: 14),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done ? 'Daily survey complete' : 'Morning survey',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  done
                      ? 'Great job. Today’s check-in is in.'
                      : recent.isEmpty
                          ? 'This check-in stays open through the trial.'
                          : 'Most recent: ${shortDate(recent.first.at)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                if (done)
                  const Text(
                    'Great job',
                    style: TextStyle(
                      color: moss,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                else
                  PrimaryButton(
                    key: const Key('take-daily'),
                    label: 'Take daily survey',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const SurveyFlow(kind: SurveyKind.daily),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SoftCard(
            color: const Color(0xFFFFF6F1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Flagged places',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Up to five places. High-risk entry opens a survey every visit. Supportive places send kudos.',
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  key: const Key('open-places'),
                  label: 'Review flagged places',
                  icon: Icons.place_outlined,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const PlacesScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peer == null ? 'No peer assigned yet' : 'Message ${peer.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Messages in the app are live between you and your peer. Crisis help is separate.',
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  key: const Key('open-messages'),
                  label: 'Message peer',
                  icon: Icons.chat_bubble_outline,
                  onPressed: () {
                    if (peer == null) {
                      showNotice(
                        context,
                        'An admin still needs to assign a peer to this account.',
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => MessagesScreen(
                          participantId: user.id,
                          peerId: peer.id,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final user = state.currentUser!;
    final today = dateOnly(state.now);
    final start = today.subtract(Duration(days: today.weekday % 7));
    final surveys = state.surveysFor(user.id);
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: _DayDot(
                label: shortWeekdays[i],
                day: start.add(Duration(days: i)),
                today: today,
                marked: surveys.any(
                  (survey) => sameDay(survey.at, start.add(Duration(days: i))),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.label,
    required this.day,
    required this.today,
    required this.marked,
  });

  final String label;
  final DateTime day;
  final DateTime today;
  final bool marked;

  @override
  Widget build(BuildContext context) {
    final isToday = sameDay(day, today);
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: muted)),
        const SizedBox(height: 6),
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isToday ? pine : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${day.day}',
            style: TextStyle(
              color: isToday ? Colors.white : ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: marked ? clay : Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
