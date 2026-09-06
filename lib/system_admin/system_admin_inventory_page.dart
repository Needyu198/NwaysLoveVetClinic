part of 'system_admin_portal.dart';

/// Inventory approval: lists pending restock requests raised by staff, opens a
/// request detail with stock history, and Approve / Partial / Reject actions.
class AdminInventoryPage extends StatelessWidget {
  const AdminInventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const _AdminPageHeader(
            title: 'Inventory Approval',
            subtitle: 'Restock and adjustment requests',
            icon: Icons.inventory_2_rounded,
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: StaffOperationsStore.instance,
              builder: (context, _) {
                final requests = StaffOperationsStore.instance.inventory
                    .where((item) => item.restockRequested)
                    .toList();
                if (requests.isEmpty) {
                  return const _AdminEmptyState(
                    icon: Icons.inventory_rounded,
                    title: 'No pending requests',
                    message: 'Restock requests from staff appear here.',
                  );
                }
                return ListView(
                  key: const ValueKey('admin-inventory-list'),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                  children: [
                    for (final item in requests) ...[
                      _AdminRequestCard(
                        item: item,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AdminInventoryRequestPage(item: item),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminRequestCard extends StatelessWidget {
  const _AdminRequestCard({required this.item, required this.onTap});

  final InventoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _adminBorder),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: _adminSoftMint,
              foregroundColor: _adminGreen,
              child: Icon(Icons.inventory_2_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Requested ${item.restockQuantity} ${item.unit} • '
                    'have ${item.quantity}',
                    style: const TextStyle(color: _adminMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _AdminStatusBadge(
              label: item.restockStatus.isEmpty
                  ? 'Pending Approval'
                  : item.restockStatus,
              color: _statusColorFor(item.restockStatus),
            ),
          ],
        ),
      ),
    ),
  );
}

Color _statusColorFor(String status) => switch (status) {
  'Approved' => _adminGreen,
  'Partially Approved' => const Color(0xFF2358A5),
  'Rejected' => const Color(0xFFB3261E),
  _ => const Color(0xFF9A5B00),
};

/// Detail for a single restock request with stock history and decisions.
class AdminInventoryRequestPage extends StatelessWidget {
  const AdminInventoryRequestPage({required this.item, super.key});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: StaffOperationsStore.instance,
        builder: (context, _) {
          final decided = const {
            'Approved',
            'Partially Approved',
            'Rejected',
          }.contains(item.restockStatus);
          return Column(
            children: [
              _AdminPageHeader(
                title: item.name,
                subtitle: 'Restock request',
                icon: Icons.inventory_2_rounded,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                  children: [
                    Center(
                      child: _AdminStatusBadge(
                        label: item.restockStatus.isEmpty
                            ? 'Pending Approval'
                            : item.restockStatus,
                        color: _statusColorFor(item.restockStatus),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AdminInfoCard(
                      rows: [
                        ('Item', '${item.name} (${item.id})'),
                        ('Category', item.category),
                        ('Available stock', '${item.quantity} ${item.unit}'),
                        ('Requested', '${item.restockQuantity} ${item.unit}'),
                        ('Reorder level', '${item.reorderLevel} ${item.unit}'),
                        ('Supplier', item.supplier.isEmpty ? '—' : item.supplier),
                        ('Expiry', _shortDay(item.expiresOn)),
                      ],
                    ),
                    if (item.restockNote.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _AdminAlertTile(
                        icon: Icons.sticky_note_2_rounded,
                        color: const Color(0xFF9A5B00),
                        title: 'Staff note',
                        message: item.restockNote,
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text('Stock history', style: _adminHeroStyle),
                    const SizedBox(height: 10),
                    if (item.movements.isEmpty)
                      const _AdminEmptyState(
                        icon: Icons.history_rounded,
                        title: 'No movements yet',
                        message: 'Stock transactions will show here.',
                      )
                    else
                      for (final movement in item.movements.reversed.take(8))
                        _AdminMovementRow(movement: movement),
                    const SizedBox(height: 22),
                    if (!decided) ...[
                      FilledButton.icon(
                        key: const ValueKey('admin-approve-restock'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _adminGreen,
                          minimumSize: const Size.fromHeight(52),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () => _approve(context),
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Approve full quantity'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2358A5),
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: Color(0xFF2358A5)),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () => _partial(context),
                        icon: const Icon(Icons.exposure_rounded),
                        label: const Text('Partially approve'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB3261E),
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: Color(0xFFB3261E)),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () => _reject(context),
                        icon: const Icon(Icons.cancel_rounded),
                        label: const Text('Reject request'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _approve(BuildContext context) async {
    final reason = await _adminReasonDialog(
      context,
      title: 'Approve ${item.restockQuantity} ${item.unit}?',
      actionLabel: 'Approve',
    );
    if (reason == null || !context.mounted) return;
    item.restockStatus = 'Approved';
    item.lastAudit = 'Restock approved • Mr. Admin • ${_shortDay(DateTime.now())}';
    StaffOperationsStore.instance.notifyChanged();
    AuditLogStore.instance.record(
      action: 'Approved restock',
      module: 'Inventory Approval',
      record: '${item.name} (${item.id})',
      previousValue: 'Pending Approval',
      newValue: 'Approved • ${item.restockQuantity} ${item.unit}',
      reason: reason,
    );
    _adminNotice(context, '${item.name} restock approved.');
    Navigator.of(context).pop();
  }

  Future<void> _partial(BuildContext context) async {
    final result = await showDialog<(int, String)>(
      context: context,
      builder: (_) => _AdminPartialApprovalDialog(item: item),
    );
    if (result == null || !context.mounted) return;
    item.restockStatus = 'Partially Approved';
    item.restockQuantity = result.$1;
    item.lastAudit =
        'Partial restock (${result.$1}) • Mr. Admin • ${_shortDay(DateTime.now())}';
    StaffOperationsStore.instance.notifyChanged();
    AuditLogStore.instance.record(
      action: 'Partially approved restock',
      module: 'Inventory Approval',
      record: '${item.name} (${item.id})',
      previousValue: 'Pending Approval',
      newValue: 'Partially Approved • ${result.$1} ${item.unit}',
      reason: result.$2,
    );
    _adminNotice(context, '${item.name} partially approved.');
    Navigator.of(context).pop();
  }

  Future<void> _reject(BuildContext context) async {
    final reason = await _adminReasonDialog(
      context,
      title: 'Reject restock for ${item.name}?',
      actionLabel: 'Reject',
      actionColor: const Color(0xFFB3261E),
    );
    if (reason == null || !context.mounted) return;
    item.restockStatus = 'Rejected';
    item.restockRequested = false;
    item.lastAudit = 'Restock rejected • Mr. Admin • ${_shortDay(DateTime.now())}';
    StaffOperationsStore.instance.notifyChanged();
    AuditLogStore.instance.record(
      action: 'Rejected restock',
      module: 'Inventory Approval',
      record: '${item.name} (${item.id})',
      previousValue: 'Pending Approval',
      newValue: 'Rejected',
      reason: reason,
    );
    _adminNotice(context, '${item.name} restock rejected.');
    Navigator.of(context).pop();
  }
}

class _AdminMovementRow extends StatelessWidget {
  const _AdminMovementRow({required this.movement});

  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final isIn = movement.type == 'Stock In';
    final color = isIn ? _adminGreen : const Color(0xFFB3261E);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _adminBorder),
      ),
      child: Row(
        children: [
          Icon(
            isIn ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${movement.type} • ${movement.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  movement.reason,
                  style: const TextStyle(color: _adminMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${movement.previousBalance} → ${movement.newBalance}',
            style: const TextStyle(color: _adminMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AdminPartialApprovalDialog extends StatefulWidget {
  const _AdminPartialApprovalDialog({required this.item});

  final InventoryItem item;

  @override
  State<_AdminPartialApprovalDialog> createState() =>
      _AdminPartialApprovalDialogState();
}

class _AdminPartialApprovalDialogState
    extends State<_AdminPartialApprovalDialog> {
  late final TextEditingController _quantity = TextEditingController(
    text: '${widget.item.restockQuantity}',
  );
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _quantity.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Partial approval'),
    content: SizedBox(
      width: 320,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _quantity,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Approved quantity',
                helperText: 'Requested ${widget.item.restockQuantity} '
                    '${widget.item.unit}',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2358A5)),
        onPressed: _confirm,
        child: const Text('Approve'),
      ),
    ],
  );

  void _confirm() {
    final value = int.tryParse(_quantity.text.trim());
    if (value == null || value <= 0 || value > widget.item.restockQuantity) {
      setState(
        () => _error = 'Enter 1 – ${widget.item.restockQuantity}',
      );
      return;
    }
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = 'A reason is required');
      return;
    }
    Navigator.of(context).pop((value, _reason.text.trim()));
  }
}
