part of 'staff_portal.dart';

class StaffInventoryPage extends StatefulWidget {
  const StaffInventoryPage({this.canAdjustStock = true, super.key});

  final bool canAdjustStock;

  @override
  State<StaffInventoryPage> createState() => _StaffInventoryPageState();
}

class _StaffInventoryPageState extends State<StaffInventoryPage> {
  String _query = '';
  String _filter = 'All';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    appBar: _appBar('Inventory'),
    body: AnimatedBuilder(
      animation: StaffOperationsStore.instance,
      builder: (context, _) {
        final all = StaffOperationsStore.instance.inventory;
        final lowCount = all.where((item) => item.isLowStock).length;
        final expiredCount = all.where((item) => item.isExpired).length;
        final items = all.where((item) {
          final matchesSearch = '${item.id} ${item.name} ${item.category}'
              .toLowerCase()
              .contains(_query.toLowerCase());
          final matchesFilter = switch (_filter) {
            'Low stock' => item.isLowStock,
            'Expired' => item.isExpired,
            'Medicine' || 'Supply' => item.category == _filter,
            _ => true,
          };
          return matchesSearch && matchesFilter;
        }).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _InventoryAlert(
                          label: 'Low stock',
                          value: '$lowCount',
                          icon: Icons.inventory_2_outlined,
                          color: const Color(0xFFFFE3A8),
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
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('staff-inventory-search'),
                    onChanged: (value) => setState(() => _query = value),
                    decoration: _input(
                      'Search medicine or supplies',
                      Icons.search_rounded,
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
                children: ['All', 'Medicine', 'Supply', 'Low stock', 'Expired']
                    .map(
                      (value) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(value),
                          selected: _filter == value,
                          selectedColor: _mint,
                          onSelected: (_) => setState(() => _filter = value),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('No matching inventory items'))
                  : ListView.separated(
                      key: const ValueKey('staff-inventory-list'),
                      padding: const EdgeInsets.all(18),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, index) => _InventoryCard(
                        item: items[index],
                        canAdjustStock: widget.canAdjustStock,
                        onAdjust: () => _adjustInventory(context, items[index]),
                        onRestock: () => _requestRestock(context, items[index]),
                      ),
                    ),
            ),
          ],
        );
      },
    ),
  );
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
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(icon),
        const SizedBox(width: 9),
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.item,
    required this.canAdjustStock,
    required this.onAdjust,
    required this.onRestock,
  });
  final InventoryItem item;
  final bool canAdjustStock;
  final VoidCallback onAdjust;
  final VoidCallback onRestock;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(
      border: item.isExpired
          ? _red
          : item.isLowStock
          ? const Color(0xFFE5A000)
          : _border,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: item.category == 'Medicine'
                    ? const Color(0xFFE6FAF2)
                    : const Color(0xFFE9E5FF),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                item.category == 'Medicine'
                    ? Icons.medication_rounded
                    : Icons.medical_information_outlined,
                color: _green,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${item.id} • ${item.category}',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  item.unit,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 11),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            if (item.isLowStock)
              const Chip(
                avatar: Icon(Icons.inventory_2_outlined, size: 16),
                label: Text('Low stock'),
                backgroundColor: Color(0xFFFFE3A8),
              ),
            if (item.isExpired)
              const Chip(
                avatar: Icon(Icons.warning_amber_rounded, size: 16),
                label: Text('Expired'),
                backgroundColor: Color(0xFFFFC7C9),
              ),
            if (item.restockRequested)
              Chip(
                avatar: const Icon(Icons.local_shipping_outlined, size: 16),
                label: Text('Requested +${item.restockQuantity}'),
                backgroundColor: const Color(0xFFCFE0FF),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Reorder at ${item.reorderLevel} • Expires ${_shortDate(item.expiresOn)}',
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        const Divider(height: 22),
        Row(
          children: [
            Expanded(
              flex: canAdjustStock ? 1 : 2,
              child: OutlinedButton.icon(
                onPressed: onRestock,
                icon: const Icon(Icons.local_shipping_outlined),
                label: Text(
                  item.restockRequested ? 'Update request' : 'Request restock',
                ),
              ),
            ),
            if (canAdjustStock) ...[
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  key: ValueKey('adjust-stock-${item.id}'),
                  onPressed: onAdjust,
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Adjust stock'),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Audit: ${item.lastAudit}',
          style: const TextStyle(color: _muted, fontSize: 10),
        ),
      ],
    ),
  );
}

Future<void> _adjustInventory(BuildContext context, InventoryItem item) async {
  var quantityText = '${item.quantity}';
  var reasonText = '';
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Adjust stock quantity'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Callout(
            icon: Icons.admin_panel_settings_outlined,
            text:
                'Direct stock changes are restricted to staff and administrators and always create an audit entry.',
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('inventory-quantity-field'),
            initialValue: quantityText,
            keyboardType: TextInputType.number,
            onChanged: (value) => quantityText = value,
            decoration: _input('New quantity', Icons.numbers_rounded),
          ),
          const SizedBox(height: 10),
          TextFormField(
            onChanged: (value) => reasonText = value,
            decoration: _input('Reason for adjustment', Icons.notes_rounded),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('confirm-stock-adjustment'),
          onPressed: () {
            final value = int.tryParse(quantityText);
            if (value == null || value < 0 || reasonText.trim().isEmpty) {
              return;
            }
            StaffOperationsStore.instance.adjustStock(
              item,
              value,
              reasonText.trim(),
            );
            Navigator.pop(dialogContext, true);
          },
          child: const Text('Save adjustment'),
        ),
      ],
    ),
  );
  if (saved == true && context.mounted) {
    _notice(context, 'Stock updated and audit entry recorded.');
  }
}

Future<void> _requestRestock(BuildContext context, InventoryItem item) async {
  var quantityText =
      '${item.restockQuantity > 0 ? item.restockQuantity : item.reorderLevel * 2}';
  var noteText = item.restockNote;
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Submit restock request'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            initialValue: quantityText,
            keyboardType: TextInputType.number,
            onChanged: (value) => quantityText = value,
            decoration: _input('Requested quantity', Icons.add_box_outlined),
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: noteText,
            maxLines: 2,
            onChanged: (value) => noteText = value,
            decoration: _input('Note (optional)', Icons.notes_rounded),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = int.tryParse(quantityText);
            if (value == null || value <= 0) return;
            StaffOperationsStore.instance.requestRestock(
              item,
              value,
              noteText.trim(),
            );
            Navigator.pop(dialogContext, true);
          },
          child: const Text('Submit request'),
        ),
      ],
    ),
  );
  if (saved == true && context.mounted) {
    _notice(context, 'Restock request submitted for approval.');
  }
}
