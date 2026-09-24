part of 'staff_portal.dart';

class StaffInventoryDetailPage extends StatelessWidget {
  const StaffInventoryDetailPage({
    required this.item,
    this.canManage = true,
    super.key,
  });

  final InventoryItem item;
  final bool canManage;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    body: Column(
      children: [
        _StaffMintHeader(title: 'Item Details', subtitle: item.name),
        Expanded(
          child: AnimatedBuilder(
            animation: StaffOperationsStore.instance,
            builder: (context, _) => ListView(
              key: const ValueKey('staff-inventory-detail'),
              padding: const EdgeInsets.all(18),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: Row(
                    children: [
                      Container(
                        key: ValueKey('inventory-detail-image-${item.id}'),
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F5F4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        clipBehavior: Clip.antiAlias,
                        child: _inventoryImage(
                          item.imageAsset,
                          fit: BoxFit.contain,
                          fallback: Icon(
                            _categoryIcon(item.category),
                            size: 40,
                            color: const Color(0xFF9FB4AC),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/photos/logoandphoto/nways_love_logo.png',
                                  key: const ValueKey(
                                    'staff-product-detail-logo',
                                  ),
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.id} • ${item.category}',
                              style: const TextStyle(color: _muted),
                            ),
                            const SizedBox(height: 8),
                            _StockStatusBadge(item: item),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.productImages.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _StaffProductPhotoStrip(item: item),
                ],
                const SizedBox(height: 14),
                _InfoCard(
                  rows: [
                    ('Product ID', item.id),
                    (
                      'Category',
                      item.subcategory.isEmpty
                          ? item.category
                          : '${item.category} • ${item.subcategory}',
                    ),
                    ('Pet type', item.petType),
                    if (item.brand.isNotEmpty) ('Brand', item.brand),
                    if (item.description.isNotEmpty)
                      ('Description', item.description),
                    ('In stock', '${item.quantity} ${item.unit}'),
                    ('Low-stock level', '${item.reorderLevel} ${item.unit}'),
                    ('Selling price', '${_money(item.sellingPrice)} MMK'),
                    ('Purchase price', '${_money(item.purchasePrice)} MMK'),
                    ('Expiry', _shortDate(item.expiresOn)),
                    if (item.restockStatus.isNotEmpty)
                      (
                        'Restock',
                        '${item.restockStatus} (+${item.restockQuantity})',
                      ),
                  ],
                ),
                if (canManage) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _InventoryDetailAction(
                          key: ValueKey('stock-in-${item.id}'),
                          onPressed: () => _stockIn(context, item),
                          icon: Icons.south_west_rounded,
                          label: 'Stock In',
                          color: _green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InventoryDetailAction(
                          key: ValueKey('stock-out-${item.id}'),
                          onPressed: () => _stockOut(context, item),
                          icon: Icons.north_east_rounded,
                          label: 'Stock Out',
                          color: const Color(0xFF9A5B00),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _InventoryDetailAction(
                          key: ValueKey('edit-${item.id}'),
                          onPressed: () => _editItem(context, item),
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          color: const Color(0xFF2358A5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InventoryDetailAction(
                          key: ValueKey('delete-${item.id}'),
                          onPressed: () => _deleteItem(context, item),
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete',
                          color: _red,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _requestRestock(context, item),
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: Text(
                        item.restockRequested
                            ? 'Restock requested'
                            : 'Request restock',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text('Stock history', style: _sectionStyle),
                const SizedBox(height: 8),
                if (item.movements.isEmpty)
                  const _Callout(
                    icon: Icons.history_rounded,
                    text: 'No stock movements recorded yet.',
                  )
                else
                  for (final m in item.movements.reversed) ...[
                    _MovementTile(movement: m),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _InventoryDetailAction extends StatelessWidget {
  const _InventoryDetailAction({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    super.key,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
  );
}

class _StaffProductPhotoStrip extends StatelessWidget {
  const _StaffProductPhotoStrip({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final photos = item.productImages.take(3).toList();
    const labels = ['Main image', 'Package back', 'Product detail'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < photos.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _inventoryImage(
                        photos[index],
                        fit: BoxFit.contain,
                        fallback: const Icon(
                          Icons.image_not_supported_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: _muted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StockStatusBadge extends StatelessWidget {
  const _StockStatusBadge({required this.item});
  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final (label, color) = item.isExpired
        ? ('Expired', _red)
        : item.isOutOfStock
        ? ('Out of Stock', _red)
        : item.isLowStock
        ? ('Low Stock', const Color(0xFF9A5B00))
        : item.isNearExpiry
        ? ('Near Expiry', const Color(0xFF9A5B00))
        : ('In Stock', _green);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement});
  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final isIn = movement.type == 'Stock In';
    final color = isIn
        ? _green
        : movement.type == 'Stock Out'
        ? const Color(0xFF9A5B00)
        : const Color(0xFF2358A5);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(
              isIn ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${movement.type} ${isIn ? '+' : '-'}${movement.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${movement.reason} • ${movement.previousBalance} → ${movement.newBalance}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                Text(
                  '${movement.staff} • ${_shortDate(movement.at)}',
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stock In / Stock Out
// ---------------------------------------------------------------------------

Future<void> _stockIn(BuildContext context, InventoryItem item) =>
    showDialog<void>(
      context: context,
      builder: (_) => _StockMovementDialog(item: item, isStockIn: true),
    );

Future<void> _stockOut(BuildContext context, InventoryItem item) =>
    showDialog<void>(
      context: context,
      builder: (_) => _StockMovementDialog(item: item, isStockIn: false),
    );

/// A stateful dialog that owns its controllers so their lifecycle is safe.
class _StockMovementDialog extends StatefulWidget {
  const _StockMovementDialog({required this.item, required this.isStockIn});

  final InventoryItem item;
  final bool isStockIn;

  @override
  State<_StockMovementDialog> createState() => _StockMovementDialogState();
}

class _StockMovementDialogState extends State<_StockMovementDialog> {
  final _qty = TextEditingController();
  final _reference = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late String _reason = _stockOutReasons.first;

  @override
  void dispose() {
    _qty.dispose();
    _reference.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final store = StaffOperationsStore.instance;
    final quantity = int.parse(_qty.text.trim());
    String message;
    if (widget.isStockIn) {
      store.stockIn(widget.item, quantity, reference: _reference.text.trim());
      message = 'Stock received and recorded.';
    } else {
      final ok = store.stockOut(widget.item, quantity, reason: _reason);
      message = ok
          ? 'Stock issued and recorded.'
          : 'Not enough stock available.';
    }
    Navigator.pop(context);
    _notice(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return AlertDialog(
      title: Text(
        widget.isStockIn
            ? 'Receive stock (Stock In)'
            : 'Issue stock (Stock Out)',
      ),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available: ${item.quantity} ${item.unit}',
                  style: const TextStyle(color: _muted),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: ValueKey(
                    widget.isStockIn ? 'stock-in-qty' : 'stock-out-qty',
                  ),
                  controller: _qty,
                  keyboardType: TextInputType.number,
                  decoration: _input(
                    widget.isStockIn ? 'Received quantity' : 'Quantity',
                    Icons.numbers_rounded,
                  ),
                  validator: (value) {
                    final n = int.tryParse((value ?? '').trim());
                    if (n == null || n <= 0) return 'Enter a positive number';
                    if (!widget.isStockIn && n > item.quantity) {
                      return 'Not enough stock';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                if (widget.isStockIn)
                  TextFormField(
                    controller: _reference,
                    decoration: _input(
                      'Delivery reference (optional)',
                      Icons.receipt_long_outlined,
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _reason,
                    isExpanded: true,
                    decoration: _input('Reason', Icons.notes_rounded),
                    items: _stockOutReasons
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setState(() => _reason = v ?? _reason),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: ValueKey(
            widget.isStockIn ? 'confirm-stock-in' : 'confirm-stock-out',
          ),
          onPressed: _submit,
          child: Text(widget.isStockIn ? 'Add to stock' : 'Deduct stock'),
        ),
      ],
    );
  }
}

const _stockOutReasons = [
  'Used during treatment',
  'Sold to pet owner',
  'Transferred',
  'Damaged',
  'Expired',
  'Lost',
  'Quantity correction',
];

String? _positiveIntValidator(String? value) {
  final n = int.tryParse((value ?? '').trim());
  if (n == null || n <= 0) return 'Enter a positive number';
  return null;
}

Future<void> _deleteItem(BuildContext context, InventoryItem item) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete item?'),
      content: Text(
        '${item.name} and its stock history will be permanently deleted.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: ValueKey('confirm-delete-${item.id}'),
          style: FilledButton.styleFrom(backgroundColor: _red),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    StaffOperationsStore.instance.deleteItem(item);
    if (context.mounted) {
      Navigator.pop(context);
      _notice(context, '${item.name} deleted.');
    }
  }
}
