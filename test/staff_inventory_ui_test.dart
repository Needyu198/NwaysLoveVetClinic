import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/staff/staff_portal.dart';

void main() {
  const itemId = 'TEST-PHOTO-ITEM';

  tearDown(() {
    StaffOperationsStore.instance.inventory.removeWhere(
      (item) => item.id == itemId,
    );
    StaffOperationsStore.instance.notifyChanged();
  });

  testWidgets('inventory shows saved item photos and queue-style filters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    StaffOperationsStore.instance.addItem(
      InventoryItem(
        id: itemId,
        name: 'Photo Test Harness',
        category: 'Accessories',
        quantity: 5,
        reorderLevel: 2,
        unit: 'pcs',
        expiresOn: DateTime.now().add(const Duration(days: 365)),
        imageAsset:
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: StaffInventoryPage()));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('staff-inventory-category-filters')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('staff-inventory-category-All')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('staff-inventory-category-Pet Food')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('staff-inventory-stock-filters')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('staff-inventory-search')),
      itemId,
    );
    await tester.pumpAndSettle();

    final image = find.byKey(const ValueKey('inventory-image-$itemId'));
    expect(image, findsOneWidget);
    expect(
      find.descendant(of: image, matching: find.byType(Image)),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('inventory-card-$itemId')));
    await tester.pumpAndSettle();
    final detailImage = find.byKey(
      const ValueKey('inventory-detail-image-$itemId'),
    );
    expect(
      find.descendant(of: detailImage, matching: find.byType(Image)),
      findsOneWidget,
    );
  });
}
