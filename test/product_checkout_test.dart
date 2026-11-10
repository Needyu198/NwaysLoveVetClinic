import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/data/clinic_api.dart';
import 'package:senior_project/pet_owner/pet_products_page.dart';

void main() {
  setUp(() {
    ClinicApi.instance.token = null;
    ProductCartStore.instance.clear();
    ProductOrderStore.instance.clear();
  });

  tearDown(() {
    ProductCartStore.instance.clear();
    ProductOrderStore.instance.clear();
  });

  testWidgets('owner completes cart and pay-at-clinic checkout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ProductDetailsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('product-buy-now')));
    await tester.pumpAndSettle();
    expect(find.text('Shopping Cart'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cart-quantity-Dog Food 01')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('cart-plus-Dog Food 01')));
    await tester.pump();
    expect(find.text('2'), findsWidgets);
    expect(find.text('8,000 MMK'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('proceed-to-checkout')));
    await tester.pumpAndSettle();
    expect(find.text('Pay at clinic'), findsWidgets);
    expect(find.text('MMQR'), findsOneWidget);
    expect(find.text('Clinic pickup'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('place-product-order')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('product-order-confirmation')),
      findsOneWidget,
    );
    expect(find.text('Order Reserved'), findsOneWidget);
    expect(ProductOrderStore.instance.orders.single.total, 8000);
    expect(ProductCartStore.instance.isEmpty, isTrue);
    expect(tester.takeException(), isNull);
  });
}
