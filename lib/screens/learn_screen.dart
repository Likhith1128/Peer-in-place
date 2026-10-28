import 'package:flutter/material.dart';

import '../content.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final user = state.currentUser!;
    final saved = articles.where((article) => state.isSaved(user.id, article.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Learn')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Text(
            'Resource directory',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Self-guided notes on substance use, mood, context, goals, and supportive places. Save any of them for later.',
            style: TextStyle(color: muted),
          ),
          if (saved.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Saved for later', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final article in saved) _ArticleTile(article: article, userId: user.id),
          ],
          const SizedBox(height: 14),
          for (final article in articles) _ArticleTile(article: article, userId: user.id),
        ],
      ),
    );
  }
}

class _ArticleTile extends StatelessWidget {
  const _ArticleTile({required this.article, required this.userId});

  final ResourceArticle article;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SoftCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          title: Text(article.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(article.subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ArticleScreen(article: article, userId: userId),
            ),
          ),
        ),
      ),
    );
  }
}

class ArticleScreen extends StatelessWidget {
  const ArticleScreen({required this.article, required this.userId, super.key});

  final ResourceArticle article;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final saved = state.isSaved(userId, article.id);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource'),
        actions: [
          IconButton(
            tooltip: saved ? 'Remove saved' : 'Save for later',
            onPressed: () => state.toggleSaved(userId, article.id),
            icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(article.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(article.subtitle, style: const TextStyle(color: muted, fontSize: 16)),
          const SizedBox(height: 16),
          for (final paragraph in article.paragraphs) ...[
            Text(paragraph, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
          ],
          PrimaryButton(
            label: saved ? 'Saved for later' : 'Save for later',
            icon: Icons.bookmark_border,
            onPressed: () => state.toggleSaved(userId, article.id),
          ),
        ],
      ),
    );
  }
}
