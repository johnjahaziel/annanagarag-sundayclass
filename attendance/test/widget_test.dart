import 'package:attendance/features/homepage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping a class opens its detail screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Homepage()));

    await tester.tap(find.text('Beginner 1'));
    await tester.pumpAndSettle();

    expect(find.text('Class Detail'), findsOneWidget);
    expect(find.text('Beginner 1'), findsWidgets);
    expect(find.text('Students'), findsOneWidget);
  });
}
