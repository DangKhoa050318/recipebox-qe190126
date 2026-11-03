import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _features = [
    (
      Icons.menu_book_outlined,
      'Save your recipes',
      'Keep a private collection of the recipes you cook or want to try.',
    ),
    (
      Icons.timer_outlined,
      'Sort by cooking time',
      'Quick dishes come first. Filter by meal category and difficulty.',
    ),
    (
      Icons.star_outline,
      'Mark your favorites',
      'Star the recipes you love and find them again in one tap.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('RecipeBox'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: scheme.onPrimary),
            onPressed: () => context.push('/login'),
            child: const Text('Login'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: Gap.sm),
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
              onPressed: () => context.push('/register'),
              child: const Text('Register'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.md),
          children: [
            const SizedBox(height: Gap.lg),
            Icon(Icons.restaurant_menu, size: 64, color: scheme.primary),
            const SizedBox(height: Gap.md),
            Text(
              'RecipeBox',
              textAlign: TextAlign.center,
              style: text.headlineLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Gap.sm),
            Text(
              'Your personal cookbook in your pocket. Save the recipes you '
              'cook or want to try, sort them by meal and difficulty, and '
              'keep your favorites one tap away.',
              textAlign: TextAlign.center,
              style: text.bodyLarge,
            ),
            const SizedBox(height: Gap.lg),
            for (final (icon, title, body) in _features) ...[
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Gap.md,
                    vertical: Gap.sm,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: Icon(icon),
                  ),
                  title: Text(title, style: text.titleMedium),
                  subtitle: Text(body),
                ),
              ),
              const SizedBox(height: Gap.sm),
            ],
          ],
        ),
      ),
    );
  }
}
