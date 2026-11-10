import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import '../data/clinic_api.dart';
import '../data/database_sync.dart';
import '../staff/staff_portal.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'pet_owner_clinic_page.dart';
import 'pet_owner_home_page.dart';
import 'pet_owner_nav_bar.dart';
import 'pet_owner_profile_page.dart';
import 'pet_owner_page_header.dart';
import 'pet_product_styles.dart';
import 'profile_flows.dart';

/// Formats an integer amount as "1,015 MMK".
String formatMmk(int amount) {
  final s = amount.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '${buf.toString()} MMK';
}

class CartLine {
  CartLine({required this.product, this.quantity = 1});
  final Product product;
  int quantity;
  int get total => product.price * quantity;
}

class ProductCartStore extends ChangeNotifier {
  ProductCartStore._();
  static final instance = ProductCartStore._();
  final Map<String, CartLine> _lines = {};

  String _key(Product product) =>
      product.inventoryId.isEmpty ? product.name : product.inventoryId;

  List<CartLine> get lines => List.unmodifiable(_lines.values);
  int get itemCount =>
      _lines.values.fold(0, (sum, line) => sum + line.quantity);
  int get subtotal => _lines.values.fold(0, (sum, line) => sum + line.total);
  bool get isEmpty => _lines.isEmpty;

  bool add(Product product, {int quantity = 1}) {
    if (quantity <= 0 || product.stock <= 0) return false;
    final key = _key(product);
    final next = (_lines[key]?.quantity ?? 0) + quantity;
    if (next > product.stock) return false;
    _lines.putIfAbsent(key, () => CartLine(product: product)).quantity = next;
    notifyListeners();
    return true;
  }

  bool setQuantity(CartLine line, int quantity) {
    if (quantity <= 0) {
      _lines.remove(_key(line.product));
      notifyListeners();
      return true;
    }
    if (quantity > line.product.stock) return false;
    line.quantity = quantity;
    notifyListeners();
    return true;
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }
}

class ProductOrderLine {
  const ProductOrderLine({
    required this.inventoryId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
  });

  factory ProductOrderLine.fromDb(Map<String, dynamic> value) =>
      ProductOrderLine(
        inventoryId: value['inventoryId'] as String? ?? '',
        name: value['name'] as String? ?? '',
        unitPrice: value['unitPrice'] as int? ?? 0,
        quantity: value['quantity'] as int? ?? 0,
      );

  Map<String, dynamic> toDb() => {
    'inventoryId': inventoryId,
    'name': name,
    'unitPrice': unitPrice,
    'quantity': quantity,
  };

  final String inventoryId;
  final String name;
  final int unitPrice;
  final int quantity;
}

class ProductOrder {
  ProductOrder({
    required this.id,
    required this.createdAt,
    required this.items,
    required this.total,
    required this.ownerName,
    required this.ownerPhone,
    this.fulfillment = 'Clinic pickup',
    this.paymentTiming = 'Pay at clinic',
    this.paymentMethod = 'Pay at clinic',
    this.paymentId = '',
    this.paymentStatus = '',
    this.mmqr = const {},
    this.paymentAuditTrail = const [],
    this.receipt = const {},
    this.status = 'Reserved',
  });

  factory ProductOrder.fromDb(Map<String, dynamic> value) => ProductOrder(
    id: value['id'] as String,
    createdAt: DateTime.parse(value['createdAt'] as String),
    items: (value['items'] as List? ?? const [])
        .map(
          (item) =>
              ProductOrderLine.fromDb(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    total: value['total'] as int? ?? 0,
    ownerName: value['ownerName'] as String? ?? '',
    ownerPhone: value['ownerPhone'] as String? ?? '',
    fulfillment: value['fulfillment'] as String? ?? 'Clinic pickup',
    paymentTiming: value['paymentTiming'] as String? ?? 'Pay at clinic',
    paymentMethod: value['paymentMethod'] as String? ?? 'Pay at clinic',
    paymentId: value['paymentId'] as String? ?? '',
    paymentStatus: value['paymentStatus'] as String? ?? '',
    mmqr: Map<String, dynamic>.from(
      value['mmqr'] as Map? ?? const <String, dynamic>{},
    ),
    paymentAuditTrail: (value['paymentAuditTrail'] as List? ?? const [])
        .whereType<Map>()
        .map((event) => Map<String, dynamic>.from(event))
        .toList(),
    receipt: Map<String, dynamic>.from(
      value['receipt'] as Map? ?? const <String, dynamic>{},
    ),
    status: value['status'] as String? ?? 'Reserved',
  );

  Map<String, dynamic> toDb() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'items': items.map((item) => item.toDb()).toList(),
    'total': total,
    'ownerName': ownerName,
    'ownerPhone': ownerPhone,
    'fulfillment': fulfillment,
    'paymentTiming': paymentTiming,
    'paymentMethod': paymentMethod,
    if (paymentId.isNotEmpty) 'paymentId': paymentId,
    if (paymentStatus.isNotEmpty) 'paymentStatus': paymentStatus,
    if (mmqr.isNotEmpty) 'mmqr': mmqr,
    if (paymentAuditTrail.isNotEmpty) 'paymentAuditTrail': paymentAuditTrail,
    if (receipt.isNotEmpty) 'receipt': receipt,
    'status': status,
  };

  final String id;
  final DateTime createdAt;
  final List<ProductOrderLine> items;
  final int total;
  final String ownerName;
  final String ownerPhone;
  final String fulfillment;
  final String paymentTiming;
  final String paymentMethod;
  final String paymentId;
  final String paymentStatus;
  final Map<String, dynamic> mmqr;
  final List<Map<String, dynamic>> paymentAuditTrail;
  final Map<String, dynamic> receipt;
  String status;
}

class ProductOrderStore extends ChangeNotifier {
  ProductOrderStore._();
  static final instance = ProductOrderStore._();
  final List<ProductOrder> _orders = [];

  List<ProductOrder> get orders => List.unmodifiable(_orders.reversed);

  void connectDatabase() => DatabaseSync.instance.bind(
    'product_orders',
    this,
    () => {for (final order in _orders) order.id: order.toDb()},
    (rows) => _orders
      ..clear()
      ..addAll(rows.values.map(ProductOrder.fromDb)),
  );

  void add(ProductOrder order) {
    _orders.add(order);
    notifyListeners();
  }

  void remove(ProductOrder order) {
    _orders.remove(order);
    notifyListeners();
  }

  @visibleForTesting
  void clear() {
    _orders.clear();
    notifyListeners();
  }
}

class PetProductsPage extends StatefulWidget {
  const PetProductsPage({super.key});

  static const String routeName = '/pet-products';

  @override
  State<PetProductsPage> createState() => _PetProductsPageState();
}

class _PetProductsPageState extends State<PetProductsPage> {
  String _category = 'All Product';
  String _query = '';
  String _sort = 'Popular';

  @override
  void initState() {
    super.initState();
    StaffOperationsStore.instance.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    StaffOperationsStore.instance.removeListener(_refresh);
    super.dispose();
  }

  List<Product> get _visibleProducts {
    final lowered = _query.toLowerCase();
    final filtered = products.where((product) {
      final categoryMatch =
          _category == 'All Product' || product.category == _category;
      final queryMatch =
          lowered.isEmpty ||
          product.name.toLowerCase().contains(lowered) ||
          product.brand.toLowerCase().contains(lowered) ||
          product.subcategory.toLowerCase().contains(lowered) ||
          product.petType.toLowerCase().contains(lowered);
      return categoryMatch && queryMatch;
    }).toList();

    switch (_sort) {
      case 'Price Low':
        filtered.sort((a, b) => a.price.compareTo(b.price));
      case 'Price High':
        filtered.sort((a, b) => b.price.compareTo(a.price));
      case 'Newest':
        // Inventory records already arrive in clinic-defined display order.
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleProducts;
    return Scaffold(
      backgroundColor: ProductStyles.background,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                PetOwnerPageHeader(
                  key: const ValueKey('pet-products-header'),
                  title: 'Products',
                  showBackButton: false,
                  logoKey: const ValueKey('pet-products-logo'),
                  onLogoTap: () => Navigator.of(
                    context,
                  ).pushReplacementNamed(PetOwnerHomePage.routeName),
                  actions: const [_ProductCartButton()],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                  child: _SearchHeader(
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Product Options',
                      key: const ValueKey('product-options-title'),
                      style: ProductStyles.sectionTitle,
                    ),
                  ),
                ),
                _CategoryIconStrip(
                  selected: _category,
                  onChanged: (value) => setState(() => _category = value),
                ),
                _SortBar(
                  sort: _sort,
                  count: visible.length,
                  onSortTap: _openSortSheet,
                ),
                Expanded(
                  child: visible.isEmpty
                      ? const _EmptyProducts()
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 118),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.60,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                              ),
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final product = visible[index];
                            return _ProductCard(
                              product: product,
                              onTap: () => Navigator.of(context).pushNamed(
                                ProductDetailsPage.routeName,
                                arguments: product,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: PetOwnerNavBar(
              selectedItem: PetOwnerNavItem.shop,
              onPetsTap: () {
                navigatePetOwnerTab(
                  context,
                  from: PetOwnerNavItem.shop,
                  to: PetOwnerNavItem.pets,
                  routeName: PetOwnerHomePage.routeName,
                  builder: (_) => const PetOwnerHomePage(),
                );
              },
              onAppointmentsTap: () {
                navigatePetOwnerTab(
                  context,
                  from: PetOwnerNavItem.shop,
                  to: PetOwnerNavItem.appointments,
                  routeName: PetOwnerClinicPage.routeName,
                  builder: (_) => const PetOwnerClinicPage(),
                );
              },
              onProfileTap: () {
                navigatePetOwnerTab(
                  context,
                  from: PetOwnerNavItem.shop,
                  to: PetOwnerNavItem.profile,
                  routeName: PetOwnerProfilePage.routeName,
                  builder: (_) => const PetOwnerProfilePage(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sort by', style: ProductStyles.sectionTitle),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ['Popular', 'Newest', 'Price Low', 'Price High']
                    .map(
                      (sort) => ChoiceChip(
                        label: Text(sort),
                        selected: _sort == sort,
                        selectedColor: ProductStyles.mint,
                        onSelected: (_) {
                          setState(() => _sort = sort);
                          Navigator.of(context).pop();
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Product detail page
// ---------------------------------------------------------------------------

class ProductDetailsPage extends StatelessWidget {
  const ProductDetailsPage({super.key});

  static const String routeName = '/product-details';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Product && products.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No products available.')),
      );
    }
    final product = args is Product ? args : products.first;
    final moreForYou = _recommendationsFor(
      product,
      (candidate) =>
          candidate.petType == product.petType ||
          candidate.petType == 'All Pets',
    );
    final collectionYouMayLove = _recommendationsFor(
      product,
      (candidate) =>
          candidate.category == product.category ||
          candidate.subcategory == product.subcategory,
    );
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: ProductCartStore.instance,
          builder: (context, _) => Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x19000000),
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('product-add-to-cart'),
                    onPressed: product.stock > 0
                        ? () {
                            final added = ProductCartStore.instance.add(
                              product,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  added
                                      ? '${product.name} added to cart.'
                                      : 'The requested quantity is not available.',
                                ),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: const Text('Add to Cart'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('product-buy-now'),
                    onPressed: product.stock > 0
                        ? () {
                            ProductCartStore.instance.add(product);
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ProductCartPage(),
                              ),
                            );
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: ProductStyles.green,
                    ),
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Buy Now'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product photo gallery with a single, familiar back action.
                    Stack(
                      children: [
                        _ProductGallery(product: product),
                        Positioned(
                          left: 14,
                          top: 12,
                          child: _CircleButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                    // Title banner.
                    Container(
                      width: double.infinity,
                      color: ProductStyles.mint,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            PetOwnerHomePage.logoAsset,
                            key: const ValueKey('pet-product-detail-logo'),
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatMmk(product.price),
                            key: const ValueKey('product-detail-price'),
                            style: const TextStyle(
                              color: ProductStyles.red,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            product.stock > 0
                                ? '${product.stock} ${product.weight} available'
                                : 'Out of stock',
                            key: const ValueKey('product-detail-stock'),
                            style: TextStyle(
                              color: product.stock > 0
                                  ? ProductStyles.green
                                  : ProductStyles.red,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _ProductFacts(product: product),
                          const Divider(height: 30),
                          const Text(
                            'Description',
                            style: ProductStyles.sectionTitle,
                          ),
                          const SizedBox(height: 10),
                          KeyedSubtree(
                            key: const ValueKey('product-detail-description'),
                            child: _Description(text: product.description),
                          ),
                          const SizedBox(height: 28),
                          _RecommendationSection(
                            key: const ValueKey('more-for-you-section'),
                            title: 'More for You',
                            products: moreForYou,
                          ),
                          const SizedBox(height: 26),
                          _RecommendationSection(
                            key: const ValueKey(
                              'collection-you-may-love-section',
                            ),
                            title: 'Collection You May Love',
                            products: collectionYouMayLove,
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCartButton extends StatelessWidget {
  const _ProductCartButton();

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ProductCartStore.instance,
    builder: (context, _) => Badge(
      isLabelVisible: ProductCartStore.instance.itemCount > 0,
      label: Text('${ProductCartStore.instance.itemCount}'),
      child: IconButton(
        key: const ValueKey('open-product-cart'),
        tooltip: 'Cart',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ProductCartPage()),
        ),
        icon: const Icon(Icons.shopping_cart_outlined),
      ),
    ),
  );
}

class ProductCartPage extends StatelessWidget {
  const ProductCartPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ProductStyles.background,
    body: SafeArea(
      child: Column(
        children: [
          PetOwnerPageHeader(
            title: 'Shopping Cart',
            actions: [
              IconButton(
                key: const ValueKey('open-product-orders'),
                tooltip: 'My orders',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProductOrdersPage(),
                  ),
                ),
                icon: const Icon(Icons.receipt_long_outlined),
              ),
            ],
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: ProductCartStore.instance,
              builder: (context, _) {
                final cart = ProductCartStore.instance;
                if (cart.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 64),
                        SizedBox(height: 12),
                        Text(
                          'Your cart is empty',
                          style: ProductStyles.sectionTitle,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: cart.lines.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _CartLineCard(line: cart.lines[index]),
                );
              },
            ),
          ),
          AnimatedBuilder(
            animation: ProductCartStore.instance,
            builder: (context, _) {
              final cart = ProductCartStore.instance;
              if (cart.isEmpty) return const SizedBox.shrink();
              return SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal', style: ProductStyles.body),
                          Text(
                            formatMmk(cart.subtotal),
                            key: const ValueKey('cart-subtotal'),
                            style: ProductStyles.sectionTitle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const ValueKey('proceed-to-checkout'),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ProductCheckoutPage(),
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: ProductStyles.green,
                            minimumSize: const Size.fromHeight(52),
                          ),
                          icon: const Icon(Icons.lock_outline_rounded),
                          label: const Text('Proceed to Checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _CartLineCard extends StatelessWidget {
  const _CartLineCard({required this.line});
  final CartLine line;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey(
      'cart-line-${line.product.inventoryId.isEmpty ? line.product.name : line.product.inventoryId}',
    ),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFDDE9E4)),
    ),
    child: Row(
      children: [
        SizedBox.square(
          dimension: 72,
          child: ProductArt(product: line.product),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line.product.name, style: ProductStyles.productName),
              const SizedBox(height: 3),
              Text(formatMmk(line.product.price), style: ProductStyles.caption),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton.outlined(
                    key: ValueKey('cart-minus-${line.product.name}'),
                    onPressed: () => ProductCartStore.instance.setQuantity(
                      line,
                      line.quantity - 1,
                    ),
                    icon: const Icon(Icons.remove_rounded, size: 18),
                  ),
                  Text(
                    '${line.quantity}',
                    key: ValueKey('cart-quantity-${line.product.name}'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  IconButton.outlined(
                    key: ValueKey('cart-plus-${line.product.name}'),
                    onPressed: () {
                      final updated = ProductCartStore.instance.setQuantity(
                        line,
                        line.quantity + 1,
                      );
                      if (!updated) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No more stock is available.'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
        Text(formatMmk(line.total), style: ProductStyles.productName),
      ],
    ),
  );
}

class ProductCheckoutPage extends StatefulWidget {
  const ProductCheckoutPage({super.key});

  @override
  State<ProductCheckoutPage> createState() => _ProductCheckoutPageState();
}

class _ProductCheckoutPageState extends State<ProductCheckoutPage> {
  bool _placing = false;
  String? _error;
  ProductOrder? _completed;
  String _paymentTiming = 'Pay online';

  Future<void> _continueToPayment() async {
    if (_placing) return;
    final selection = await Navigator.of(context).push<ProductPaymentSelection>(
      MaterialPageRoute(
        builder: (_) => ProductPaymentPage(paymentTiming: _paymentTiming),
      ),
    );
    if (selection != null && mounted) await _placeOrder(selection);
  }

  Future<void> _placeOrder(ProductPaymentSelection payment) async {
    final cart = ProductCartStore.instance;
    if (cart.isEmpty || _placing) return;
    final inventory = StaffOperationsStore.instance;
    for (final line in cart.lines) {
      if (line.product.inventoryId.isEmpty) continue;
      final matches = inventory.activeInventory.where(
        (item) => item.id == line.product.inventoryId,
      );
      if (matches.isEmpty ||
          matches.first.availableUnexpiredQuantity < line.quantity) {
        setState(
          () => _error = '${line.product.name} no longer has enough stock.',
        );
        return;
      }
    }
    setState(() {
      _placing = true;
      _error = null;
    });
    final now = DateTime.now();
    final profile = OwnerProfileStore.instance.profile;
    final order = ProductOrder(
      id: 'ORD-${now.microsecondsSinceEpoch}',
      createdAt: now,
      items: cart.lines
          .map(
            (line) => ProductOrderLine(
              inventoryId: line.product.inventoryId,
              name: line.product.name,
              unitPrice: line.product.price,
              quantity: line.quantity,
            ),
          )
          .toList(),
      total: cart.subtotal,
      ownerName: profile.fullName,
      ownerPhone: profile.phone,
      paymentTiming: payment.paymentTiming,
      paymentMethod: payment.paymentMethod,
    );
    ProductOrderStore.instance.add(order);
    try {
      if (DatabaseSync.instance.active) {
        await DatabaseSync.instance.flushOrThrow();
        await DatabaseSync.instance.refreshTables([
          'inventory',
          'product_orders',
        ]);
      } else if (ClinicApi.instance.token != null) {
        for (final line in cart.lines) {
          if (line.product.inventoryId.isEmpty) continue;
          final item = inventory.activeInventory.firstWhere(
            (item) => item.id == line.product.inventoryId,
          );
          inventory.stockOut(
            item,
            line.quantity,
            reason: 'Reserved for ${order.id}',
            reference: order.id,
          );
        }
      }
      cart.clear();
      final completedOrder = ProductOrderStore.instance.orders.firstWhere(
        (saved) => saved.id == order.id,
        orElse: () => order,
      );
      if (mounted) setState(() => _completed = completedOrder);
    } catch (error) {
      ProductOrderStore.instance.remove(order);
      if (mounted) {
        setState(
          () => _error = 'The order could not be reserved. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = _completed;
    if (completed != null) return _OrderConfirmation(order: completed);
    final profile = OwnerProfileStore.instance.profile;
    final cart = ProductCartStore.instance;
    return Scaffold(
      backgroundColor: ProductStyles.background,
      body: SafeArea(
        child: Column(
          children: [
            const PetOwnerPageHeader(title: 'Checkout'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  const Text(
                    'Pickup details',
                    style: ProductStyles.sectionTitle,
                  ),
                  const SizedBox(height: 10),
                  _CheckoutCard(
                    rows: [
                      (
                        'Customer',
                        profile.fullName.isEmpty
                            ? 'Registered owner'
                            : profile.fullName,
                      ),
                      (
                        'Phone',
                        profile.phone.isEmpty ? 'Not recorded' : profile.phone,
                      ),
                      ('Fulfillment', 'Clinic pickup'),
                      ('Payment', _paymentTiming),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'When would you like to pay?',
                    style: ProductStyles.sectionTitle,
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'Pay online',
                        label: Text('Pay online'),
                        icon: Icon(Icons.language_rounded),
                      ),
                      ButtonSegment(
                        value: 'Pay at clinic',
                        label: Text('Pay at clinic'),
                        icon: Icon(Icons.storefront_outlined),
                      ),
                    ],
                    selected: {_paymentTiming},
                    onSelectionChanged: (selection) =>
                        setState(() => _paymentTiming = selection.single),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Order summary',
                    style: ProductStyles.sectionTitle,
                  ),
                  const SizedBox(height: 10),
                  _CheckoutCard(
                    rows: [
                      for (final line in cart.lines)
                        (
                          '${line.quantity} × ${line.product.name}',
                          formatMmk(line.total),
                        ),
                      ('Total', formatMmk(cart.subtotal)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _paymentTiming == 'Pay online'
                        ? 'Continue to the secure payment page to pay by MMQR before pickup.'
                        : 'Continue to choose Cash or MMQR. Clinic staff will verify the payment and issue a receipt.',
                    style: ProductStyles.caption,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: ProductStyles.red),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('place-product-order'),
                  onPressed: _placing ? null : _continueToPayment,
                  style: FilledButton.styleFrom(
                    backgroundColor: ProductStyles.green,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  icon: _placing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    _placing ? 'Reserving items…' : 'Continue to Payment',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductPaymentSelection {
  const ProductPaymentSelection({
    required this.paymentTiming,
    required this.paymentMethod,
  });

  final String paymentTiming;
  final String paymentMethod;
}

class ProductPaymentPage extends StatefulWidget {
  const ProductPaymentPage({super.key, required this.paymentTiming});

  final String paymentTiming;

  @override
  State<ProductPaymentPage> createState() => _ProductPaymentPageState();
}

class _ProductPaymentPageState extends State<ProductPaymentPage> {
  late String _method = widget.paymentTiming == 'Pay online' ? 'MMQR' : 'Cash';

  @override
  Widget build(BuildContext context) {
    final online = widget.paymentTiming == 'Pay online';
    final total = ProductCartStore.instance.subtotal;
    return Scaffold(
      key: const ValueKey('product-payment-page'),
      backgroundColor: ProductStyles.background,
      body: SafeArea(
        child: Column(
          children: [
            const PetOwnerPageHeader(title: 'Payment'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Row(
                    children: [
                      _PaymentStep(number: '1', label: 'Checkout', done: true),
                      const Expanded(child: Divider()),
                      _PaymentStep(number: '2', label: 'Payment', done: false),
                      const Expanded(child: Divider()),
                      _PaymentStep(number: '3', label: 'Receipt', done: false),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _CheckoutCard(
                    rows: [
                      ('Payment timing', widget.paymentTiming),
                      ('Order total', formatMmk(total)),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    online ? 'Online payment method' : 'Pay at clinic with',
                    style: ProductStyles.sectionTitle,
                  ),
                  const SizedBox(height: 10),
                  if (online)
                    _PaymentMethodCard(
                      key: const ValueKey('payment-method-mmqr'),
                      selected: true,
                      icon: Icons.qr_code_2_rounded,
                      title: 'Pay by MMQR',
                      subtitle:
                          'A unique QR reference will be created for this exact order total.',
                      onTap: () {},
                    )
                  else ...[
                    _PaymentMethodCard(
                      key: const ValueKey('payment-method-cash'),
                      selected: _method == 'Cash',
                      icon: Icons.payments_outlined,
                      title: 'Pay by cash',
                      subtitle:
                          'Pay at pickup. Staff records cash tendered, change and receipt number.',
                      onTap: () => setState(() => _method = 'Cash'),
                    ),
                    const SizedBox(height: 10),
                    _PaymentMethodCard(
                      key: const ValueKey('payment-method-mmqr'),
                      selected: _method == 'MMQR',
                      icon: Icons.qr_code_2_rounded,
                      title: 'Pay by MMQR',
                      subtitle:
                          'Scan at the clinic; settlement remains pending until verified.',
                      onTap: () => setState(() => _method = 'MMQR'),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8F2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          color: ProductStyles.green,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _method == 'MMQR'
                                ? 'Creating a QR does not mark the order paid. The amount and reference must match a verified settlement.'
                                : 'The order stays unpaid until clinic staff records the cash receipt. Duplicate receipt numbers are rejected.',
                            style: ProductStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('confirm-product-payment-method'),
                  onPressed: () => Navigator.pop(
                    context,
                    ProductPaymentSelection(
                      paymentTiming: widget.paymentTiming,
                      paymentMethod: _method,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: ProductStyles.green,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  icon: const Icon(Icons.lock_outline_rounded),
                  label: Text(
                    _method == 'MMQR'
                        ? 'Reserve Order & Create MMQR'
                        : 'Reserve Order for Cash Payment',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentStep extends StatelessWidget {
  const _PaymentStep({
    required this.number,
    required this.label,
    required this.done,
  });
  final String number;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      CircleAvatar(
        radius: 15,
        backgroundColor: ProductStyles.green,
        child: done
            ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
            : Text(number, style: const TextStyle(color: Colors.white)),
      ),
      const SizedBox(height: 4),
      Text(label, style: ProductStyles.caption),
    ],
  );
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    super.key,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? ProductStyles.green : const Color(0xFFDDE9E4),
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEAF8F2),
            child: Icon(icon, color: ProductStyles.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: ProductStyles.caption),
              ],
            ),
          ),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? ProductStyles.green : Colors.grey,
          ),
        ],
      ),
    ),
  );
}

class _CheckoutCard extends StatelessWidget {
  const _CheckoutCard({required this.rows});
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFDDE9E4)),
    ),
    child: Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(rows[index].$1, style: ProductStyles.caption),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  rows[index].$2,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          if (index < rows.length - 1) const Divider(height: 20),
        ],
      ],
    ),
  );
}

class _OrderConfirmation extends StatelessWidget {
  const _OrderConfirmation({required this.order});
  final ProductOrder order;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const ValueKey('product-order-confirmation'),
    backgroundColor: ProductStyles.background,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 36),
          const Icon(
            Icons.check_circle_rounded,
            size: 84,
            color: ProductStyles.green,
          ),
          const SizedBox(height: 18),
          const Text(
            'Order Reserved',
            textAlign: TextAlign.center,
            style: ProductStyles.sectionTitle,
          ),
          const SizedBox(height: 8),
          Text(
            order.id,
            textAlign: TextAlign.center,
            style: ProductStyles.caption,
          ),
          const SizedBox(height: 24),
          _CheckoutCard(
            rows: [
              ('Status', order.status),
              (
                'Items',
                '${order.items.fold<int>(0, (sum, item) => sum + item.quantity)}',
              ),
              ('Total', formatMmk(order.total)),
              ('Payment timing', order.paymentTiming),
              ('Payment', order.paymentMethod),
              if (order.paymentStatus.isNotEmpty)
                ('Payment status', order.paymentStatus),
              ('Pickup', "Nway's Love Vet Clinic"),
            ],
          ),
          if (order.paymentMethod == 'MMQR' && order.mmqr.isNotEmpty) ...[
            const SizedBox(height: 18),
            _MmqrPaymentPanel(order: order),
          ],
          if (order.receipt.isNotEmpty) ...[
            const SizedBox(height: 18),
            _ReceiptCard(receipt: order.receipt, paymentId: order.paymentId),
          ],
          const SizedBox(height: 18),
          FilledButton(
            key: const ValueKey('finish-product-order'),
            onPressed: () => Navigator.of(context).popUntil(
              (route) =>
                  route.isFirst ||
                  route.settings.name == PetProductsPage.routeName,
            ),
            style: FilledButton.styleFrom(backgroundColor: ProductStyles.green),
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    ),
  );
}

class _MmqrPaymentPanel extends StatefulWidget {
  const _MmqrPaymentPanel({required this.order});
  final ProductOrder order;

  @override
  State<_MmqrPaymentPanel> createState() => _MmqrPaymentPanelState();
}

class _MmqrPaymentPanelState extends State<_MmqrPaymentPanel> {
  late Map<String, dynamic> _mmqr = Map<String, dynamic>.from(
    widget.order.mmqr,
  );
  late String _status = widget.order.paymentStatus.isEmpty
      ? 'Pending'
      : widget.order.paymentStatus;
  late Map<String, dynamic> _receipt = Map<String, dynamic>.from(
    widget.order.receipt,
  );
  Timer? _clock;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    if (ClinicApi.instance.token != null && widget.order.paymentId.isNotEmpty) {
      unawaited(_request('POST', '/mmqr/displayed'));
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Duration get _remaining {
    final expiry = DateTime.tryParse(_mmqr['expiresAt'] as String? ?? '');
    if (expiry == null) return Duration.zero;
    final value = expiry.difference(DateTime.now().toUtc());
    return value.isNegative ? Duration.zero : value;
  }

  Future<void> _request(
    String method,
    String suffix, [
    Map<String, dynamic>? body,
  ]) async {
    if (ClinicApi.instance.token == null) return;
    setState(() => _busy = true);
    try {
      final result = await ClinicApi.instance.request(
        method,
        '/payments/${Uri.encodeComponent(widget.order.paymentId)}$suffix',
        body,
      );
      final value = Map<String, dynamic>.from(
        result['record']['data']['value'] as Map,
      );
      if (!mounted) return;
      setState(() {
        _status = value['status'] as String? ?? _status;
        _mmqr = Map<String, dynamic>.from(value['mmqr'] as Map? ?? _mmqr);
        _receipt = Map<String, dynamic>.from(
          value['receipt'] as Map? ?? const <String, dynamic>{},
        );
      });
      await DatabaseSync.instance.refreshTable('product_orders');
    } on ClinicApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() => _request('GET', '/status');
  Future<void> _cancel() =>
      _request('POST', '/mmqr/cancel', {'reason': 'Cancelled by customer'});
  Future<void> _regenerate() => _request('POST', '/mmqr/regenerate');

  Widget _qrImage() {
    final dataUrl = _mmqr['qrImageDataUrl'] as String? ?? '';
    if (!dataUrl.startsWith('data:image/')) {
      return const Icon(
        Icons.qr_code_2_rounded,
        size: 160,
        color: ProductStyles.green,
      );
    }
    try {
      return Image.memory(
        base64Decode(dataUrl.substring(dataUrl.indexOf(',') + 1)),
        width: 220,
        height: 220,
        gaplessPlayback: true,
      );
    } catch (_) {
      return const Icon(Icons.broken_image_outlined, size: 80);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    final pending = _status == 'Pending' && _mmqr['status'] == 'Pending';
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDDE9E4)),
          ),
          child: Column(
            children: [
              _qrImage(),
              const SizedBox(height: 8),
              Text(
                pending
                    ? 'Waiting for payment'
                    : 'MMQR ${_mmqr['status'] ?? _status}',
                style: ProductStyles.sectionTitle,
              ),
              const SizedBox(height: 6),
              Text(
                formatMmk(
                  (_mmqr['amount'] as num?)?.toInt() ?? widget.order.total,
                ),
              ),
              Text(
                'Reference: ${_mmqr['reference']}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                pending && remaining > Duration.zero
                    ? 'Expires in $minutes:$seconds'
                    : pending
                    ? 'QR expired — refresh or regenerate'
                    : 'Payment status: $_status',
                style: TextStyle(
                  color: pending && remaining <= Duration.zero
                      ? ProductStyles.red
                      : ProductStyles.green,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (_busy)
                const CircularProgressIndicator()
              else
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh status'),
                    ),
                    if (pending && remaining > Duration.zero)
                      TextButton(
                        onPressed: _cancel,
                        child: const Text('Cancel QR'),
                      ),
                    if (!pending || remaining <= Duration.zero)
                      FilledButton.icon(
                        onPressed: _regenerate,
                        icon: const Icon(Icons.qr_code_2_rounded),
                        label: const Text('Generate new QR'),
                      ),
                  ],
                ),
              const SizedBox(height: 8),
              const Text(
                'A QR image is not proof of payment. The order becomes paid only after verified settlement.',
                textAlign: TextAlign.center,
                style: ProductStyles.caption,
              ),
            ],
          ),
        ),
        if (_receipt.isNotEmpty) ...[
          const SizedBox(height: 18),
          _ReceiptCard(receipt: _receipt, paymentId: widget.order.paymentId),
        ],
      ],
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.receipt, required this.paymentId});
  final Map<String, dynamic> receipt;
  final String paymentId;

  Future<void> _open(String key) async {
    final value = receipt[key] as String? ?? '';
    if (value.isEmpty) return;
    await launchUrl(Uri.parse(value), mode: LaunchMode.externalApplication);
  }

  Future<void> _email(BuildContext context) async {
    try {
      final result = await ClinicApi.instance.request(
        'POST',
        '/payments/${Uri.encodeComponent(paymentId)}/receipt/email',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt email queued for ${result['email']}'),
          ),
        );
      }
    } on ClinicApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFDDE9E4)),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.receipt_long_rounded,
          size: 48,
          color: ProductStyles.green,
        ),
        const Text('Digital receipt', style: ProductStyles.sectionTitle),
        const SizedBox(height: 6),
        Text(receipt['receiptNumber'] as String? ?? ''),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _open('verificationUrl'),
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Verify'),
            ),
            FilledButton.icon(
              onPressed: () => _open('pdfUrl'),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download / Print'),
            ),
            OutlinedButton.icon(
              onPressed: () => _email(context),
              icon: const Icon(Icons.email_outlined),
              label: const Text('Email'),
            ),
          ],
        ),
      ],
    ),
  );
}

class ProductOrdersPage extends StatelessWidget {
  const ProductOrdersPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ProductStyles.background,
    body: SafeArea(
      child: Column(
        children: [
          const PetOwnerPageHeader(title: 'My Product Orders'),
          Expanded(
            child: AnimatedBuilder(
              animation: ProductOrderStore.instance,
              builder: (context, _) {
                final orders = ProductOrderStore.instance.orders;
                if (orders.isEmpty) {
                  return const Center(child: Text('No product orders yet.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Column(
                      children: [
                        _CheckoutCard(
                          rows: [
                            ('Order', order.id),
                            ('Status', order.status),
                            ('Total', formatMmk(order.total)),
                            ('Payment timing', order.paymentTiming),
                            ('Payment', order.paymentMethod),
                            if (order.paymentStatus.isNotEmpty)
                              ('Payment status', order.paymentStatus),
                            if (order.paymentAuditTrail.isNotEmpty)
                              (
                                'Payment audit',
                                '${order.paymentAuditTrail.length} verified events',
                              ),
                          ],
                        ),
                        if (order.receipt.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _ReceiptCard(
                            receipt: order.receipt,
                            paymentId: order.paymentId,
                          ),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

List<Product> _recommendationsFor(
  Product current,
  bool Function(Product product) matches, {
  List<Product> excluded = const [],
}) {
  final excludedNames = {current.name, ...excluded.map((item) => item.name)};
  final available = products
      .where((item) => !excludedNames.contains(item.name))
      .toList();
  final preferred = available.where(matches).take(4).toList();
  if (preferred.length < 4) {
    preferred.addAll(
      available
          .where((item) => !preferred.any((match) => match.name == item.name))
          .take(4 - preferred.length),
    );
  }
  return preferred;
}

// ---------------------------------------------------------------------------
// Product model + data source (real inventory)
// ---------------------------------------------------------------------------

class Product {
  const Product({
    this.inventoryId = '',
    required this.name,
    required this.category,
    required this.brand,
    required this.price,
    required this.description,
    required this.petType,
    required this.weight,
    required this.color,
    required this.icon,
    this.imageAsset,
    this.photoUrl = '',
    this.imageUrls = const [],
    this.subcategory = '',
    this.stock = 20,
  });

  final String inventoryId;
  final String name;
  final String category;
  final String brand;
  final int price;
  final String description;
  final String petType;
  final String weight;
  final Color color;
  final IconData icon;
  final String? imageAsset;

  /// Inline product image (base64 data URI) when available.
  final String photoUrl;
  final List<String> imageUrls;
  final String subcategory;
  final int stock;

  List<String> get galleryImages {
    if (imageUrls.isNotEmpty) return imageUrls;
    if (photoUrl.isNotEmpty) return [photoUrl];
    if ((imageAsset ?? '').isNotEmpty) return [imageAsset!];
    return const [];
  }
}

Color _categoryColor(String category) {
  switch (_normalizedProductCategory(category)) {
    case 'Food':
      return const Color(0xFFFFD329);
    case 'Medicine':
      return const Color(0xFF5DA7FF);
    case 'Grooming':
      return const Color(0xFF06C957);
    case 'Toys':
      return const Color(0xFFFF6C73);
    case 'Accessories':
      return const Color(0xFF9B8CFF);
    default:
      return const Color(0xFFA1FDD8);
  }
}

IconData _categoryIcon(String category) {
  switch (_normalizedProductCategory(category)) {
    case 'Food':
      return Icons.restaurant_rounded;
    case 'Medicine':
      return Icons.medication_rounded;
    case 'Grooming':
      return Icons.shower_rounded;
    case 'Toys':
      return Icons.toys_rounded;
    case 'Accessories':
      return Icons.pets_rounded;
    default:
      return Icons.pets_rounded;
  }
}

String? _categoryIconAsset(String category) {
  switch (_normalizedProductCategory(category)) {
    case 'Food':
      return 'assets/photos/icon/pet_food.png';
    case 'Medicine':
      return 'assets/photos/icon/pet_medicine.png';
    case 'Accessories':
      return 'assets/photos/icon/pet_accessories.png';
    default:
      return null;
  }
}

String _normalizedProductCategory(String category) {
  switch (category) {
    case 'Food':
    case 'Pet Food':
    case 'Treats':
      return 'Food';
    case 'Medicine':
    case 'Vaccines':
    case 'Medical Supplies':
      return 'Medicine';
    case 'Accessories':
    case 'Grooming':
    case 'Toys':
    case 'Cleaning Supplies':
    case 'Other':
      return 'Accessories';
    default:
      return 'Accessories';
  }
}

List<Product> get products => ClinicApi.instance.token == null
    ? _demoProducts
    : StaffOperationsStore.instance.activeInventory
          .map(
            (item) => Product(
              inventoryId: item.id,
              name: item.name,
              category: _normalizedProductCategory(item.category),
              subcategory: item.subcategory,
              brand: item.brand.isNotEmpty
                  ? item.brand
                  : item.supplier.isEmpty
                  ? 'Clinic Shop'
                  : item.supplier,
              price: item.sellingPrice,
              description: item.description.isNotEmpty
                  ? item.description
                  : '${item.name}. Category: ${item.category}.',
              petType: item.petType,
              weight: item.unit,
              color: _categoryColor(item.category),
              icon: _categoryIcon(item.category),
              // Base64 data URIs show as real photos; asset paths fall back to
              // the asset image; both handled by ProductArt.
              imageAsset:
                  (item.imageAsset != null &&
                      item.imageAsset!.startsWith('assets/'))
                  ? item.imageAsset
                  : null,
              photoUrl:
                  (item.imageAsset != null &&
                      item.imageAsset!.startsWith('data:'))
                  ? item.imageAsset!
                  : '',
              imageUrls: item.productImages,
              stock: item.availableUnexpiredQuantity,
            ),
          )
          .toList();

const _demoProducts = <Product>[
  Product(
    name: 'Dog Food 01',
    category: 'Food',
    subcategory: 'Dog Food',
    brand: 'Pedigree',
    price: 4000,
    description: 'Balanced nutrition dry food for adult dogs.',
    petType: 'Dog',
    weight: '1 kg',
    color: Color(0xFFFFD329),
    icon: Icons.pets_rounded,
  ),
  Product(
    name: 'Cat Food 01',
    category: 'Food',
    subcategory: 'Cat Food',
    brand: 'Meow Mix',
    price: 4000,
    description: 'Original choice cat food with balanced nutrition.',
    petType: 'Cat',
    weight: '800 g',
    color: Color(0xFFFFC83D),
    icon: Icons.cruelty_free_rounded,
  ),
  Product(
    name: 'Dog Food 02',
    category: 'Food',
    subcategory: 'Dog Food',
    brand: 'Pedigree',
    price: 6000,
    description: 'Adult dog food with chicken and vegetable flavor.',
    petType: 'Dog',
    weight: '10 kg',
    color: Color(0xFFD72D39),
    icon: Icons.pets_rounded,
  ),
  Product(
    name: 'Dog Toy',
    category: 'Accessories',
    subcategory: 'Accessories',
    brand: 'Nway',
    price: 5000,
    description: 'Soft chew toy for play and exercise.',
    petType: 'Dog',
    weight: 'M',
    color: Color(0xFF5DA7FF),
    icon: Icons.toys_rounded,
  ),
];

const categories = ['All Product', 'Food', 'Medicine', 'Accessories'];
const productPetTypes = ['All Pets', 'Dog', 'Cat'];
const productSubcategories = [
  'All',
  'Dog Food',
  'Cat Food',
  'Medicine',
  'Accessories',
];

// ---------------------------------------------------------------------------
// List page widgets
// ---------------------------------------------------------------------------

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: TextField(
        key: const ValueKey('pet-products-search'),
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded, size: 22),
          hintText: 'Search products, brands, or pet type',
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFDDE9E4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFDDE9E4)),
          ),
        ),
      ),
    );
  }
}

class _CategoryIconStrip extends StatelessWidget {
  const _CategoryIconStrip({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 106,
      color: Colors.transparent,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selected == category;
          final isAll = category == 'All Product';
          final imageAsset = isAll ? null : _categoryIconAsset(category);
          return GestureDetector(
            onTap: () => onChanged(category),
            child: SizedBox(
              width: 64,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE8FFF5)
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF147D5B)
                            : const Color(0xFFDDE9E4),
                        width: 2,
                      ),
                    ),
                    child: imageAsset == null
                        ? Icon(
                            key: isAll
                                ? const ValueKey('product-category-all-icon')
                                : null,
                            isAll
                                ? Icons.grid_view_rounded
                                : _categoryIcon(category),
                            color: const Color(0xFF147D5B),
                            size: 24,
                          )
                        : Padding(
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              imageAsset,
                              width: 34,
                              height: 34,
                              fit: BoxFit.contain,
                            ),
                          ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    category == 'All Product' ? 'All' : category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SortBar extends StatelessWidget {
  const _SortBar({
    required this.sort,
    required this.count,
    required this.onSortTap,
  });
  final String sort;
  final int count;
  final VoidCallback onSortTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE9E4)),
      ),
      child: Row(
        children: [
          Tooltip(
            message: 'Filter and sort',
            child: InkWell(
              onTap: onSortTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FFF5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(
                      sort,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.swap_vert_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          Text('$count Products', style: ProductStyles.caption),
        ],
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 44, color: Color(0xFF9BB0A8)),
          SizedBox(height: 10),
          Text('No products found', style: ProductStyles.productName),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFDDE9E4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C0B2F25),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(aspectRatio: 1, child: ProductArt(product: product)),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ProductStyles.caption,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatMmk(product.price),
                    style: const TextStyle(
                      color: ProductStyles.red,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _PetTypePill(petType: product.petType),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductGallery extends StatefulWidget {
  const _ProductGallery({required this.product});
  final Product product;

  @override
  State<_ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<_ProductGallery> {
  var _index = 0;
  late final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.product.galleryImages.isEmpty
        ? <String?>[null]
        : widget.product.galleryImages.cast<String?>();
    return SizedBox(
      height: 405,
      child: Column(
        children: [
          SizedBox(
            height: 320,
            child: Stack(
              children: [
                PageView.builder(
                  key: const ValueKey('product-image-gallery'),
                  controller: _controller,
                  itemCount: images.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (_, index) => Semantics(
                    button: true,
                    label:
                        'Open ${widget.product.name} photo ${index + 1} full screen',
                    child: GestureDetector(
                      key: ValueKey('open-product-photo-$index'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _FullScreenProductGallery(
                            product: widget.product,
                            initialIndex: index,
                          ),
                        ),
                      ),
                      child: ProductArt(
                        product: widget.product,
                        large: true,
                        imageSource: images[index],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${_index + 1}/${images.length}',
                      key: const ValueKey('product-image-count'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) => AnimatedContainer(
                key: ValueKey('product-image-dot-$index'),
                duration: const Duration(milliseconds: 180),
                width: index == _index ? 18 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == _index
                      ? const Color(0xFF147D5B)
                      : const Color(0xFFC9D8D2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 54,
            child: ListView.separated(
              key: const ValueKey('product-image-thumbnails'),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => InkWell(
                key: ValueKey('product-image-thumbnail-$index'),
                onTap: () => _controller.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOutCubic,
                ),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: index == _index
                          ? const Color(0xFF147D5B)
                          : const Color(0xFFDDE9E4),
                      width: index == _index ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _ProductThumbnail(
                    product: widget.product,
                    imageSource: images[index],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenProductGallery extends StatefulWidget {
  const _FullScreenProductGallery({
    required this.product,
    required this.initialIndex,
  });

  final Product product;
  final int initialIndex;

  @override
  State<_FullScreenProductGallery> createState() =>
      _FullScreenProductGalleryState();
}

class _FullScreenProductGalleryState extends State<_FullScreenProductGallery> {
  late var _index = widget.initialIndex;
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.product.galleryImages.isEmpty
        ? <String?>[null]
        : widget.product.galleryImages.cast<String?>();
    return Scaffold(
      key: const ValueKey('full-screen-product-gallery'),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} of ${images.length}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: images.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (_, index) => InteractiveViewer(
                key: ValueKey('zoomable-product-photo-$index'),
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: ProductArt(
                    product: widget.product,
                    large: true,
                    imageSource: images[index],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => Container(
                    width: index == _index ? 20 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index == _index ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({required this.product, required this.imageSource});

  final Product product;
  final String? imageSource;

  @override
  Widget build(BuildContext context) {
    final bytes = imageSource == null ? null : _decodeDataUri(imageSource!);
    if (bytes != null) return Image.memory(bytes, fit: BoxFit.cover);
    if (imageSource != null && imageSource!.startsWith('assets/')) {
      return Image.asset(imageSource!, fit: BoxFit.cover);
    }
    return ColoredBox(
      color: product.color,
      child: Icon(product.icon, color: Colors.white, size: 24),
    );
  }
}

class ProductArt extends StatelessWidget {
  const ProductArt({
    required this.product,
    this.large = false,
    this.imageSource,
    super.key,
  });
  final Product product;
  final bool large;
  final String? imageSource;

  @override
  Widget build(BuildContext context) {
    // Prefer a real image (base64 data URI or bundled asset) when available.
    final source =
        imageSource ??
        (product.photoUrl.isNotEmpty ? product.photoUrl : product.imageAsset);
    final bytes = source == null ? null : _decodeDataUri(source);
    if (bytes != null) {
      return Container(
        color: Colors.white,
        height: large ? 320 : null,
        width: large ? double.infinity : null,
        child: Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true),
      );
    }
    if (source != null && source.startsWith('assets/')) {
      return Container(
        color: Colors.white,
        height: large ? 320 : null,
        width: large ? double.infinity : null,
        child: Image.asset(
          source,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _artFallback(),
        ),
      );
    }
    return _artFallback();
  }

  Widget _artFallback() {
    return Container(
      width: large ? double.infinity : null,
      height: large ? 320 : null,
      decoration: BoxDecoration(color: product.color),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            product.icon,
            size: large ? 130 : 52,
            color: Colors.white.withValues(alpha: 0.88),
          ),
          Positioned(
            bottom: large ? 40 : 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                product.category,
                style: TextStyle(
                  color: product.color,
                  fontWeight: FontWeight.w900,
                  fontSize: large ? 18 : 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Uint8List? _decodeDataUri(String value) {
  if (!value.startsWith('data:')) return null;
  final comma = value.indexOf(',');
  if (comma < 0) return null;
  try {
    return base64Decode(value.substring(comma + 1));
  } catch (_) {
    return null;
  }
}

class _PetTypePill extends StatelessWidget {
  const _PetTypePill({required this.petType});
  final String petType;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE8FFF5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      petType,
      style: const TextStyle(
        color: Color(0xFF16785B),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Detail page widgets
// ---------------------------------------------------------------------------

class _ProductFacts extends StatelessWidget {
  const _ProductFacts({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('product-detail-facts'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF5FBF8),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFDDE9E4)),
    ),
    child: Column(
      children: [
        _ProductFact(label: 'Brand', value: product.brand),
        _ProductFact(label: 'Pet type', value: product.petType),
        _ProductFact(label: 'Category', value: product.category),
        _ProductFact(
          label: 'Subcategory',
          value: product.subcategory.isEmpty
              ? product.category
              : product.subcategory,
          isLast: true,
        ),
      ],
    ),
  );
}

class _ProductFact extends StatelessWidget {
  const _ProductFact({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 98, child: Text(label, style: ProductStyles.caption)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _RecommendationSection extends StatelessWidget {
  const _RecommendationSection({
    required this.title,
    required this.products,
    super.key,
  });

  final String title;
  final List<Product> products;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: ProductStyles.sectionTitle),
      const SizedBox(height: 12),
      if (products.isEmpty)
        const Text(
          'More clinic products will appear here soon.',
          style: ProductStyles.caption,
        )
      else
        SizedBox(
          height: 238,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return _MiniProductCard(
                product: product,
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(ProductDetailsPage.routeName, arguments: product),
              );
            },
          ),
        ),
    ],
  );
}

class _MiniProductCard extends StatelessWidget {
  const _MiniProductCard({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 152,
    child: Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFDDE9E4)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 112,
              width: double.infinity,
              child: ProductArt(product: product),
            ),
            Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ProductStyles.caption,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    formatMmk(product.price),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ProductStyles.red,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _PetTypePill(petType: product.petType),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: Colors.black87),
        ),
      ),
    );
  }
}

class _Description extends StatefulWidget {
  const _Description({required this.text});
  final String text;
  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: ProductStyles.body,
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? 'See less' : 'See more'),
          ),
        ),
      ],
    );
  }
}
