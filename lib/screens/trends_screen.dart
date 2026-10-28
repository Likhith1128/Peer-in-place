import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final user = state.currentUser!;
    final summary = state.summaryFor(user.id);
    final mood = state.moodSeries(user.id);
    final use = state.useSeries(user.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Trends')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            'Mood and substance use over this trial. A map of GPS movement is not part of this view.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Stat(label: 'Daily surveys', value: '${summary.dailyCount}')),
              const SizedBox(width: 8),
              Expanded(child: _Stat(label: 'Use days', value: '${summary.useDays}')),
              const SizedBox(width: 8),
              Expanded(child: _Stat(label: 'Location surveys', value: '${summary.locationCount}')),
            ],
          ),
          const SizedBox(height: 12),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mood', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                const Text('1 very low · 5 steady', style: TextStyle(color: muted)),
                const SizedBox(height: 8),
                TrendChart(values: mood, color: pine, min: 1, max: 5),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reported use',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const Text('1 on days use was reported', style: TextStyle(color: muted)),
                const SizedBox(height: 8),
                TrendChart(values: use, color: clay, min: 0, max: 1),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Counts above are the last 7 days, including today.',
            style: TextStyle(color: muted),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: muted, fontSize: 12)),
        ],
      ),
    );
  }
}
