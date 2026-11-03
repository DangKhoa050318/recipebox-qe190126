import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../theme.dart';
import '../utils/validators.dart';
import 'common.dart';

/// Holds the values of the Add Recipe and Edit Recipe forms.
class RecipeFormData {
  RecipeFormData([Recipe? recipe])
      : name = TextEditingController(text: recipe?.name),
        cookTime = TextEditingController(text: recipe?.cookTime.toString()),
        servings = TextEditingController(text: recipe?.servings?.toString()),
        notes = TextEditingController(text: recipe?.notes),
        category = recipe == null || !kCategories.contains(recipe.category)
            ? null
            : recipe.category,
        difficulty =
            recipe == null || !kDifficulties.contains(recipe.difficulty)
                ? null
                : recipe.difficulty;

  final TextEditingController name;
  final TextEditingController cookTime;
  final TextEditingController servings;
  final TextEditingController notes;
  String? category;
  String? difficulty;

  /// Only call after the form validated.
  RecipeInput toInput() {
    final s = servings.text.trim();
    return RecipeInput(
      name: name.text,
      category: category!,
      difficulty: difficulty!,
      cookTime: int.parse(cookTime.text.trim()),
      servings: s.isEmpty ? null : int.parse(s),
      notes: notes.text,
    );
  }

  void clear() {
    name.clear();
    cookTime.clear();
    servings.clear();
    notes.clear();
    category = null;
    difficulty = null;
  }

  void dispose() {
    name.dispose();
    cookTime.dispose();
    servings.dispose();
    notes.dispose();
  }
}

/// The recipe fields shared by the Add Recipe form and the Detail edit mode.
/// Place inside a [Form]; rebuild the [Form] with a new key after
/// [RecipeFormData.clear] so the dropdowns reset too.
class RecipeFormFields extends StatelessWidget {
  const RecipeFormFields({super.key, required this.data});

  final RecipeFormData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: data.name,
          label: 'Name',
          validator: Validators.name,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: Gap.md),
        _ChoiceField(
          label: 'Category',
          emptyChoice: 'Choose category',
          options: kCategories,
          initialValue: data.category,
          validator: Validators.category,
          onChanged: (v) => data.category = v,
        ),
        const SizedBox(height: Gap.md),
        _ChoiceField(
          label: 'Difficulty',
          emptyChoice: 'Choose difficulty',
          options: kDifficulties,
          initialValue: data.difficulty,
          validator: Validators.difficulty,
          onChanged: (v) => data.difficulty = v,
        ),
        const SizedBox(height: Gap.md),
        AppTextField(
          controller: data.cookTime,
          label: 'Cook time (minutes)',
          validator: Validators.cookTime,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: Gap.md),
        AppTextField(
          controller: data.servings,
          label: 'Servings (1-20, optional)',
          validator: Validators.servings,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: Gap.md),
        AppTextField(
          controller: data.notes,
          label: 'Notes (optional)',
          validator: Validators.notes,
          keyboardType: TextInputType.multiline,
          maxLines: 4,
        ),
      ],
    );
  }
}

class _ChoiceField extends StatelessWidget {
  const _ChoiceField({
    required this.label,
    required this.emptyChoice,
    required this.options,
    required this.initialValue,
    required this.validator,
    required this.onChanged,
  });

  final String label;
  final String emptyChoice;
  final List<String> options;
  final String? initialValue;
  final FormFieldValidator<String?> validator;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: initialValue,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      hint: Text(emptyChoice),
      validator: validator,
      onChanged: onChanged,
      items: [
        DropdownMenuItem<String?>(value: null, child: Text(emptyChoice)),
        for (final o in options)
          DropdownMenuItem<String?>(value: o, child: Text(o)),
      ],
    );
  }
}
