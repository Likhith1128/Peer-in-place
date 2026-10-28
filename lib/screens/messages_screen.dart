import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({
    required this.participantId,
    required this.peerId,
    super.key,
  });

  final String participantId;
  final String peerId;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _body = TextEditingController();
  final _header = TextEditingController();
  bool _schedule = false;
  DateTime? _when;

  @override
  void dispose() {
    _body.dispose();
    _header.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final me = state.currentUser!;
    final participant = state.userById(widget.participantId);
    final peer = state.userById(widget.peerId);
    final thread = state.threadFor(widget.participantId);
    final canSchedule = me.role != UserRole.participant;
    return Scaffold(
      appBar: AppBar(
        title: Text(participant?.name ?? 'Messages'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  peer == null
                      ? 'Peer thread'
                      : 'With ${peer.name}. Messages show up for both people in this session.',
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 12),
                for (final message in thread)
                  _Bubble(
                    message: message,
                    mine: message.senderId == me.id,
                    now: state.now,
                  ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  if (canSchedule && _schedule) ...[
                    TextField(
                      controller: _header,
                      maxLength: 48,
                      decoration: const InputDecoration(
                        labelText: 'Header',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                          );
                          if (date == null || !context.mounted) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (time == null) return;
                          setState(() {
                            _when = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        },
                        child: Text(
                          _when == null
                              ? 'Pick a time'
                              : '${shortDate(_when!)} ${friendlyTime(_when!)}',
                        ),
                      ),
                    ),
                  ],
                  TextField(
                    key: const Key('message-field'),
                    controller: _body,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 240,
                    decoration: const InputDecoration(
                      hintText: 'Write a message',
                      counterText: '',
                    ),
                  ),
                  Row(
                    children: [
                      if (canSchedule)
                        TextButton(
                          onPressed: () => setState(() => _schedule = !_schedule),
                          child: Text(_schedule ? 'Send now' : 'Schedule'),
                        ),
                      const Spacer(),
                      FilledButton(
                        key: const Key('send-message'),
                        onPressed: () {
                          if (_body.text.trim().isEmpty) return;
                          if (_schedule && _when == null) {
                            showNotice(context, 'Pick a time for the scheduled message.');
                            return;
                          }
                          if ((_header.text).length > 48 || _body.text.length > 240) {
                            showNotice(
                              context,
                              'Keep the header under 48 characters and the body under 240.',
                            );
                            return;
                          }
                          state.sendMessage(
                            participantId: widget.participantId,
                            peerId: widget.peerId,
                            senderId: me.id,
                            senderRole: me.role,
                            body: _body.text,
                            header: _schedule ? _header.text : null,
                            scheduledFor: _schedule ? _when : null,
                          );
                          _body.clear();
                          _header.clear();
                          setState(() {
                            _schedule = false;
                            _when = null;
                          });
                        },
                        child: const Text('Send'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.now,
  });

  final ChatMessage message;
  final bool mine;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheduled = message.isScheduled(now);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: mine ? const Color(0x140E6B62) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.header != null)
              Text(
                message.header!,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            Text(message.body),
            const SizedBox(height: 4),
            Text(
              scheduled
                  ? 'Scheduled ${shortDate(message.scheduledFor!)} ${friendlyTime(message.scheduledFor!)}'
                  : friendlyTime(message.at),
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
