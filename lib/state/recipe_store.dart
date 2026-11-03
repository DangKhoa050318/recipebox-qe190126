import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/recipe.dart';
import '../services/auth_service.dart';
import '../services/recipe_repository.dart';

/// Counts describing the recipes currently shown.
class RecipeSummary {
  const RecipeSummary(this.total, this.favorites, this.totalTime, this.byCategory);

  final int total;
  final int favorites;
  final int totalTime;

  /// One entry per category that appears, most recipes first; ties follow
  /// the order Breakfast, Lunch, Dinner, Dessert.
  final List<MapEntry<String, int>> byCategory;

  factory RecipeSummary.of(List<Recipe> recipes) {
    final counts = {for (final c in kCategories) c: 0};
    var totalTime = 0;
    for (final r in recipes) {
      totalTime += r.cookTime;
      if (counts.containsKey(r.category)) {
        counts[r.category] = counts[r.category]! + 1;
      }
    }
    final rows = counts.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return kCategories.indexOf(a.key).compareTo(kCategories.indexOf(b.key));
      });
    return RecipeSummary(
      recipes.length,
      recipes.where((r) => r.favorite).length,
      totalTime,
      rows,
    );
  }
}

/// The logged-in user's recipes plus the List screen's filters, shared by the
/// List and Detail screens.
class RecipeStore extends ChangeNotifier {
  RecipeStore(this._auth, this._repo) {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  final AuthService _auth;
  final RecipeRepository _repo;

  StreamSubscription<List<Recipe>>? _sub;
  String? _userId;
  List<Recipe> _recipes = const [];
  bool _loading = false;
  String? _loadError;

  String? _category;
  String? _difficulty;
  bool _favoritesOnly = false;
  String _search = '';

  bool get loading => _loading;
  String? get loadError => _loadError;
  String? get categoryFilter => _category;
  String? get difficultyFilter => _difficulty;
  bool get favoritesOnly => _favoritesOnly;
  String get search => _search;

  List<Recipe> get visibleRecipes {
    final query = _search.trim().toLowerCase();
    return _recipes.where((r) {
      if (_category != null && r.category != _category) return false;
      if (_difficulty != null && r.difficulty != _difficulty) return false;
      if (_favoritesOnly && !r.favorite) return false;
      if (query.isNotEmpty &&
          !r.name.toLowerCase().contains(query) &&
          !r.notes.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  RecipeSummary get summary => RecipeSummary.of(visibleRecipes);

  Recipe? byId(String id) {
    for (final r in _recipes) {
      if (r.id == id) return r;
    }
    return null;
  }

  void setCategoryFilter(String? category) {
    _category = category;
    notifyListeners();
  }

  void setDifficultyFilter(String? difficulty) {
    _difficulty = difficulty;
    notifyListeners();
  }

  void setFavoritesOnly(bool value) {
    _favoritesOnly = value;
    notifyListeners();
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void clearFilters() {
    _resetFilters();
    notifyListeners();
  }

  Future<void> addRecipe(RecipeInput input) => _repo.add(_requireUser(), input);

  Future<String> updateRecipe(Recipe recipe, RecipeInput input) =>
      _repo.update(recipe, input);

  Future<void> toggleFavorite(Recipe recipe) =>
      _repo.setFavorite(recipe, !recipe.favorite);

  Future<void> deleteRecipe(Recipe recipe) => _repo.delete(recipe);

  String _requireUser() {
    final id = _userId;
    if (id == null) throw StateError('Not logged in');
    return id;
  }

  void _resetFilters() {
    _category = null;
    _difficulty = null;
    _favoritesOnly = false;
    _search = '';
  }

  void _onAuthChanged() {
    final userId = _auth.user?.uid;
    if (userId == _userId) return;
    _userId = userId;
    _sub?.cancel();
    _sub = null;
    _recipes = const [];
    _loadError = null;
    _resetFilters();
    _loading = userId != null;
    if (userId != null) {
      _sub = _repo.watchRecipes(userId).listen(
        (recipes) {
          _recipes = recipes;
          _loading = false;
          _loadError = null;
          notifyListeners();
        },
        onError: (Object e) {
          _loading = false;
          _loadError = e.toString();
          notifyListeners();
        },
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _sub?.cancel();
    super.dispose();
  }
}
