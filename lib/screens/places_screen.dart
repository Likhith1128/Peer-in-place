import 'package:flutter/material.dart';

import '../location_service.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'survey_flow.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  final _service = const LocationService();
  String? _status;

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final user = state.currentUser!;
    final places = state.placesFor(user.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Flagged places')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            '${places.length} of 5 places. Surveys stay on for the trial and open again on every entry.',
            style: const TextStyle(color: muted),
          ),
          if (_status != null) ...[
            const SizedBox(height: 8),
            Text(_status!, style: const TextStyle(color: clay)),
          ],
          const SizedBox(height: 12),
          PrimaryButton(
            key: const Key('check-nearby'),
            label: 'Check nearby places',
            icon: Icons.my_location,
            onPressed: () => _checkNearby(places),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: places.length >= 5
                ? null
                : () => _saveHere(state, user.id),
            child: const Text('Save where I am now'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: places.length >= 5 ? null : () => _addManual(state, user.id),
            child: const Text('Add a place by name'),
          ),
          const SizedBox(height: 16),
          for (final place in places) ...[
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        place.isHighRisk ? Icons.warning_amber : Icons.park_outlined,
                        color: place.isHighRisk ? clay : moss,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          place.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                        ),
                      ),
                      Text(
                        place.isHighRisk ? 'High-risk' : 'Supportive',
                        style: TextStyle(
                          color: place.isHighRisk ? clay : moss,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(place.note),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    key: Key('arrive-${place.id}'),
                    label: 'Arrive',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => SurveyFlow(
                          kind: place.isHighRisk
                              ? SurveyKind.location
                              : SurveyKind.healthy,
                          placeId: place.id,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => state.removePlace(place.id),
                      child: const Text('Remove'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Future<void> _checkNearby(List<Place> places) async {
    setState(() => _status = 'Checking location…');
    final fix = await _service.currentFix();
    if (!mounted) return;
    if (!fix.ok) {
      setState(() => _status = fix.message);
      return;
    }
    Place? nearest;
    var best = double.infinity;
    for (final place in places) {
      if (place.latitude == null || place.longitude == null) continue;
      final meters = _service.distanceMeters(
        fromLat: fix.latitude!,
        fromLng: fix.longitude!,
        toLat: place.latitude!,
        toLng: place.longitude!,
      );
      if (meters <= 150 && meters < best) {
        best = meters;
        nearest = place;
      }
    }
    if (nearest == null) {
      setState(() => _status = 'No flagged place with a saved pin is within 150 meters.');
      return;
    }
    setState(() => _status = 'You are near ${nearest!.name}.');
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SurveyFlow(
          kind: nearest!.isHighRisk ? SurveyKind.location : SurveyKind.healthy,
          placeId: nearest.id,
        ),
      ),
    );
  }

  Future<void> _saveHere(dynamic state, String userId) async {
    final fix = await _service.currentFix();
    if (!mounted) return;
    if (!fix.ok) {
      setState(() => _status = fix.message);
      return;
    }
    final draft = await _askForPlace(context);
    if (draft == null || !mounted) return;
    final error = state.addPlace(
      participantId: userId,
      name: draft.name,
      kind: draft.kind,
      note: draft.note,
      latitude: fix.latitude,
      longitude: fix.longitude,
    );
    setState(() => _status = error ?? 'Saved ${draft.name} at your current location.');
  }

  Future<void> _addManual(dynamic state, String userId) async {
    final draft = await _askForPlace(context);
    if (draft == null || !mounted) return;
    final error = state.addPlace(
      participantId: userId,
      name: draft.name,
      kind: draft.kind,
      note: draft.note,
    );
    setState(() => _status = error);
  }
}

class _PlaceDraft {
  const _PlaceDraft(this.name, this.kind, this.note);
  final String name;
  final PlaceKind kind;
  final String note;
}

Future<_PlaceDraft?> _askForPlace(BuildContext context) {
  final name = TextEditingController();
  final note = TextEditingController();
  var kind = PlaceKind.highRisk;
  return showDialog<_PlaceDraft>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: const Text('Flag a place'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Place name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: note,
              decoration: const InputDecoration(labelText: 'Note from peer or you'),
            ),
            const SizedBox(height: 8),
            SegmentedButton<PlaceKind>(
              segments: const [
                ButtonSegment(value: PlaceKind.highRisk, label: Text('High-risk')),
                ButtonSegment(value: PlaceKind.healthy, label: Text('Supportive')),
              ],
              selected: {kind},
              onSelectionChanged: (value) => setLocal(() => kind = value.first),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              _PlaceDraft(name.text, kind, note.text),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
