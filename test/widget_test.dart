// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:deep_work_app/ritual_edit.dart';
import 'package:deep_work_app/rituals_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockRitual extends Mock implements Ritual {}

class MockRitualStep extends Mock implements RitualStep {}

void main() {
  testWidgets('Checks the creation of a editing ritual.',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    var ritual = MockRitual();
    when(ritual.title).thenReturn("My mock ritual");
    var ritualStep = MockRitualStep();
    when(ritualStep.title).thenReturn("First Step");
    when(ritualStep.description).thenReturn("Why First Step is important.");
    when(ritual.getRitualSteps())
        .thenAnswer((_) => Future.value(List<RitualStep>.of([ritualStep])));
    Widget testWidget = new MediaQuery(
        data: new MediaQueryData(),
        child: new MaterialApp(home: RitualsEditPage(ritual: ritual)));
    await tester.pumpWidget(testWidget);
    expect(find.text("Ritual My mock ritual"), findsOneWidget);
    expect(find.text("Loading..."), findsOneWidget);
    await tester.pump();
    expect(find.text("Loading..."), findsNothing);
    expect(find.text("First Step"), findsOneWidget);
    expect(find.text("Why First Step is important."), findsOneWidget);
  });
}
