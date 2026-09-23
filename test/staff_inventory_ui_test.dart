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

    expect(find.byIcon(Icons.shopping_cart_outlined), findsNothing);

    expect(
      find.byKey(const ValueKey('staff-inventory-category-filters')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('staff-inventory-category-All')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('staff-inventory-category-Food')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('staff-inventory-category-Medicine')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('staff-inventory-category-Accessories')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('staff-inventory-category-Toys')),
      findsNothing,
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
    expect(find.byIcon(Icons.inventory_2_outlined), findsNothing);
    expect(find.byKey(const ValueKey('stock-in-$itemId')), findsOneWidget);
    expect(find.byKey(const ValueKey('stock-out-$itemId')), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-$itemId')), findsOneWidget);
    expect(find.byKey(const ValueKey('delete-$itemId')), findsOneWidget);
    expect(find.text('Restock'), findsNothing);
    expect(find.text('Archive item'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('delete-$itemId')));
    await tester.pumpAndSettle();
    expect(find.text('Delete item?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-delete-$itemId')));
    await tester.pumpAndSettle();
    expect(
      StaffOperationsStore.instance.inventory.any((item) => item.id == itemId),
      isFalse,
    );
  });

  testWidgets('add inventory only offers the shared product categories', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: StaffAddInventoryPage()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('generated-product-id')), findsOneWidget);
    expect(find.text('Automatic'), findsOneWidget);
    expect(find.text('Item Name'), findsOneWidget);
    expect(find.text('Subcategory'), findsOneWidget);
    expect(find.text('Pet Type'), findsOneWidget);
    expect(find.text('Brand'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    expect(find.text('Medicine'), findsOneWidget);
    expect(find.text('Accessories'), findsOneWidget);
    expect(find.text('Treats'), findsNothing);
    expect(find.text('Grooming'), findsNothing);
    expect(find.text('Toys'), findsNothing);
    expect(find.text('Vaccines'), findsNothing);
    expect(find.text('Medical Supplies'), findsNothing);
    await tester.tap(find.text('Medicine'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -520));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('product-image-slot-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('product-image-slot-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('product-image-slot-2')), findsOneWidget);
    expect(find.text('Main image'), findsOneWidget);
    expect(find.text('Package back'), findsOneWidget);
    expect(find.text('Product detail'), findsOneWidget);

    expect(find.widgetWithText(TextFormField, 'Stock'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Price'), findsOneWidget);
  });
}
