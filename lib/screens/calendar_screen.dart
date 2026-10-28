import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _visible;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visible = DateTime(now.year, now.month);
    _selected = dateOnly(now);
  }

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final user = state.currentUser!;
    final surveys = state.surveysFor(user.id);
    final events = state.eventsFor(user.id);
    final days = DateUtils.getDaysInMonth(_visible.year, _visible.month);
    final lead = DateTime(_visible.year, _visible.month, 1).weekday % 7;
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() {
                  _visible = DateTime(_visible.year, _visible.month - 1);
                }),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${monthName(_visible)} ${_visible.year}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _visible = DateTime(_visible.year, _visible.month + 1);
                }),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: [
              for (final label in shortWeekdays)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < lead; i++) const SizedBox.shrink(),
              for (var day = 1; day <= days; day++)
                _CalendarDay(
                  day: DateTime(_visible.year, _visible.month, day),
                  selected: _selected,
                  marked: surveys.any(
                        (survey) => sameDay(
                          survey.at,
                          DateTime(_visible.year, _visible.month, day),
                        ),
                      ) ||
                      events.any(
                        (event) => sameDay(
                          event.start,
                          DateTime(_visible.year, _visible.month, day),
                        ),
                      ),
                  onTap: (value) => setState(() => _selected = value),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            friendlyDate(_selected),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final survey in surveys.where((survey) => sameDay(survey.at, _selected)))
            _EntryTile(survey: survey, placeName: _placeName(state, survey)),
          for (final event in events.where((event) => sameDay(event.start, _selected)))
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('${friendlyTime(event.start)} · ${event.location}'),
                  if (event.notes.isNotEmpty)
                    Text(event.notes, style: const TextStyle(color: muted)),
                ],
              ),
            ),
          if (surveys.every((survey) => !sameDay(survey.at, _selected)) &&
              events.every((event) => !sameDay(event.start, _selected)))
            const Text('Nothing recorded for this day.'),
        ],
      ),
    );
  }

  String _placeName(dynamic state, SurveyRecord survey) {
    if (survey.placeId == null) return '';
    return state.placeById(survey.placeId!)?.name ?? '';
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.selected,
    required this.marked,
    required this.onTap,
  });

  final DateTime day;
  final DateTime selected;
  final bool marked;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = sameDay(day, selected);
    return InkWell(
      onTap: () => onTap(day),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? pine : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: isSelected ? Colors.white : ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: marked ? clay : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.survey, required this.placeName});

  final SurveyRecord survey;
  final String placeName;

  @override
  Widget build(BuildContext context) {
    final title = switch (survey.kind) {
      SurveyKind.daily => 'Daily survey submitted',
      SurveyKind.location => 'Location survey submitted',
      SurveyKind.healthy => 'Supportive place check-in',
    };
    final where = placeName.isEmpty ? survey.mood ?? '' : placeName;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(
              where.isEmpty ? friendlyTime(survey.at) : '$where · ${friendlyTime(survey.at)}',
              style: const TextStyle(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
