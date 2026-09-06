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
        _StaffMintHeader(
          title: 'Item Details',
          subtitle: item.name,
          icon: Icons.inventory_2_outlined,
        ),
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
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
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
                const SizedBox(height: 14),
                _InfoCard(
                  rows: [
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
                        child: FilledButton.icon(
                          key: ValueKey('stock-in-${item.id}'),
                          onPressed: () => _stockIn(context, item),
                          icon: const Icon(Icons.south_west_rounded),
                          label: const Text('Stock In'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          key: ValueKey('stock-out-${item.id}'),
                          onPressed: () => _stockOut(context, item),
                          icon: const Icon(Icons.north_east_rounded),
                          label: const Text('Stock Out'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF9A5B00),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _editItem(context, item),
                          child: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _requestRestock(context, item),
                          child: Text(
                            item.restockRequested
                                ? 'Update request'
                                : 'Restock',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      key: ValueKey('archive-${item.id}'),
                      onPressed: () => _archiveItem(context, item),
                      icon: const Icon(Icons.archive_outlined, color: _red),
                      label: const Text(
                        'Archive item',
                        style: TextStyle(color: _red),
                      ),
                    ),
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

Future<void> _archiveItem(BuildContext context, InventoryItem item) async {
  final reason = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Archive item?'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Archived items keep their history but leave the active list.',
              style: TextStyle(color: _muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reason,
              decoration: _input('Reason', Icons.notes_rounded),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _red),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Archive'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    StaffOperationsStore.instance.archiveItem(
      item,
      reason.text.trim().isEmpty ? 'No reason given' : reason.text.trim(),
    );
    if (context.mounted) {
      Navigator.pop(context);
      _notice(context, '${item.name} archived.');
    }
  }
  reason.dispose();
}
