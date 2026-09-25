import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/pet_owner/appointment_booking_page.dart';
import 'package:senior_project/pet_owner/profile_flows.dart';

void main() {
  testWidgets('Book Appointment home visit uses the owner profile address', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(OwnerProfileStore.instance.reset);
    AppointmentStore.instance.clear();
    addTearDown(AppointmentStore.instance.clear);

    OwnerProfileStore.instance.update(
      OwnerProfileData(
        fullName: 'Mya Mya',
        dateOfBirth: DateTime(1995, 2, 10),
        gender: 'Female',
        phone: '09912345678',
        email: 'mya@example.com',
        address: 'No. 24, Thazin Street, Zabuthiri, Nay Pyi Taw',
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: AppointmentBookingPage(
          initialPetName: 'Max',
          initialServiceName: 'Home Visit',
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Dr. Min Khant'));
    await tester.pump();
    await tester.tap(find.text('Choose Date'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ChoiceChip).at(1));
    await tester.pump();
    await tester.tap(find.text('View Time Slots'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('appointment-time-12:00 PM')));
    await tester.pump();
    await tester.tap(find.text('Enter Appointment Details'));
    await tester.pump();

    final addressCard = find.byKey(const ValueKey('appointment-address'));
    expect(addressCard, findsOneWidget);
    expect(
      find.descendant(
        of: addressCard,
        matching: find.text('No. 24, Thazin Street, Zabuthiri, Nay Pyi Taw'),
      ),
      findsOneWidget,
    );

    OwnerProfileStore.instance.update(
      OwnerProfileData(
        fullName: 'Mya Mya',
        dateOfBirth: DateTime(1995, 2, 10),
        gender: 'Female',
        phone: '09912345678',
        email: 'mya@example.com',
        address: 'No. 88, Yaza Thingaha Road, Nay Pyi Taw',
      ),
    );
    await tester.pump();
    expect(
      find.descendant(
        of: addressCard,
        matching: find.text('No. 88, Yaza Thingaha Road, Nay Pyi Taw'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.enterText(
      find.byKey(const ValueKey('appointment-symptoms')),
      'Low appetite',
    );
    await tester.enterText(
      find.byKey(const ValueKey('appointment-reason')),
      'Home examination',
    );
    await tester.tap(find.text('Review Booking'));
    await tester.pump();
    expect(
      find.text('No. 88, Yaza Thingaha Road, Nay Pyi Taw'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
  });
}
