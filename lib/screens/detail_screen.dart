import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../state/recipe_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/recipe_form_fields.dart';
import '../widgets/recipe_tile.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  // Changes when the name is edited, because the id depends on it.
  late String _id = widget.recipeId;
  Recipe? _lastRecipe;

  RecipeFormData? _form;
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _submitted = false;
  bool _saving = false;
  bool _leaving = false;
  String? _error;

  @override
  void dispose() {
    _form?.dispose();
    super.dispose();
  }

  void _startEdit(Recipe recipe) {
    setState(() {
      _form?.dispose();
      _form = RecipeFormData(recipe);
      _formKey = GlobalKey<FormState>();
      _submitted = false;
      _error = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _form?.dispose();
      _form = null;
      _error = null;
    });
  }

  Future<void> _save(Recipe recipe) async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final newId = await context
          .read<RecipeStore>()
          .updateRecipe(recipe, _form!.toInput());
      if (!mounted) return;
      setState(() {
        _id = newId;
        _form?.dispose();
        _form = null;
      });
    } on FirebaseException catch (e) {
      if (mounted) setState(() => _error = e.message ?? e.code);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleFavorite(Recipe recipe) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<RecipeStore>().toggleFavorite(recipe);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _delete(Recipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete recipe'),
        content: Text('Delete "${recipe.name}" from your recipes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              minimumSize: const Size(64, 40),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final store = context.read<RecipeStore>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _leaving = true);
    context.pop();
    // The list updates at once; if Firestore refuses, the recipe comes back.
    store.deleteRecipe(recipe).catchError((Object e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RecipeStore>();
    final current = store.byId(_id);
    if (current != null) _lastRecipe = current;
    final recipe = current ?? (_saving || _leaving ? _lastRecipe : null);

    if (recipe == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail')),
        body: Center(
          child: store.loading
              ? const CircularProgressIndicator()
              : const Text('Recipe not found'),
        ),
      );
    }

    final editing = _form != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit recipe' : 'Detail'),
        actions: [
          if (!editing)
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _startEdit(recipe),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.md),
          children: [editing ? _buildEdit(recipe) : _buildView(recipe)],
        ),
      ),
    );
  }

  Widget _buildView(Recipe recipe) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipe.name, style: text.headlineSmall),
                        const SizedBox(height: Gap.xs),
                        Text(
                          '${recipe.category} · ${recipe.cookTime} min',
                          style: text.titleSmall,
                        ),
                      ],
                    ),
                  ),
                  FavoriteButton(
                    favorite: recipe.favorite,
                    onPressed: () => _toggleFavorite(recipe),
                  ),
                ],
              ),
              const Divider(height: Gap.lg),
              _DetailRow(label: 'Name', value: recipe.name),
              _DetailRow(label: 'Category', value: recipe.category),
              _DetailRow(label: 'Difficulty', value: recipe.difficulty),
              _DetailRow(label: 'Cook time', value: '${recipe.cookTime} min'),
              _DetailRow(
                label: 'Servings',
                value: recipe.servings == null
                    ? 'Not set'
                    : '${recipe.servings}',
              ),
              _DetailRow(
                label: 'Favorite',
                value: recipe.favorite ? 'Yes' : 'No',
              ),
              _DetailRow(
                label: 'Notes',
                value: recipe.notes.isEmpty ? 'No notes' : recipe.notes,
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _startEdit(recipe),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(width: Gap.sm),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.error,
                  side: BorderSide(color: scheme.error),
                ),
                onPressed: () => _delete(recipe),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEdit(Recipe recipe) {
    return SectionCard(
      title: 'Edit recipe',
      child: Form(
        key: _formKey,
        autovalidateMode:
            _submitted ? AutovalidateMode.always : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RecipeFormFields(data: _form!),
            const SizedBox(height: Gap.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _cancelEdit,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: Gap.sm),
                Expanded(
                  child: PrimaryButton(
                    label: 'Save',
                    icon: Icons.save_outlined,
                    busy: _saving,
                    onPressed: () => _save(recipe),
                  ),
                ),
              ],
            ),
            if (_error != null) FormMessage(text: _error!),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: text.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: text.bodyLarge)),
        ],
      ),
    );
  }
}
