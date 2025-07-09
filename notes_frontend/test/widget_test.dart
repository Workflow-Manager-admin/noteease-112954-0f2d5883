import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_frontend/main.dart';

void main() {
  testWidgets('Shows notes list screen and app bar title', (WidgetTester tester) async {
    await tester.pumpWidget(const NotesApp());

    expect(find.text('My Notes'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Should show a note from demo seed
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Minimal'), findsOneWidget);
  });

  testWidgets('FAB creates a new note flow', (WidgetTester tester) async {
    await tester.pumpWidget(const NotesApp());

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('New Note'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
  });
}
