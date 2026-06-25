import 'package:flutter_test/flutter_test.dart';

import 'package:recipe_ai/main.dart';

void main() {
  testWidgets('RecipeNest splash smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('RecipeNest'), findsOneWidget);
    expect(find.text('Cook Smarter With AI'), findsOneWidget);
  });
}
