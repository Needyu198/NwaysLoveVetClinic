import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/data/clinic_api.dart';
import 'package:senior_project/pet_owner/pet_products_page.dart';
import 'package:senior_project/staff/staff_portal.dart';

const _pixel =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

void main() {
  test('product fields and three images survive inventory serialization', () {
    final item = InventoryItem(
      id: 'PRD-TEST',
      name: 'Adult Dog Food',
      category: 'Food',
      subcategory: 'Dog Food',
      petType: 'Dog',
      brand: 'Royal Canin',
      description: 'Complete dry food.',
      quantity: 5,
      reorderLevel: 1,
      unit: 'pcs',
      sellingPrice: 850,
      expiresOn: DateTime(2030),
      imageAsset: _pixel,
      productImages: const [_pixel, _pixel, _pixel],
    );

    final restored = InventoryItem.fromDb(item.toDb());
    expect(restored.id, 'PRD-TEST');
    expect(restored.subcategory, 'Dog Food');
    expect(restored.petType, 'Dog');
    expect(restored.brand, 'Royal Canin');
    expect(restored.quantity, 5);
    expect(restored.productImages, hasLength(3));
  });

  testWidgets('pet owner catalog reads products created by staff', (
    tester,
  ) async {
    const id = 'PRD-SHARED-CATALOG-TEST';
    final previousToken = ClinicApi.instance.token;
    ClinicApi.instance.token = 'widget-test-token';
    StaffOperationsStore.instance.addItem(
      InventoryItem(
        id: id,
        name: 'Shared Royal Canin Product',
        category: 'Food',
        subcategory: 'Dog Food',
        petType: 'Dog',
        brand: 'Royal Canin',
        description: 'Complete dry food.',
        quantity: 5,
        reorderLevel: 1,
        unit: 'pcs',
        sellingPrice: 850,
        expiresOn: DateTime(2030),
        imageAsset: _pixel,
        productImages: const [_pixel, _pixel, _pixel],
      ),
    );
    addTearDown(() {
      ClinicApi.instance.token = previousToken;
      StaffOperationsStore.instance.inventory.removeWhere(
        (item) => item.id == id,
      );
      StaffOperationsStore.instance.notifyChanged();
    });

    await tester.pumpWidget(const MaterialApp(home: PetProductsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Product Options'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('product-category-all-icon')),
      findsOneWidget,
    );
    expect(find.text('Recommended Products'), findsNothing);
    expect(find.byKey(const ValueKey('pet-type-filters')), findsNothing);
    expect(
      find.byKey(const ValueKey('product-subcategory-filters')),
      findsNothing,
    );
    await tester.enterText(
      find.byKey(const ValueKey('pet-products-search')),
      'Shared Royal Canin Product',
    );
    await tester.pumpAndSettle();
    expect(find.text('Shared Royal Canin Product'), findsWidgets);
  });

  testWidgets('pet and subcategory filter bars are not shown', (tester) async {
    final previousToken = ClinicApi.instance.token;
    ClinicApi.instance.token = null;
    addTearDown(() => ClinicApi.instance.token = previousToken);

    await tester.pumpWidget(const MaterialApp(home: PetProductsPage()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pet-type-filters')), findsNothing);
    expect(
      find.byKey(const ValueKey('product-subcategory-filters')),
      findsNothing,
    );
    expect(find.text('Dog Food 01'), findsOneWidget);
    expect(find.text('Cat Food 01'), findsOneWidget);
  });

  testWidgets('pet owner can swipe through all three product photos', (
    tester,
  ) async {
    const product = Product(
      name: 'Adult Dog Food',
      category: 'Food',
      subcategory: 'Dog Food',
      brand: 'Royal Canin',
      price: 850,
      description: 'Complete dry food.',
      petType: 'Dog',
      weight: 'pcs',
      color: Colors.amber,
      icon: Icons.pets,
      imageUrls: [_pixel, _pixel, _pixel],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                settings: const RouteSettings(arguments: product),
                builder: (_) => const ProductDetailsPage(),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('product-image-gallery')), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    await tester.fling(
      find.byKey(const ValueKey('product-image-gallery')),
      const Offset(-500, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
    expect(find.byKey(const ValueKey('product-detail-price')), findsOneWidget);
    expect(find.byKey(const ValueKey('product-detail-stock')), findsNothing);
    expect(find.byKey(const ValueKey('product-detail-facts')), findsOneWidget);
    expect(find.byKey(const ValueKey('product-image-dot-0')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('product-image-thumbnails')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('product-detail-description')),
      findsOneWidget,
    );
    expect(find.text('More for You'), findsOneWidget);
    expect(find.text('Collection You May Love'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('open-product-photo-1')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('full-screen-product-gallery')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('zoomable-product-photo-1')),
      findsOneWidget,
    );
  });
}
