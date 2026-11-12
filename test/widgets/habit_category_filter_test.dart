import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'habits': jsonEncode([
        {
          'id': 'reading',
          'name': 'Read',
          'frequency': 'daily',
          'category': 'Study',
          'completedDates': [],
        },
        {
          'id': 'running',
          'name': 'Run',
          'frequency': 'daily',
          'category': 'Fitness',
          'completedDates': [],
        },
      ]),
    });
  });

  testWidgets('category filter shows matching habits and can reset',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HabitHomePage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Run'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Study'));
    await tester.pumpAndSettle();

    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Run'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();

    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Run'), findsOneWidget);
  });

  testWidgets('empty categories show a helpful message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HabitHomePage()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Health'));
    await tester.pumpAndSettle();

    expect(find.text('No habits in Health yet.'), findsOneWidget);
  });
}
