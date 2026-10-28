import 'package:flutter/material.dart';

import '../app_state.dart';
import '../format.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'messages_screen.dart';

class SurveyFlow extends StatefulWidget {
  const SurveyFlow({required this.kind, this.placeId, super.key});

  final SurveyKind kind;
  final String? placeId;

  @override
  State<SurveyFlow> createState() => _SurveyFlowState();
}

class _SurveyFlowState extends State<SurveyFlow> {
  int _step = 0;
  bool _done = false;
  bool _leftEarly = false;
  String? _choice;
  String? _mood;
  String? _use;
  String? _intent;
  String? _context;
  String? _goal;
  String? _presence;

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final user = state.currentUser!;
    final place = widget.placeId == null ? null : state.placeById(widget.placeId!);
    final title = switch (widget.kind) {
      SurveyKind.daily => 'Daily survey',
      SurveyKind.location => 'Location survey',
      SurveyKind.healthy => 'Supportive place',
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_done || _step == 0) {
              Navigator.pop(context);
            } else {
              setState(() {
                _step -= 1;
                _choice = _valueForStep(_step);
              });
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (!_done) ...[
            Text(
              'Step ${_step + 1} of $_stepCount',
              style: const TextStyle(color: muted, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
          ],
          if (_done)
            _DonePane(
              title: _leftEarly ? 'Checked in' : 'Great job',
              body: _leftEarly
                  ? 'No survey was needed. Thanks for confirming where you are.'
                  : widget.kind == SurveyKind.daily
                      ? 'Thanks for completing your daily survey.'
                      : widget.kind == SurveyKind.healthy
                          ? 'Thanks for rating your mood in a place you chose.'
                          : 'Thanks for completing your location survey. Your peer can see the alert.',
              onClose: () => Navigator.pop(context),
              onMessage: user.peerId == null
                  ? null
                  : () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => MessagesScreen(
                            participantId: user.id,
                            peerId: user.peerId!,
                          ),
                        ),
                      );
                    },
            )
          else
            _stepBody(state, user, place),
        ],
      ),
    );
  }

  int get _stepCount => switch (widget.kind) {
        SurveyKind.daily => 5,
        SurveyKind.location => 5,
        SurveyKind.healthy => 3,
      };

  String? _valueForStep(int step) {
    if (widget.kind == SurveyKind.daily) {
      return switch (step) {
        1 => _mood,
        2 => _use,
        3 => _context,
        4 => _goal,
        _ => null,
      };
    }
    if (widget.kind == SurveyKind.location) {
      return switch (step) {
        0 => _presence,
        1 => _mood,
        2 => _intent,
        3 => _context,
        _ => null,
      };
    }
    return step == 1 ? _mood : null;
  }

  Widget _stepBody(AppState state, AppUser user, Place? place) {
    if (widget.kind == SurveyKind.daily && _step == 0) {
      return _InstructionStep(
        heading: 'Good morning',
        body:
            'This check-in takes about a minute. It asks about mood, use since yesterday, who was around, and your goal. It stays available through the trial, once each morning.',
        onContinue: () => setState(() => _step = 1),
      );
    }
    if (widget.kind == SurveyKind.healthy && _step == 0) {
      return _InstructionStep(
        heading: 'You are in a supportive place',
        body: place?.note ??
            'This is a place you marked as supportive. Rate your mood, then read your goal again.',
        onContinue: () => setState(() => _step = 1),
      );
    }
    if (widget.kind == SurveyKind.location && _step == 4) {
      return _InstructionStep(
        heading: place?.name ?? 'A note from your peer',
        body: place?.note ?? 'Your peer left a note for this place.',
        continueLabel: 'Finish survey',
        onContinue: () => _finish(state, user),
      );
    }
    if (widget.kind == SurveyKind.healthy && _step == 2) {
      return _InstructionStep(
        heading: 'Your goal',
        body: state.goalFor(user.id),
        continueLabel: 'Finish',
        onContinue: () => _finish(state, user),
      );
    }

    final prompt = _prompt(place);
    final options = _options();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(prompt, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        OptionList(
          options: options,
          selected: _choice,
          onSelected: (value) => setState(() => _choice = value),
        ),
        const SizedBox(height: 8),
        PrimaryButton(
          key: const Key('survey-continue'),
          label: 'Continue',
          onPressed: () {
            if (_choice == null) {
              showNotice(context, 'Choose an answer to continue.');
              return;
            }
            _storeChoice();
            if (widget.kind == SurveyKind.location &&
                _step == 0 &&
                _presence != presenceOptions.first) {
              _finish(state, user, leftEarly: true);
              return;
            }
            if (widget.kind == SurveyKind.daily && _step == 4) {
              _finish(state, user);
              return;
            }
            setState(() {
              _step += 1;
              _choice = _valueForStep(_step);
            });
          },
        ),
      ],
    );
  }

  String _prompt(Place? place) {
    if (widget.kind == SurveyKind.location && _step == 0) {
      return 'Are you at ${place?.name ?? 'this place'} right now?';
    }
    if (_step == 1 || (widget.kind == SurveyKind.healthy && _step == 1)) {
      return widget.kind == SurveyKind.daily
          ? 'How is your mood this morning?'
          : 'How is your mood right now?';
    }
    if (widget.kind == SurveyKind.daily && _step == 2) {
      return 'Since yesterday, did you use alcohol or other drugs?';
    }
    if (widget.kind == SurveyKind.location && _step == 2) {
      return 'How strong is the intent to use right now?';
    }
    if (widget.kind == SurveyKind.daily && _step == 3) {
      return 'What was the context?';
    }
    if (widget.kind == SurveyKind.location && _step == 3) {
      return 'Who is with you?';
    }
    return 'Did you take a step toward your goal?';
  }

  List<String> _options() {
    if (widget.kind == SurveyKind.location && _step == 0) return presenceOptions;
    if (_step == 1) return moodOptions;
    if (widget.kind == SurveyKind.daily && _step == 2) return useOptions;
    if (widget.kind == SurveyKind.location && _step == 2) return intentOptions;
    if (_step == 3) return contextOptions;
    return goalOptions;
  }

  void _storeChoice() {
    final value = _choice;
    if (widget.kind == SurveyKind.location && _step == 0) {
      _presence = value;
    } else if (_step == 1) {
      _mood = value;
    } else if (widget.kind == SurveyKind.daily && _step == 2) {
      _use = value;
    } else if (widget.kind == SurveyKind.location && _step == 2) {
      _intent = value;
    } else if (_step == 3) {
      _context = value;
    } else if (widget.kind == SurveyKind.daily && _step == 4) {
      _goal = value;
    }
  }

  void _finish(AppState state, AppUser user, {bool leftEarly = false}) {
    if (widget.kind == SurveyKind.daily) {
      final saved = state.recordDaily(
        participantId: user.id,
        mood: _mood ?? 'Okay',
        use: _use ?? 'No',
        context: _context ?? 'Home',
        goal: _goal ?? 'Partly',
      );
      if (!saved) {
        showNotice(context, 'Today’s morning survey is already complete.');
      }
    } else if (widget.kind == SurveyKind.location) {
      state.recordLocationVisit(
        participantId: user.id,
        placeId: widget.placeId!,
        present: !leftEarly,
        mood: _mood,
        intent: _intent,
        context: _context,
      );
    } else {
      state.recordHealthyVisit(
        participantId: user.id,
        placeId: widget.placeId!,
        mood: _mood ?? 'Okay',
      );
    }
    setState(() {
      _done = true;
      _leftEarly = leftEarly;
    });
  }
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({
    required this.heading,
    required this.body,
    required this.onContinue,
    this.continueLabel = 'Continue',
  });

  final String heading;
  final String body;
  final String continueLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Text(body, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 18),
        PrimaryButton(
          key: const Key('survey-continue'),
          label: continueLabel,
          onPressed: onContinue,
        ),
      ],
    );
  }
}

class _DonePane extends StatelessWidget {
  const _DonePane({
    required this.title,
    required this.body,
    required this.onClose,
    this.onMessage,
  });

  final String title;
  final String body;
  final VoidCallback onClose;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.verified, color: moss, size: 42),
        const SizedBox(height: 10),
        Text(title, key: const Key('survey-done'), style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(body, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 18),
        if (onMessage != null) ...[
          PrimaryButton(label: 'Message peer', onPressed: onMessage),
          const SizedBox(height: 8),
        ],
        PrimaryButton(label: 'Back home', onPressed: onClose),
      ],
    );
  }
}
