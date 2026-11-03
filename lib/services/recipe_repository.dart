import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/recipe.dart';

/// All reads and writes of the `recipes` collection.
class RecipeRepository {
  RecipeRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _recipes =>
      _db.collection('recipes');

  Stream<List<Recipe>> watchRecipes(String userId) => _recipes
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snap) =>
          snap.docs.map(Recipe.fromDoc).toList()..sort(Recipe.compare));

  /// Saves a new recipe. Runs as a transaction so nothing shows up in the list
  /// until Firestore has accepted it (a refused duplicate never flickers in).
  Future<void> add(String userId, RecipeInput input) async {
    final id = Recipe.keyFor(userId, input.name);
    final ref = _recipes.doc(id);
    await _db.runTransaction((tx) async {
      tx.set(ref, {
        ...input.toMap(),
        'id': id,
        'userId': userId,
        'favorite': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Updates a recipe and returns its (possibly new) id. Changing the name
  /// changes the document id, so the recipe is moved to the new id.
  Future<String> update(Recipe recipe, RecipeInput input) async {
    final newId = Recipe.keyFor(recipe.userId, input.name);
    if (newId == recipe.id) {
      await _recipes.doc(recipe.id).update(input.toMap());
      return recipe.id;
    }
    await _db.runTransaction((tx) async {
      tx.delete(_recipes.doc(recipe.id));
      tx.set(_recipes.doc(newId), {
        ...input.toMap(),
        'id': newId,
        'userId': recipe.userId,
        'favorite': recipe.favorite,
        'createdAt': recipe.createdAt ?? FieldValue.serverTimestamp(),
      });
    });
    return newId;
  }

  Future<void> setFavorite(Recipe recipe, bool favorite) =>
      _recipes.doc(recipe.id).update({'favorite': favorite});

  Future<void> delete(Recipe recipe) => _recipes.doc(recipe.id).delete();
}
