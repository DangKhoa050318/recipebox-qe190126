import 'package:exam_app/models/recipe.dart';
import 'package:exam_app/state/recipe_store.dart';
import 'package:exam_app/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

Recipe _recipe(
  String name, {
  int cookTime = 30,
  String category = 'Lunch',
  bool favorite = false,
}) =>
    Recipe(
      id: name,
      userId: 'u',
      name: name,
      category: category,
      difficulty: 'Easy',
      cookTime: cookTime,
      servings: null,
      favorite: favorite,
      notes: '',
      createdAt: null,
    );

void main() {
  group('Recipe.keyFor', () {
    test('matches the hash computed by the security rules', () {
      // sha256("uid123|pho bo"), computed with Node's crypto.
      expect(
        Recipe.keyFor('uid123', '  PHO Bo '),
        'cb069450f30447cb20b15a16946890d5daa8f4edf1de961eb0b274d9730937b9',
      );
    });

    test('ignores case and surrounding spaces, differs per user', () {
      expect(Recipe.keyFor('u', 'Pho Bo'), Recipe.keyFor('u', ' pho bo '));
      expect(Recipe.keyFor('u', 'Pho Bo'), isNot(Recipe.keyFor('v', 'Pho Bo')));
    });
  });

  test('recipes sort by cook time, then by name ignoring case', () {
    final recipes = [
      _recipe('pancakes', cookTime: 20),
      _recipe('Omelette', cookTime: 10),
      _recipe('Brownies', cookTime: 45),
      _recipe('apple pie', cookTime: 20),
    ]..sort(Recipe.compare);
    expect(recipes.map((r) => r.name),
        ['Omelette', 'apple pie', 'pancakes', 'Brownies']);
  });

  test('RecipeSummary counts, total time and category order', () {
    final s = RecipeSummary.of([
      _recipe('a', category: 'Dessert', cookTime: 10, favorite: true),
      _recipe('b', category: 'Dinner', cookTime: 20),
      _recipe('c', category: 'Dessert', cookTime: 30),
      _recipe('d', category: 'Breakfast', cookTime: 5, favorite: true),
      _recipe('e', category: 'Dinner', cookTime: 15),
    ]);
    expect(s.total, 5);
    expect(s.favorites, 2);
    expect(s.totalTime, 80);
    // Dinner and Dessert tie at 2: Dinner comes first; then Breakfast.
    expect(s.byCategory.map((e) => '${e.key}:${e.value}'),
        ['Dinner:2', 'Dessert:2', 'Breakfast:1']);
    expect(RecipeSummary.of([]).byCategory, isEmpty);
  });

  group('Validators', () {
    test('auth fields', () {
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email('abc'), 'Please enter a valid email address');
      expect(Validators.email(' a@b.co '), isNull);
      expect(Validators.loginPassword(''), 'Password is required');
      expect(Validators.registerPassword('12345'),
          'Password must be at least 6 characters');
      expect(Validators.confirmPassword('', 'x'), 'Confirm password is required');
      expect(Validators.confirmPassword('y', 'x'), 'Passwords do not match');
    });

    test('recipe fields', () {
      expect(Validators.name('   '), 'Name is required');
      expect(Validators.name('n' * 81), 'Name must be at most 80 characters');
      expect(Validators.name('n' * 80), isNull);
      expect(Validators.category(null), 'Please choose a category');
      expect(Validators.difficulty(null), 'Please choose a difficulty');
      expect(Validators.cookTime(' '), 'Cook time is required');
      const ct = 'Cook time must be a whole number from 1 to 600';
      for (final bad in ['0', '601', '2.5', '-3', 'abc', '99999999999999999999']) {
        expect(Validators.cookTime(bad), ct, reason: bad);
      }
      expect(Validators.cookTime('1'), isNull);
      expect(Validators.cookTime('600'), isNull);
      expect(Validators.servings(''), isNull);
      const sv = 'Servings must be a whole number from 1 to 20';
      for (final bad in ['0', '21', '1.5', 'x']) {
        expect(Validators.servings(bad), sv, reason: bad);
      }
      expect(Validators.servings('20'), isNull);
      expect(Validators.notes('n' * 301), 'Notes must be at most 300 characters');
      expect(Validators.notes('n' * 300), isNull);
    });
  });
}
