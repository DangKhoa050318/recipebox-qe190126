import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

const List<String> kCategories = ['Breakfast', 'Lunch', 'Dinner', 'Dessert'];
const List<String> kDifficulties = ['Easy', 'Medium', 'Hard'];

/// A recipe as stored in the `recipes` collection.
class Recipe {
  const Recipe({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.difficulty,
    required this.cookTime,
    required this.servings,
    required this.favorite,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String category;
  final String difficulty;
  final int cookTime;
  final int? servings;
  final bool favorite;
  final String notes;
  final Timestamp? createdAt;

  factory Recipe.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Recipe(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      name: d['name'] as String? ?? '',
      category: d['category'] as String? ?? '',
      difficulty: d['difficulty'] as String? ?? '',
      cookTime: (d['cookTime'] as num?)?.toInt() ?? 0,
      servings: (d['servings'] as num?)?.toInt(),
      favorite: d['favorite'] == true,
      notes: d['notes'] as String? ?? '',
      createdAt: d['createdAt'] is Timestamp ? d['createdAt'] as Timestamp : null,
    );
  }

  /// Document id for a recipe: the same person + name (ignoring case and
  /// surrounding spaces) always maps to the same id, which is how the security
  /// rules refuse duplicates. Must match `recipeKey()` in firestore.rules.
  static String keyFor(String userId, String name) {
    final raw = '$userId|${name.trim().toLowerCase()}';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  /// Shortest cook time first, then by name (case-insensitive).
  static int compare(Recipe a, Recipe b) {
    final byTime = a.cookTime.compareTo(b.cookTime);
    if (byTime != 0) return byTime;
    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    if (byName != 0) return byName;
    return a.id.compareTo(b.id);
  }
}

/// The user-editable part of a recipe, as entered in the Add / Edit forms.
class RecipeInput {
  const RecipeInput({
    required this.name,
    required this.category,
    required this.difficulty,
    required this.cookTime,
    required this.servings,
    required this.notes,
  });

  final String name;
  final String category;
  final String difficulty;
  final int cookTime;
  final int? servings;
  final String notes;

  Map<String, dynamic> toMap() => {
        'name': name.trim(),
        'category': category,
        'difficulty': difficulty,
        'cookTime': cookTime,
        'servings': servings,
        'notes': notes.trim(),
      };
}
