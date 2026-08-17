import 'package:flutter/material.dart';

import 'pet_owner_clinic_page.dart';
import 'pet_owner_home_page.dart';
import 'pet_owner_nav_bar.dart';
import 'pet_owner_profile_page.dart';
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
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
          Align(
            alignment: Alignment.bottomCenter,
            child: PetOwnerNavBar(
              selectedItem: PetOwnerNavItem.shop,
              onPetsTap: () {
                Navigator.of(
                  context,
                ).pushReplacementNamed(PetOwnerHomePage.routeName);
              },
              onAppointmentsTap: () {
                Navigator.of(
                  context,
                ).pushReplacementNamed(PetOwnerClinicPage.routeName);
              },
              onProfileTap: () {
                Navigator.of(
                  context,
                ).pushReplacementNamed(PetOwnerProfilePage.routeName);
              },
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

class ProductDetailsPage extends StatelessWidget {
  const ProductDetailsPage({super.key});

  static const String routeName = '/product-details';

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
                          _DetailInfo(product: product),
                          const SizedBox(height: 16),
                          const _ReviewsPreview(),
                          const SizedBox(height: 32),
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
