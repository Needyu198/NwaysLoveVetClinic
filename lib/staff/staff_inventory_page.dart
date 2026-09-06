part of 'staff_portal.dart';

class StaffInventoryPage extends StatefulWidget {
  const StaffInventoryPage({this.canAdjustStock = true, super.key});

  final bool canAdjustStock;

  @override
  State<StaffInventoryPage> createState() => _StaffInventoryPageState();
}

class _StaffInventoryPageState extends State<StaffInventoryPage> {
  String _query = '';
  String _category = 'All';
  String _stockFilter = 'All';

  bool _matches(InventoryItem item) {
    final q = _query.trim().toLowerCase();
    final matchesSearch =
        q.isEmpty ||
        '${item.id} ${item.name} ${item.category}'.toLowerCase().contains(q);
    final matchesCategory = _category == 'All' || item.category == _category;
    final matchesStock = switch (_stockFilter) {
      'In Stock' => !item.isLowStock,
      'Low Stock' => item.isLowStock && !item.isOutOfStock,
      'Out of Stock' => item.isOutOfStock,
      _ => true,
    };
    return matchesSearch && matchesCategory && matchesStock;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: AnimatedBuilder(
      animation: StaffOperationsStore.instance,
      builder: (context, _) {
        final all = StaffOperationsStore.instance.activeInventory;
        final items = all.where(_matches).toList();
        final lowCount = all.where((i) => i.isLowStock).length;
        final expiredCount = all.where((i) => i.isExpired).length;
        final nearExpiry = all
            .where((i) => i.isNearExpiry && !i.isExpired)
            .length;
        return Column(
          children: [
            const _InventoryHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _InventoryActionPill(
                      icon: Icons.search_rounded,
                      child: TextField(
                        key: const ValueKey('staff-inventory-search'),
                        onChanged: (v) => setState(() => _query = v),
                        decoration: const InputDecoration(
                          hintText: 'Search Items',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  if (widget.canAdjustStock)
                    _InventoryActionPill(
                      icon: Icons.add_rounded,
                      expand: false,
                      onTap: () =>
                          _push(context, const StaffAddInventoryPage()),
                      child: const Text(
                        'Add New Items',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (lowCount > 0 || expiredCount > 0 || nearExpiry > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: _InventoryAlert(
                        label: 'Low / Out',
                        value: '$lowCount',
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFFFFE3A8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InventoryAlert(
                        label: 'Near expiry',
                        value: '$nearExpiry',
                        icon: Icons.schedule_rounded,
                        color: const Color(0xFFFFE0B2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InventoryAlert(
                        label: 'Expired',
                        value: '$expiredCount',
                        icon: Icons.warning_amber_rounded,
                        color: const Color(0xFFFFC7C9),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: [
                  for (final c in [
                    'All',
                    ...StaffOperationsStore.inventoryCategories,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: _category == c,
                        selectedColor: _mint,
                        onSelected: (_) => setState(() => _category = c),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: [
                  for (final s in [
                    'All',
                    'In Stock',
                    'Low Stock',
                    'Out of Stock',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(s),
                        selected: _stockFilter == s,
                        selectedColor: const Color(0xFFCFE0FF),
                        onSelected: (_) => setState(() => _stockFilter = s),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('No matching inventory items'))
                  : GridView.builder(
                      key: const ValueKey('staff-inventory-list'),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.70,
                          ),
                      itemCount: items.length,
                      itemBuilder: (context, index) => _InventoryGridCard(
                        item: items[index],
                        onTap: () => _push(
                          context,
                          StaffInventoryDetailPage(
                            item: items[index],
                            canManage: widget.canAdjustStock,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    ),
  );
}

class _InventoryHeader extends StatelessWidget {
  const _InventoryHeader();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      color: _mint,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 18, 20),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.chevron_left_rounded, size: 28),
            ),
            const Icon(Icons.shopping_cart_outlined, size: 26, color: _ink),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inventory',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: _ink,
                    ),
                  ),
                  Text(
                    'Stock, alerts and restock requests',
                    style: TextStyle(color: Color(0xFF3B5249), fontSize: 13),
                  ),
                ],
              ),
            ),
            Image.asset(
              'assets/photos/logoandphoto/nways_love_logo.png',
              width: 52,
              height: 52,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    ),
  );
}

class _InventoryActionPill extends StatelessWidget {
  const _InventoryActionPill({
    required this.icon,
    required this.child,
    this.onTap,
    this.expand = true,
  });

  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF17C08B),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          if (expand)
            Expanded(child: child)
          else ...[
            child,
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: content,
    );
  }
}

class _InventoryAlert extends StatelessWidget {
  const _InventoryAlert({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 7),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _InventoryGridCard extends StatelessWidget {
  const _InventoryGridCard({required this.item, required this.onTap});
  final InventoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = item.isExpired
        ? ('Expired', _red)
        : item.isOutOfStock
        ? ('Out of stock', _red)
        : item.isLowStock
        ? ('Low stock', const Color(0xFF9A5B00))
        : ('In stock', _green);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 1.5,
      shadowColor: const Color(0x22000000),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('inventory-card-${item.id}'),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _InventoryImage(item: item),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: _InventoryStatusPill(
                        label: statusLabel,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 15,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.quantity} ${item.unit}',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            '${_money(item.sellingPrice)} MMK',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: _green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryStatusPill extends StatelessWidget {
  const _InventoryStatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _InventoryImage extends StatelessWidget {
  const _InventoryImage({required this.item});
  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF3F5F4),
      alignment: Alignment.center,
      child: _inventoryImage(
        item.imageAsset,
        fit: BoxFit.contain,
        fallback: _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Icon(
    _categoryIcon(item.category),
    size: 54,
    color: const Color(0xFF9FB4AC),
  );
}

/// Renders an inventory image whether it is a bundled asset path or a local
/// file path chosen by staff via the image picker.
Widget _inventoryImage(
  String? path, {
  required Widget fallback,
  BoxFit fit = BoxFit.cover,
}) {
  if (path == null) return fallback;
  if (path.startsWith('assets/')) {
    return Image.asset(
      path,
      fit: fit,
      errorBuilder: (context, error, stack) => fallback,
    );
  }
  return Image.file(
    File(path),
    fit: fit,
    errorBuilder: (context, error, stack) => fallback,
  );
}

IconData _categoryIcon(String category) => switch (category) {
  'Pet Food' => Icons.pets_rounded,
  'Medicine' => Icons.medication_rounded,
  'Vaccines' => Icons.vaccines_rounded,
  'Medical Supplies' => Icons.medical_information_outlined,
  'Cleaning Supplies' => Icons.cleaning_services_rounded,
  'Accessories' => Icons.shopping_bag_outlined,
  _ => Icons.inventory_2_outlined,
};

String _money(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
