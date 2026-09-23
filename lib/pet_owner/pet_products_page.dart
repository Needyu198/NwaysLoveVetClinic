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
  });

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
