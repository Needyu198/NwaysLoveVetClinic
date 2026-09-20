import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/pet_owner/owner_shared_stores.dart';
import 'package:senior_project/pet_owner/pet_owner_home_page.dart';
import 'package:senior_project/pet_owner/pet_reminder_page.dart';

void main() {
  setUp(() {
    ReminderStore.instance.reset();
    for (final type in ReminderType.values) {
      ReminderStore.instance.addNew(
        title: '${type.label} reminder',
        type: type,
        dateTime: DateTime.now().add(Duration(days: type.index + 1)),
      );
    }
  });

  tearDown(ReminderStore.instance.reset);

  testWidgets('reminder page uses fixed-size supplied icons', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PetReminderPage()));
    await tester.pumpAndSettle();

    for (final type in ReminderType.values) {
      final mainIcon = find.byKey(ValueKey('reminder-${type.name}-main-icon'));
      final categoryIcon = find.byKey(
        ValueKey('reminder-${type.name}-category-icon'),
      );

      expect(tester.widget<SizedBox>(mainIcon).width, 38);
      expect(tester.widget<SizedBox>(mainIcon).height, 38);
      expect(tester.widget<SizedBox>(categoryIcon).width, 19);
      expect(tester.widget<SizedBox>(categoryIcon).height, 19);
    }
  });

  testWidgets('home reminders box uses fixed-size supplied icons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PetOwnerHomePage()));
    await tester.pumpAndSettle();

    for (final type in ReminderType.values) {
      final finder = find.byKey(ValueKey('home-${type.name}-reminder-icon'));
      expect(finder, findsOneWidget);
      expect(tester.widget<SizedBox>(finder).width, 30);
      expect(tester.widget<SizedBox>(finder).height, 30);
    }
  });
}
