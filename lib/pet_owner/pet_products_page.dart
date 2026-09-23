import 'dart:convert';
import 'dart:typed_data';

import '../data/clinic_api.dart';
import '../staff/staff_portal.dart';
import 'package:flutter/material.dart';

import 'pet_owner_clinic_page.dart';
import 'pet_owner_home_page.dart';
import 'pet_owner_nav_bar.dart';
import 'pet_owner_profile_page.dart';
import 'pet_owner_page_header.dart';
import 'pet_product_styles.dart';

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
      case 'Discount':
        filtered.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
      case 'Newest':
        filtered.sort((a, b) => b.stock.compareTo(a.stock));
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
                  title: 'Pet Products',
                  logoKey: const ValueKey('pet-products-logo'),
                  onLogoTap: () => Navigator.of(
                    context,
                  ).pushReplacementNamed(PetOwnerHomePage.routeName),
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Recommended Products',
                      key: ValueKey('recommended-products-title'),
                      style: ProductStyles.sectionTitle,
                    ),
                  ),
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
                                childAspectRatio: 0.62,
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
                children:
                    ['Popular', 'Newest', 'Price Low', 'Price High', 'Discount']
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
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
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
                          const SizedBox(height: 14),
                          KeyedSubtree(
                            key: const ValueKey('product-detail-stock'),
                            child: _StockPill(stock: product.stock),
                          ),
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
                          const SizedBox(height: 24),
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

// ---------------------------------------------------------------------------
// Product model + data source (real inventory)
// ---------------------------------------------------------------------------

class Product {
  const Product({
    required this.name,
    required this.category,
    required this.brand,
    required this.price,
    required this.originalPrice,
    required this.stock,
    required this.description,
    required this.petType,
    required this.weight,
    required this.color,
    required this.icon,
    this.imageAsset,
    this.photoUrl = '',
    this.imageUrls = const [],
    this.subcategory = '',
  });

  final String name;
  final String category;
  final String brand;
  final int price;
  final int originalPrice;
  final int stock;
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

  List<String> get galleryImages {
    if (imageUrls.isNotEmpty) return imageUrls;
    if (photoUrl.isNotEmpty) return [photoUrl];
    if ((imageAsset ?? '').isNotEmpty) return [imageAsset!];
    return const [];
  }

  int get discountPercent {
    if (originalPrice <= 0 || originalPrice <= price) return 0;
    return (((originalPrice - price) / originalPrice) * 100).round();
  }
}

/// Deterministic display "original price" so a product's discount badge is
/// stable per product (derived from its real selling price, not random).
int _originalPriceFor(String key, int sellingPrice) {
  if (sellingPrice <= 0) return 0;
  // 5%..25% markup based on a stable hash of the product identity.
  final pct = 5 + (key.hashCode.abs() % 21);
  return (sellingPrice * (100 + pct) / 100).round();
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
              name: item.name,
              category: _normalizedProductCategory(item.category),
              subcategory: item.subcategory,
              brand: item.brand.isNotEmpty
                  ? item.brand
                  : item.supplier.isEmpty
                  ? 'Clinic Shop'
                  : item.supplier,
              price: item.sellingPrice,
              originalPrice: _originalPriceFor(item.id, item.sellingPrice),
              stock: item.quantity,
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
            ),
          )
          .toList();

const _demoProducts = <Product>[
  Product(
    name: 'Dog Food 01',
    category: 'Food',
    brand: 'Pedigree',
    price: 4000,
    originalPrice: 4600,
    stock: 24,
    description: 'Balanced nutrition dry food for adult dogs.',
    petType: 'Dog',
    weight: '1 kg',
    color: Color(0xFFFFD329),
    icon: Icons.pets_rounded,
  ),
  Product(
    name: 'Cat Food 01',
    category: 'Food',
    brand: 'Meow Mix',
    price: 4000,
    originalPrice: 5000,
    stock: 14,
    description: 'Original choice cat food with balanced nutrition.',
    petType: 'Cat',
    weight: '800 g',
    color: Color(0xFFFFC83D),
    icon: Icons.cruelty_free_rounded,
  ),
  Product(
    name: 'Dog Food 02',
    category: 'Food',
    brand: 'Pedigree',
    price: 6000,
    originalPrice: 6600,
    stock: 16,
    description: 'Adult dog food with chicken and vegetable flavor.',
    petType: 'Dog',
    weight: '10 kg',
    color: Color(0xFFD72D39),
    icon: Icons.pets_rounded,
  ),
  Product(
    name: 'Dog Toy',
    category: 'Accessories',
    brand: 'Nway',
    price: 5000,
    originalPrice: 5800,
    stock: 20,
    description: 'Soft chew toy for play and exercise.',
    petType: 'Dog',
    weight: 'M',
    color: Color(0xFF5DA7FF),
    icon: Icons.toys_rounded,
  ),
];

const categories = ['All Product', 'Food', 'Medicine', 'Accessories'];

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
          final imageAsset = _categoryIconAsset(category);
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
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          formatMmk(product.price),
                          style: const TextStyle(
                            color: ProductStyles.red,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (product.discountPercent > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '-${product.discountPercent}%',
                          style: const TextStyle(
                            color: ProductStyles.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  _StockPill(stock: product.stock),
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

  @override
  Widget build(BuildContext context) {
    final images = widget.product.galleryImages;
    if (images.length <= 1) {
      return ProductArt(product: widget.product, large: true);
    }
    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          PageView.builder(
            key: const ValueKey('product-image-gallery'),
            itemCount: images.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (_, index) => ProductArt(
              product: widget.product,
              large: true,
              imageSource: images[index],
            ),
          ),
          Positioned(
            right: 14,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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

class _StockPill extends StatelessWidget {
  const _StockPill({required this.stock});
  final int stock;

  @override
  Widget build(BuildContext context) {
    final inStock = stock > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: inStock ? const Color(0xFFE8FFF5) : const Color(0xFFFFE9E5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        inStock ? 'In stock: $stock' : 'Out of stock',
        style: TextStyle(
          color: inStock ? const Color(0xFF16785B) : const Color(0xFFCE3D2E),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail page widgets
// ---------------------------------------------------------------------------

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
