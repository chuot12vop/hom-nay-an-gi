import 'dart:convert';

class SavedFilters {
  const SavedFilters({
    required this.mealId,
    required this.maxPriceVnd,
    required this.allergicIngredientIds,
  });

  final int? mealId;
  final int maxPriceVnd;
  final List<int> allergicIngredientIds;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mealId': mealId,
      'maxPriceVnd': maxPriceVnd,
      'allergicIngredientIds': allergicIngredientIds,
    };
  }

  factory SavedFilters.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawIngredientIds =
        (json['allergicIngredientIds'] as List<dynamic>? ?? <dynamic>[]);

    return SavedFilters(
      mealId: json['mealId'] as int?,
      maxPriceVnd: (json['maxPriceVnd'] as num?)?.toInt() ?? 0,
      allergicIngredientIds: rawIngredientIds
          .map((dynamic value) => (value as num).toInt())
          .toList(),
    );
  }

  String toPrettyString() {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }
}
