class Recipe {
  final String title;
  final String description;
  final List<String> ingredients;
  final List<String> steps;
  final int servings;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final List<String> tags;

  Recipe({
    required this.title,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.servings,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.tags,
  });

  // Convert to Map for Hive storage
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'steps': steps,
      'servings': servings,
      'prepTimeMinutes': prepTimeMinutes,
      'cookTimeMinutes': cookTimeMinutes,
      'tags': tags,
    };
  }

  // Create Recipe from Map (from Hive)
  factory Recipe.fromMap(Map<dynamic, dynamic> map) {
    return Recipe(
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      ingredients: _convertListItems(map['ingredients']),
      steps: _convertListItems(map['steps']),
      servings: map['servings'] is int ? map['servings'] : 2,
      prepTimeMinutes: map['prepTimeMinutes'] is int ? map['prepTimeMinutes'] : 0,
      cookTimeMinutes: map['cookTimeMinutes'] is int ? map['cookTimeMinutes'] : 0,
      tags: _convertListItems(map['tags']),
    );
  }

  // Helper method to convert list items
  static List<String> _convertListItems(dynamic items) {
    if (items == null) return [];
    if (items is List) {
      return items.map((item) => item.toString()).toList();
    }
    return [];
  }

  // Total time in minutes
  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;

  // Format time as hours and minutes
  String formatTime(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $remainingMinutes min';
  }

  // Get formatted prep time
  String get prepTimeFormatted => formatTime(prepTimeMinutes);

  // Get formatted cook time
  String get cookTimeFormatted => formatTime(cookTimeMinutes);

  // Get formatted total time
  String get totalTimeFormatted => formatTime(totalTimeMinutes);

  // Create a copy of this recipe with updated fields
  Recipe copyWith({
    String? title,
    String? description,
    List<String>? ingredients,
    List<String>? steps,
    int? servings,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    List<String>? tags,
  }) {
    return Recipe(
      title: title ?? this.title,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      servings: servings ?? this.servings,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      tags: tags ?? this.tags,
    );
  }
}