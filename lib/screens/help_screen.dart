import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';
import '../widgets.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _subject = TextEditingController();
  final _body = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _call(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url on this device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final email = state.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Help')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const Text(
            'If you are in immediate danger, call emergency services. This prototype does not contact them for you.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          _CrisisCard(
            title: 'Emergency',
            detail: 'Call 911',
            onTap: () => _call('tel:911'),
          ),
          _CrisisCard(
            title: 'Suicide & Crisis Lifeline',
            detail: 'Call or text 988',
            onTap: () => _call('tel:988'),
          ),
          _CrisisCard(
            title: 'SAMHSA National Helpline',
            detail: '1-800-662-HELP (4357)',
            onTap: () => _call('tel:18006624357'),
          ),
          const SizedBox(height: 18),
          Text('Contact the study team', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          const Text(
            'Let us know if you have any questions. Messages stay in this session for the admin inbox.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subject,
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _body,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Body'),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: _sent ? 'Sent' : 'Send',
            onPressed: _sent
                ? null
                : () {
                    if (_subject.text.trim().isEmpty || _body.text.trim().isEmpty) {
                      showNotice(context, 'Add a subject and a message.');
                      return;
                    }
                    state.sendContact(
                      fromEmail: email,
                      subject: _subject.text,
                      body: _body.text,
                    );
                    setState(() => _sent = true);
                  },
          ),
        ],
      ),
    );
  }
}

class _CrisisCard extends StatelessWidget {
  const _CrisisCard({
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SoftCard(
        color: const Color(0xFFFFF6F1),
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              const Icon(Icons.phone_in_talk, color: clay),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(detail),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
