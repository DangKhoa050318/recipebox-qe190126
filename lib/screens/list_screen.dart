import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../services/auth_service.dart';
import '../state/recipe_store.dart';
import '../theme.dart';
import '../widgets/add_recipe_card.dart';
import '../widgets/common.dart';
import '../widgets/recipe_tile.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.text = context.read<RecipeStore>().search;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite(Recipe recipe) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<RecipeStore>().toggleFavorite(recipe);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final store = context.watch<RecipeStore>();
    final recipes = store.visibleRecipes;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RecipeBox'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Gap.sm),
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
              onPressed: () => context.read<AuthService>().signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: scheme.primaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: Gap.md),
            height: 44,
            child: Row(
              children: [
                Icon(Icons.account_circle, color: scheme.onPrimaryContainer),
                const SizedBox(width: Gap.sm),
                // Shrinks a long e-mail to fit instead of cutting it off.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      auth.user?.email ?? '',
                      style: TextStyle(color: scheme.onPrimaryContainer),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.md),
          children: [
            const AddRecipeCard(),
            const SizedBox(height: Gap.md),
            _FilterCard(searchController: _search),
            const SizedBox(height: Gap.md),
            _SummaryCard(summary: store.summary),
            const SizedBox(height: Gap.md),
            Text('Your recipes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Gap.sm),
            if (store.loading)
              const Padding(
                padding: EdgeInsets.all(Gap.lg),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (store.loadError != null)
              FormMessage(text: store.loadError!)
            else if (recipes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: Gap.lg),
                child: Text('No recipes found', textAlign: TextAlign.center),
              )
            else
              for (final recipe in recipes) ...[
                RecipeTile(
                  key: ValueKey(recipe.id),
                  recipe: recipe,
                  onOpen: () {
                    // Keep the keyboard closed when coming back from Detail.
                    FocusScope.of(context).unfocus();
                    context.push('/recipes/${recipe.id}');
                  },
                  onToggleFavorite: () => _toggleFavorite(recipe),
                ),
                const SizedBox(height: Gap.sm),
              ],
          ],
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({required this.searchController});

  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RecipeStore>();
    return SectionCard(
      title: 'Filter and search',
      trailing: TextButton.icon(
        onPressed: () {
          searchController.clear();
          store.clearFilters();
        },
        icon: const Icon(Icons.clear_all),
        label: const Text('Clear'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: searchController,
            label: 'Search name or notes',
            prefixIcon: Icons.search,
            textInputAction: TextInputAction.search,
            onChanged: store.setSearch,
          ),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  label: 'Category',
                  value: store.categoryFilter,
                  options: kCategories,
                  onChanged: store.setCategoryFilter,
                ),
              ),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: _FilterDropdown(
                  label: 'Difficulty',
                  value: store.difficultyFilter,
                  options: kDifficulties,
                  onChanged: store.setDifficultyFilter,
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Favorites only'),
            value: store.favoritesOnly,
            onChanged: store.setFavoritesOnly,
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          isDense: true,
          onChanged: onChanged,
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('All')),
            for (final o in options)
              DropdownMenuItem<String?>(value: o, child: Text(o)),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final RecipeSummary summary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SectionCard(
      title: 'Summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: Gap.lg,
            runSpacing: Gap.xs,
            children: [
              Text('Recipes: ${summary.total}', style: text.titleSmall),
              Text('Favorites: ${summary.favorites}', style: text.titleSmall),
              Text('Total time: ${summary.totalTime} min', style: text.titleSmall),
            ],
          ),
          if (summary.byCategory.isNotEmpty) ...[
            const Divider(height: Gap.lg),
            for (final row in summary.byCategory)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text(row.key)),
                    Text('${row.value}', style: text.titleSmall),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
