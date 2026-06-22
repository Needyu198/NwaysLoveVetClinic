import 'package:flutter/material.dart';

import 'pet_owner_nav_bar.dart';
import 'pet_product_styles.dart';

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
  bool _showQuickMenu = false;

  List<Product> get _visibleProducts {
    final lowered = _query.toLowerCase();
    final filtered = products.where((product) {
      final categoryMatch =
          _category == 'All Product' || product.category == _category;
      final queryMatch =
          lowered.isEmpty ||
          product.name.toLowerCase().contains(lowered) ||
          product.brand.toLowerCase().contains(lowered) ||
          product.petType.toLowerCase().contains(lowered);
      return categoryMatch && queryMatch;
    }).toList();

    switch (_sort) {
      case 'Price Low':
        filtered.sort((a, b) => a.price.compareTo(b.price));
      case 'Price High':
        filtered.sort((a, b) => b.price.compareTo(a.price));
      case 'Rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
      case 'Newest':
        filtered.sort((a, b) => b.stock.compareTo(a.stock));
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProductStyles.background,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _ProductHeader(
                  title: 'Available Products',
                  onBack: () => Navigator.of(context).pop(),
                  trailing: IconButton(
                    onPressed: () =>
                        setState(() => _showQuickMenu = !_showQuickMenu),
                    icon: const Icon(Icons.tune_rounded),
                    tooltip: 'Filters',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
                  child: _SearchBar(
                    onChanged: (value) => setState(() => _query = value),
                    onFilterTap: _openFilterSheet,
                  ),
                ),
                _CategoryStrip(
                  selected: _category,
                  onChanged: (value) => setState(() => _category = value),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 118),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 14,
                        ),
                    itemCount: _visibleProducts.length,
                    itemBuilder: (context, index) {
                      final product = _visibleProducts[index];
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
          if (_showQuickMenu)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showQuickMenu = false),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.34),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _QuickProductMenu(
                      onOrdersTap: () {
                        setState(() => _showQuickMenu = false);
                        Navigator.of(context).pushNamed(OrdersPage.routeName);
                      },
                      onCartTap: () {
                        setState(() => _showQuickMenu = false);
                        Navigator.of(context).pushNamed(CartPage.routeName);
                      },
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 28,
            bottom: 128,
            child: FloatingActionButton.small(
              heroTag: 'product-menu',
              onPressed: () => setState(() => _showQuickMenu = true),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              child: const Icon(Icons.shopping_cart_checkout_rounded, size: 28),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: PetOwnerNavBar(
              selectedItem: PetOwnerNavItem.shop,
              onProfileTap: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  void _openFilterSheet() {
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
              const Text('Sort & Filter', style: ProductStyles.sectionTitle),
              const SizedBox(height: 14),
              const Text('Sort by', style: ProductStyles.caption),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    ['Popular', 'Newest', 'Price Low', 'Price High', 'Rating']
                        .map(
                          (sort) => ChoiceChip(
                            label: Text(sort),
                            selected: _sort == sort,
                            onSelected: (_) {
                              setState(() => _sort = sort);
                              Navigator.of(context).pop();
                            },
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 20),
              const Text('Quick filters', style: ProductStyles.caption),
              const SizedBox(height: 8),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('Dog')),
                  Chip(label: Text('Cat')),
                  Chip(label: Text('In stock')),
                  Chip(label: Text('Under 5,000 MMK')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key});

  static const String routeName = '/product-details';

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int quantity = 2;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final product = args is Product ? args : products.first;

    return Scaffold(
      backgroundColor: Colors.white,
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
                    Stack(
                      children: [
                        _ProductHeroArt(product: product),
                        Positioned(
                          left: 18,
                          top: 18,
                          child: _BackCircle(
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                        Positioned(
                          right: 18,
                          bottom: 0,
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.share_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFC95B77), Color(0xFF3D252A)],
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${product.price} MMK',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${product.rating}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: ProductStyles.detailTitle,
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.favorite_border_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFF3F4F6),
                                ),
                                tooltip: 'Wishlist',
                              ),
                            ],
                          ),
                          Text(
                            '${product.brand} • ${product.petType} • ${product.weight}',
                            style: ProductStyles.caption,
                          ),
                          const SizedBox(height: 12),
                          _StockPill(stock: product.stock),
                          const SizedBox(height: 16),
                          Text(product.description, style: ProductStyles.body),
                          const Divider(height: 34),
                          const _InfoCard(
                            icon: Icons.local_shipping_rounded,
                            title: 'Delivery',
                            detail:
                                'Standard delivery available. Usually arrives within 2-3 days.',
                          ),
                          const Divider(height: 34),
                          Row(
                            children: [
                              const Text(
                                'Quantity',
                                style: ProductStyles.sectionTitle,
                              ),
                              const Spacer(),
                              _QuantitySelector(
                                quantity: quantity,
                                onMinus: () => setState(
                                  () => quantity = quantity > 1
                                      ? quantity - 1
                                      : 1,
                                ),
                                onPlus: () => setState(() => quantity++),
                              ),
                            ],
                          ),
                          const Divider(height: 34),
                          _DetailInfo(product: product),
                          const SizedBox(height: 16),
                          const _ReviewsPreview(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 26),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed(CartPage.routeName),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: const Text('Add to Cart'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(CheckoutPage.routeName),
                      style: FilledButton.styleFrom(
                        backgroundColor: ProductStyles.green,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: const Text('Buy Now'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  static const String routeName = '/cart';

  @override
  Widget build(BuildContext context) {
    return _CartLikePage(
      title: 'Cart',
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.radio_button_unchecked_rounded, size: 28),
              SizedBox(width: 8),
              Text('Select all', style: ProductStyles.body),
              Spacer(),
              Text('Subtotal', style: ProductStyles.caption),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('8,000 MMK', style: ProductStyles.rowTitle),
              const SizedBox(width: 18),
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(CheckoutPage.routeName),
                  style: FilledButton.styleFrom(
                    backgroundColor: ProductStyles.green,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  child: const Text('Check Out'),
                ),
              ),
            ],
          ),
        ],
      ),
      products: [products[0], products[4], products[5]],
    );
  }
}

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  static const String routeName = '/checkout';

  @override
  Widget build(BuildContext context) {
    return _CartLikePage(
      title: 'Check Out',
      products: [products[0]],
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Text('Total (2 items)', style: ProductStyles.body),
              Spacer(),
              Text('8,000 MMK', style: ProductStyles.rowTitle),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: () => _showPaymentMethods(context),
              style: FilledButton.styleFrom(
                backgroundColor: ProductStyles.green,
              ),
              child: const Text('Place Order'),
            ),
          ),
        ],
      ),
    );
  }

  static void _showPaymentMethods(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _PaymentMethodSheet(),
    );
  }
}

class PaymentQrPage extends StatefulWidget {
  const PaymentQrPage({super.key});

  static const String routeName = '/payment-qr';

  @override
  State<PaymentQrPage> createState() => _PaymentQrPageState();
}

class _PaymentQrPageState extends State<PaymentQrPage> {
  bool _showThanks = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProductStyles.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _ProductHeader(
                  title: 'Complete Payment in 00:20:00',
                  onBack: () => Navigator.of(context).pop(),
                  closeIcon: true,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Column(
                            children: [
                              CustomPaint(
                                size: const Size(260, 260),
                                painter: _QrPainter(),
                              ),
                              const Text(
                                'K pay Wave pay\nQR here',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Total :',
                                    style: ProductStyles.rowTitle,
                                  ),
                                  SizedBox(width: 48),
                                  Text(
                                    '8,000 MMK',
                                    style: ProductStyles.rowTitle,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Please Upload Your Complete Payment Slip Here',
                                style: ProductStyles.body,
                              ),
                              const SizedBox(height: 22),
                              Container(
                                height: 110,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: const Row(
                                  children: [
                                    _SlipPreview(),
                                    Spacer(),
                                    Icon(Icons.image_outlined, size: 34),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
                _CheckoutBottom(
                  buttonText: 'Finish',
                  onPressed: () => setState(() => _showThanks = true),
                ),
              ],
            ),
            if (_showThanks)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 34),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                      color: Colors.white,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Thank You !',
                            style: ProductStyles.detailTitle,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).popUntil((route) => route.isFirst),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: ProductStyles.green,
                                  ),
                                  child: const Text('Done'),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pushReplacementNamed(OrdersPage.routeName),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFA7BBB4),
                                  ),
                                  child: const Text('Go To Order'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  static const String routeName = '/orders';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProductStyles.background,
      body: SafeArea(
        child: Column(
          children: [
            _ProductHeader(
              title: 'My Orders',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                children: [
                  _OrderCard(
                    product: products[3],
                    status: 'Delivered',
                    quantity: 2,
                  ),
                  _OrderCard(
                    product: products[1],
                    status: 'To Deliver',
                    quantity: 1,
                  ),
                  _OrderCard(
                    product: products[6],
                    status: 'To Deliver',
                    quantity: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Product {
  const Product({
    required this.name,
    required this.category,
    required this.brand,
    required this.price,
    required this.stock,
    required this.description,
    required this.petType,
    required this.weight,
    required this.rating,
    required this.reviews,
    required this.color,
    required this.icon,
  });

  final String name;
  final String category;
  final String brand;
  final int price;
  final int stock;
  final String description;
  final String petType;
  final String weight;
  final double rating;
  final int reviews;
  final Color color;
  final IconData icon;
}

const products = <Product>[
  Product(
    name: 'Dog Food 01',
    category: 'Food',
    brand: 'Pedigree',
    price: 4000,
    stock: 24,
    description: 'Description Details Description Details',
    petType: 'Dog',
    weight: '1 kg',
    rating: 4.8,
    reviews: 120,
    color: Color(0xFFFFD329),
    icon: Icons.pets_rounded,
  ),
  Product(
    name: 'Cat Food 01',
    category: 'Food',
    brand: 'Meow Mix',
    price: 4000,
    stock: 14,
    description: 'Original choice cat food with balanced nutrition.',
    petType: 'Cat',
    weight: '800 g',
    rating: 4.7,
    reviews: 96,
    color: Color(0xFFFFC83D),
    icon: Icons.cruelty_free_rounded,
  ),
  Product(
    name: 'Rabbit Food 01',
    category: 'Food',
    brand: 'Fortified',
    price: 4000,
    stock: 9,
    description: 'Pellets with fiber and vitamins for rabbits.',
    petType: 'Rabbit',
    weight: '900 g',
    rating: 4.6,
    reviews: 42,
    color: Color(0xFF9ED27D),
    icon: Icons.eco_rounded,
  ),
  Product(
    name: 'Dog Food 02',
    category: 'Food',
    brand: 'Pedigree',
    price: 6000,
    stock: 16,
    description: 'Adult dog food with chicken and vegetable flavor.',
    petType: 'Dog',
    weight: '10 kg',
    rating: 4.9,
    reviews: 160,
    color: Color(0xFFD72D39),
    icon: Icons.pets_rounded,
  ),
  Product(
    name: 'Dog Food 03',
    category: 'Food',
    brand: 'Pedigree',
    price: 10000,
    stock: 12,
    description: 'Healthy complete food for adult dogs.',
    petType: 'Dog',
    weight: '1 kg',
    rating: 4.5,
    reviews: 88,
    color: Color(0xFFFFD329),
    icon: Icons.pets_rounded,
  ),
  Product(
    name: 'Dog Toy',
    category: 'Toys',
    brand: 'Nway',
    price: 5000,
    stock: 20,
    description: 'Soft chew toy for play and exercise.',
    petType: 'Dog',
    weight: 'M',
    rating: 4.4,
    reviews: 35,
    color: Color(0xFF5DA7FF),
    icon: Icons.toys_rounded,
  ),
  Product(
    name: 'Cat Toy',
    category: 'Toys',
    brand: 'Nway',
    price: 5000,
    stock: 18,
    description: 'Colorful mouse toy for cats.',
    petType: 'Cat',
    weight: 'S',
    rating: 4.5,
    reviews: 51,
    color: Color(0xFFFF6C73),
    icon: Icons.mouse_rounded,
  ),
];

const categories = [
  'All Product',
  'Food',
  'Treats',
  'Medicine',
  'Grooming',
  'Toys',
  'Accessories',
];

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({
    required this.title,
    required this.onBack,
    this.trailing,
    this.closeIcon = false,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;
  final bool closeIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(
              closeIcon
                  ? Icons.close_rounded
                  : Icons.arrow_back_ios_new_rounded,
            ),
            iconSize: 25,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: ProductStyles.pageTitle,
            ),
          ),
          SizedBox(width: 48, child: trailing),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged, required this.onFilterTap});
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Search food, toys, medicine...',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: Color(0xFFDADDE3)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 52,
          width: 52,
          child: IconButton.filled(
            onPressed: onFilterTap,
            icon: const Icon(Icons.tune_rounded),
            style: IconButton.styleFrom(
              backgroundColor: ProductStyles.mint,
              foregroundColor: Colors.black,
            ),
            tooltip: 'Filter and sort',
          ),
        ),
      ],
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      color: ProductStyles.mint,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selected == category;
          return ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 94),
            child: ChoiceChip(
              showCheckmark: false,
              selected: isSelected,
              label: Text(category),
              onSelected: (_) => onChanged(category),
              selectedColor: ProductStyles.red,
              backgroundColor: Colors.white,
              labelStyle: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemCount: categories.length,
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
          border: Border.all(color: const Color(0xFFE6E8EC)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0B2F25),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(child: ProductArt(product: product)),
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              style: ProductStyles.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(product.brand, style: ProductStyles.caption),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${product.price} MMK',
                    style: ProductStyles.price,
                  ),
                ),
                Icon(
                  Icons.star_rounded,
                  color: Colors.amber.shade700,
                  size: 18,
                ),
                Text(
                  product.rating.toStringAsFixed(1),
                  style: ProductStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 6),
            _StockPill(stock: product.stock),
          ],
        ),
      ),
    );
  }
}

class ProductArt extends StatelessWidget {
  const ProductArt({required this.product, this.large = false, super.key});
  final Product product;
  final bool large;
  @override
  Widget build(BuildContext context) {
    final width = large ? double.infinity : 116.0;
    final height = large ? 320.0 : 104.0;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: product.color,
        borderRadius: BorderRadius.circular(large ? 0 : 18),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            product.icon,
            size: large ? 150 : 58,
            color: Colors.white.withValues(alpha: 0.86),
          ),
          Positioned(
            top: large ? 46 : 16,
            child: Text(
              product.brand,
              style: TextStyle(
                color: Colors.white,
                fontSize: large ? 42 : 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Positioned(
            bottom: large ? 60 : 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                product.petType,
                style: TextStyle(
                  color: product.color,
                  fontWeight: FontWeight.w900,
                  fontSize: large ? 22 : 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockPill extends StatelessWidget {
  const _StockPill({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final inStock = stock > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: inStock ? const Color(0xFFE8FFF5) : const Color(0xFFFFE9E5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        inStock ? 'In stock: $stock' : 'Out of stock',
        style: TextStyle(
          color: inStock ? const Color(0xFF16785B) : const Color(0xFFCE3D2E),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ProductHeroArt extends StatelessWidget {
  const _ProductHeroArt({required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) =>
      ProductArt(product: product, large: true);
}

class _BackCircle extends StatelessWidget {
  const _BackCircle({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    icon: const Icon(Icons.arrow_back_ios_new_rounded),
    style: IconButton.styleFrom(backgroundColor: Colors.white),
  );
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });
  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 56,
      decoration: const ShapeDecoration(
        color: Color(0xFFD9D9D9),
        shape: StadiumBorder(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: onMinus,
            icon: const Icon(Icons.remove_rounded),
          ),
          Text('$quantity', style: ProductStyles.rowTitle),
          IconButton(onPressed: onPlus, icon: const Icon(Icons.add_rounded)),
        ],
      ),
    );
  }
}

class _DetailInfo extends StatelessWidget {
  const _DetailInfo({required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Brand: ${product.brand}', style: ProductStyles.body),
        Text('Stock: ${product.stock} available', style: ProductStyles.body),
        Text('Suitable for: ${product.petType}', style: ProductStyles.body),
        Text('Weight/Size: ${product.weight}', style: ProductStyles.body),
        Text(
          'Rating: ${product.rating} (${product.reviews} reviews)',
          style: ProductStyles.body,
        ),
        const Text(
          'Ingredients/Materials: Balanced nutrients and pet-safe materials.',
          style: ProductStyles.body,
        ),
        const Text(
          'Usage: Follow package instructions. Store in a cool dry place.',
          style: ProductStyles.body,
        ),
        const Text(
          'Warning: Keep away from children and consult doctor for medicine.',
          style: ProductStyles.body,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3F3ED)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFE8FFF5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF16785B), size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ProductStyles.productName),
                const SizedBox(height: 4),
                Text(detail, style: ProductStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsPreview extends StatelessWidget {
  const _ReviewsPreview();

  @override
  Widget build(BuildContext context) {
    return const _InfoCard(
      icon: Icons.rate_review_rounded,
      title: 'Reviews',
      detail:
          '4.8 average rating from happy pet owners. Review list can be connected to customer feedback data.',
    );
  }
}

class _QuickProductMenu extends StatelessWidget {
  const _QuickProductMenu({required this.onOrdersTap, required this.onCartTap});
  final VoidCallback onOrdersTap;
  final VoidCallback onCartTap;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      margin: const EdgeInsets.only(right: 18),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Quick Actions', style: ProductStyles.productName),
          const SizedBox(height: 10),
          _QuickMenuItem(
            icon: Icons.shopping_cart_rounded,
            label: 'Cart',
            onTap: onCartTap,
          ),
          const SizedBox(height: 8),
          _QuickMenuItem(
            icon: Icons.receipt_long_rounded,
            label: 'Orders',
            onTap: onOrdersTap,
          ),
        ],
      ),
    );
  }
}

class _QuickMenuItem extends StatelessWidget {
  const _QuickMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFEFFFF8),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF16785B), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF7DA199)),
          ],
        ),
      ),
    ),
  );
}

class _CartLikePage extends StatelessWidget {
  const _CartLikePage({
    required this.title,
    required this.products,
    required this.bottom,
  });
  final String title;
  final List<Product> products;
  final Widget bottom;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProductStyles.background,
      body: SafeArea(
        child: Column(
          children: [
            _ProductHeader(
              title: title,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                itemBuilder: (context, index) => _CartItem(
                  product: products[index],
                  quantity: index == 1 ? 1 : 2,
                ),
                separatorBuilder: (_, _) => const SizedBox(height: 22),
                itemCount: products.length,
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: bottom,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItem extends StatelessWidget {
  const _CartItem({required this.product, required this.quantity});
  final Product product;
  final int quantity;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: ProductArt(product: product),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: ProductStyles.rowTitle),
                const SizedBox(height: 12),
                const Text('Description', style: ProductStyles.rowTitle),
                Text('${product.price} MMK', style: ProductStyles.price),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: _QuantitySelector(
                    quantity: quantity,
                    onMinus: () {},
                    onPlus: () {},
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.radio_button_checked_rounded, size: 34),
        ],
      ),
    );
  }
}

class _PaymentMethodSheet extends StatefulWidget {
  const _PaymentMethodSheet();
  @override
  State<_PaymentMethodSheet> createState() => _PaymentMethodSheetState();
}

class _PaymentMethodSheetState extends State<_PaymentMethodSheet> {
  String selected = 'KBZ Pay (K pay)';
  final methods = const [
    'Wave Money',
    'KBZ Pay (K pay)',
    'AYA Pay',
    'Bank Transfer',
    'Cash On Delivery',
  ];
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 24, 8, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Center(
                    child: Text(
                      'Payment Method',
                      style: ProductStyles.detailTitle,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 32),
                ),
              ],
            ),
            const Divider(),
            for (final method in methods)
              ListTile(
                leading: Container(
                  width: 64,
                  alignment: Alignment.center,
                  child: Text(
                    method.split(' ').first,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1F63FF),
                    ),
                  ),
                ),
                title: Text(method, style: ProductStyles.rowTitle),
                trailing: Icon(
                  selected == method
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 34,
                ),
                onTap: () => setState(() => selected = method),
              ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushReplacementNamed(PaymentQrPage.routeName),
                style: FilledButton.styleFrom(
                  backgroundColor: ProductStyles.green,
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutBottom extends StatelessWidget {
  const _CheckoutBottom({required this.buttonText, required this.onPressed});
  final String buttonText;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(
          children: [
            Text('Total (2 items)', style: ProductStyles.body),
            Spacer(),
            Text('8,000 MMK', style: ProductStyles.rowTitle),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(backgroundColor: ProductStyles.green),
            child: Text(buttonText),
          ),
        ),
      ],
    ),
  );
}

class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final cell = size.width / 13;
    for (var y = 0; y < 13; y++) {
      for (var x = 0; x < 13; x++) {
        if ((x * y + x + y) % 3 == 0 ||
            x < 3 && y < 3 ||
            x > 9 && y < 3 ||
            x < 3 && y > 9) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell * .86, cell * .86),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SlipPreview extends StatelessWidget {
  const _SlipPreview();
  @override
  Widget build(BuildContext context) => Container(
    width: 82,
    height: 82,
    color: const Color(0xFF0D55AA),
    alignment: Alignment.center,
    child: const Text(
      '8,000.00 Ks',
      style: TextStyle(color: Colors.white, fontSize: 10),
    ),
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.product,
    required this.status,
    required this.quantity,
  });
  final Product product;
  final String status;
  final int quantity;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 36),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: ProductArt(product: product),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: ProductStyles.rowTitle),
                const SizedBox(height: 14),
                const Text('Description', style: ProductStyles.rowTitle),
                Text('${product.price} MMK', style: ProductStyles.price),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Text(
                      status,
                      style: ProductStyles.body.copyWith(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 110,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: const ShapeDecoration(
                        color: Color(0xFFD9D9D9),
                        shape: StadiumBorder(),
                      ),
                      child: Text('$quantity', style: ProductStyles.rowTitle),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
