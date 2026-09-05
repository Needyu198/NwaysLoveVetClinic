part of 'doctor_portal.dart';

class DoctorInventoryPage extends StatefulWidget {
  const DoctorInventoryPage({super.key});

  @override
  State<DoctorInventoryPage> createState() => _DoctorInventoryPageState();
}

class _DoctorInventoryPageState extends State<DoctorInventoryPage> {
  final _search = TextEditingController();
  var _filter = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const _DoctorSubpageHeader(title: 'Inventory'),
          Expanded(
            child: AnimatedBuilder(
              animation: StaffOperationsStore.instance,
              builder: (context, _) {
                final all = StaffOperationsStore.instance.inventory;
                final query = _search.text.trim().toLowerCase();
                final items = all.where((item) {
                  final matchesQuery =
                      query.isEmpty ||
                      '${item.id} ${item.name} ${item.category}'
                          .toLowerCase()
                          .contains(query);
                  final matchesFilter = switch (_filter) {
                    'Low Stock' => item.isLowStock,
                    'Expired' => item.isExpired,
                    'Medicine' || 'Supply' => item.category == _filter,
                    _ => true,
                  };
                  return matchesQuery && matchesFilter;
                }).toList();
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _DoctorInventorySummary(
                              icon: Icons.inventory_2_outlined,
                              value:
                                  '${all.where((item) => item.isLowStock).length}',
                              label: 'Low Stock',
                              urgent: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DoctorInventorySummary(
                              icon: Icons.warning_amber_rounded,
                              value:
                                  '${all.where((item) => item.isExpired).length}',
                              label: 'Expired',
                              urgent: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DoctorInventorySummary(
                              icon: Icons.medication_outlined,
                              value: '${all.length}',
                              label: 'Items',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: TextField(
                        key: const ValueKey('doctor-inventory-search'),
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search medicine or supplies',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: DoctorStyles.green,
                          ),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _search.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          filled: true,
                          fillColor: DoctorStyles.softMint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 43,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children:
                            [
                                  'All',
                                  'Medicine',
                                  'Supply',
                                  'Low Stock',
                                  'Expired',
                                ]
                                .map(
                                  (value) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(value),
                                      selected: _filter == value,
                                      selectedColor: DoctorStyles.mint,
                                      backgroundColor: DoctorStyles.softMint,
                                      side: BorderSide.none,
                                      labelStyle: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                      onSelected: (_) =>
                                          setState(() => _filter = value),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                    Expanded(
                      child: items.isEmpty
                          ? const _EmptyDoctorState(
                              icon: Icons.inventory_2_outlined,
                              title: 'No inventory items found',
                              message:
                                  'Try another search or inventory filter.',
                            )
                          : ListView.separated(
                              key: const ValueKey('doctor-inventory-list'),
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                14,
                                20,
                                30,
                              ),
                              itemCount: items.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (_, index) => _DoctorInventoryCard(
                                item: items[index],
                                onRestock: () => _doctorRequestRestock(
                                  context,
                                  items[index],
                                ),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _DoctorInventorySummary extends StatelessWidget {
  const _DoctorInventorySummary({
    required this.icon,
    required this.value,
    required this.label,
    this.urgent = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool urgent;

  @override
  Widget build(BuildContext context) => Container(
    height: 88,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: urgent
          ? DoctorStyles.emergencyRed.withValues(alpha: 0.12)
          : DoctorStyles.mint,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: urgent ? DoctorStyles.emergencyRed : DoctorStyles.green,
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                color: urgent ? DoctorStyles.emergencyRed : DoctorStyles.ink,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          label,
          maxLines: 1,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _DoctorInventoryCard extends StatelessWidget {
  const _DoctorInventoryCard({required this.item, required this.onRestock});

  final InventoryItem item;
  final VoidCallback onRestock;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: DoctorStyles.mint,
      borderRadius: BorderRadius.circular(30),
      boxShadow: const [
        BoxShadow(
          color: Color(0x26000000),
          blurRadius: 7,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: Icon(
                item.category == 'Medicine'
                    ? Icons.medication_rounded
                    : Icons.medical_information_outlined,
                color: DoctorStyles.green,
                size: 28,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.id} • ${item.category}',
                    style: DoctorStyles.muted,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${item.quantity}', style: DoctorStyles.stat),
                Text(item.unit, style: DoctorStyles.small),
              ],
            ),
          ],
        ),
        const SizedBox(height: 13),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Reorder at ${item.reorderLevel}\nExpires ${_doctorInventoryDate(item.expiresOn)}',
                  style: DoctorStyles.muted,
                ),
              ),
              if (item.isExpired)
                const _DoctorInventoryBadge(
                  label: 'Expired',
                  color: DoctorStyles.emergencyRed,
                )
              else if (item.isLowStock)
                const _DoctorInventoryBadge(
                  label: 'Low Stock',
                  color: Color(0xFFB76E00),
                )
              else
                const _DoctorInventoryBadge(
                  label: 'In Stock',
                  color: DoctorStyles.green,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: ValueKey('doctor-restock-${item.id}'),
            onPressed: onRestock,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(46),
              shape: const StadiumBorder(),
            ),
            icon: Icon(
              item.restockRequested
                  ? Icons.task_alt_rounded
                  : Icons.local_shipping_outlined,
            ),
            label: Text(
              item.restockRequested
                  ? 'Restock Requested (+${item.restockQuantity})'
                  : 'Request Restock',
            ),
          ),
        ),
      ],
    ),
  );
}

class _DoctorInventoryBadge extends StatelessWidget {
  const _DoctorInventoryBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
    ),
  );
}

Future<void> _doctorRequestRestock(
  BuildContext context,
  InventoryItem item,
) async {
  var quantity =
      '${item.restockQuantity > 0 ? item.restockQuantity : item.reorderLevel * 2}';
  var note = item.restockNote;
  final submitted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text(
        'Request Restock',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name, style: DoctorStyles.cardTitle),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: quantity,
            keyboardType: TextInputType.number,
            onChanged: (value) => quantity = value,
            decoration: _doctorInventoryInput('Requested quantity'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: note,
            maxLines: 2,
            onChanged: (value) => note = value,
            decoration: _doctorInventoryInput('Reason or note'),
          ),
          const SizedBox(height: 12),
          const Text(
            'A staff member or administrator must approve and update stock.',
            style: DoctorStyles.muted,
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
            final requested = int.tryParse(quantity);
            if (requested == null || requested <= 0) return;
            StaffOperationsStore.instance.requestRestock(
              item,
              requested,
              note.trim(),
            );
            Navigator.pop(dialogContext, true);
          },
          style: FilledButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          child: const Text('Submit Request'),
        ),
      ],
    ),
  );
  if (submitted == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restock request sent to clinic staff.')),
    );
  }
}

InputDecoration _doctorInventoryInput(String label) => InputDecoration(
  labelText: label,
  filled: true,
  fillColor: DoctorStyles.softMint,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide.none,
  ),
);

String _doctorInventoryDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
