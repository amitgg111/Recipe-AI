import 'package:cloud_firestore/cloud_firestore.dart';

class   MealPlanItem {
  final String id;
  final String date; // Format: "yyyy-MM-dd"
  final String mealType; // "Breakfast", "Lunch", "Dinner", "Snack"
  final String recipeId;
  final String recipeTitle;
  final String? recipeImageUrl;

  MealPlanItem({
    required this.id,
    required this.date,
    required this.mealType,
    required this.recipeId,
    required this.recipeTitle,
    this.recipeImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'mealType': mealType,
      'recipeId': recipeId,
      'recipeTitle': recipeTitle,
      'recipeImageUrl': recipeImageUrl,
    };
  }

  factory MealPlanItem.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MealPlanItem(
      id: doc.id,
      date: data['date'] ?? '',
      mealType: data['mealType'] ?? '',
      recipeId: data['recipeId'] ?? '',
      recipeTitle: data['recipeTitle'] ?? '',
      recipeImageUrl: data['recipeImageUrl'],
    );
  }
}
