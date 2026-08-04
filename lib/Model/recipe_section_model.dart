/// Represents a named group of ingredients (e.g. "For the sauce:").
/// [name] is null when there is a single unnamed group.
class IngredientSection {
  final String? name;
  final List<String> items;

  const IngredientSection({this.name, required this.items});

  Map<String, dynamic> toMap() => {
    'name': name,
    'items': List<String>.from(items),
  };

  factory IngredientSection.fromMap(Map<String, dynamic> m) =>
      IngredientSection(
        name: m['name'] as String?,
        items: (m['items'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );

  /// Creates a copy with optionally changed values.
  IngredientSection copyWith({String? name, List<String>? items}) {
    return IngredientSection(
      name: name ?? this.name,
      items: items ?? this.items,
    );
  }
}

/// Represents a named group of instruction steps (e.g. "Make the dough").
/// [name] is null when there is a single unnamed group.
class InstructionSection {
  final String? name;
  final List<String> steps;

  const InstructionSection({this.name, required this.steps});

  Map<String, dynamic> toMap() => {
    'name': name,
    'steps': List<String>.from(steps),
  };

  factory InstructionSection.fromMap(Map<String, dynamic> m) =>
      InstructionSection(
        name: m['name'] as String?,
        steps: (m['steps'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}
