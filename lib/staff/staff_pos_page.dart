part of 'staff_portal.dart';

class StaffPosPage extends StatefulWidget {
  const StaffPosPage({super.key});

  @override
  State<StaffPosPage> createState() => _StaffPosPageState();
}

class _StaffPosPageState extends State<StaffPosPage> {
  final _search = TextEditingController();
  final Map<String, _PosCartLine> _cart = {};
  String _category = 'All';
  bool _submitting = false;
  List<Map<String, dynamic>> _recentSales = [];

  int get _itemCount =>
      _cart.values.fold(0, (sum, line) => sum + line.quantity);
  int get _total => _cart.values.fold(
    0,
    (sum, line) => sum + line.item.sellingPrice * line.quantity,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_loadRecentSales());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<InventoryItem> get _visibleItems {
    final query = _search.text.trim().toLowerCase();
    return StaffOperationsStore.instance.activeInventory.where((item) {
      final matchesQuery =
          query.isEmpty ||
          '${item.name} ${item.id} ${item.barcode} ${item.brand}'
              .toLowerCase()
              .contains(query);
      return matchesQuery && (_category == 'All' || item.category == _category);
    }).toList();
  }

  Future<void> _loadRecentSales() async {
    try {
      final response = await ClinicApi.instance.request(
        'GET',
        '/data/product_orders',
      );
      final records =
          (response['records'] as List? ?? const [])
              .whereType<Map>()
              .map((record) => Map<String, dynamic>.from(record))
              .map(
                (record) => Map<String, dynamic>.from(
                  record['data'] as Map? ?? const {},
                ),
              )
              .map(
                (data) => Map<String, dynamic>.from(
                  data['value'] as Map? ?? const {},
                ),
              )
              .where((order) => order['source'] == 'POS')
              .toList()
            ..sort(
              (a, b) => (b['createdAt'] as String? ?? '').compareTo(
                a['createdAt'] as String? ?? '',
              ),
            );
      if (mounted) setState(() => _recentSales = records.take(8).toList());
    } on Object {
      // The POS itself remains available if loading the recent list fails.
    }
  }

  void _add(InventoryItem item) {
    final available = item.availableUnexpiredQuantity;
    if (item.sellingPrice <= 0) {
      _notice(
        context,
        'Set a selling price for ${item.name} before selling it.',
      );
      return;
    }
    if (available <= (_cart[item.id]?.quantity ?? 0)) {
      _notice(
        context,
        'No more unexpired stock is available for ${item.name}.',
      );
      return;
    }
    setState(
      () => _cart.update(item.id, (line) {
        line.quantity += 1;
        return line;
      }, ifAbsent: () => _PosCartLine(item)),
    );
  }

  void _changeQuantity(String itemId, int next) {
    final line = _cart[itemId];
    if (line == null) return;
    if (next <= 0) {
      setState(() => _cart.remove(itemId));
      return;
    }
    if (next > line.item.availableUnexpiredQuantity) {
      _notice(context, 'That quantity is higher than the available stock.');
      return;
    }
    setState(() => line.quantity = next);
  }

  void _scanOrSearch(String value) {
    final item = StaffOperationsStore.instance.findByBarcode(value);
    if (item == null) return;
    _add(item);
    _search.clear();
    setState(() {});
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _ProductBarcodeScannerPage()),
    );
    if (barcode == null || !mounted) return;
    final item = StaffOperationsStore.instance.findByBarcode(barcode);
    if (item == null) {
      _notice(context, 'No inventory item matches barcode "$barcode".');
      return;
    }
    _add(item);
    _search.clear();
    setState(() {});
  }

  Future<Map<String, String>?> _checkoutDetails() async {
    final customer = TextEditingController(text: 'Walk-in customer');
    final phone = TextEditingController();
    var method = 'Cash';
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: const Text('Checkout'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: customer,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Customer name (optional)',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Payment method',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Cash',
                      label: Text('Cash'),
                      icon: Icon(Icons.payments_outlined),
                    ),
                    ButtonSegment(
                      value: 'MMQR',
                      label: Text('KBZPay QR'),
                      icon: Icon(Icons.qr_code_rounded),
                    ),
                  ],
                  selected: {method},
                  onSelectionChanged: (selection) =>
                      dialogSetState(() => method = selection.first),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(child: Text('Due now')),
                    Text(
                      _formatPosMmk(_total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, {
                'customer': customer.text.trim().isEmpty
                    ? 'Walk-in customer'
                    : customer.text.trim(),
                'phone': phone.text.trim(),
                'method': method,
              }),
              child: const Text('Create sale'),
            ),
          ],
        ),
      ),
    );
    customer.dispose();
    phone.dispose();
    return result;
  }

  Future<void> _checkout() async {
    if (_submitting || _cart.isEmpty) return;
    final details = await _checkoutDetails();
    if (details == null || !mounted) return;
    final saleId = 'POS-${DateTime.now().microsecondsSinceEpoch}';
    final amountBeforeSave = _total;
    final order = <String, dynamic>{
      'id': saleId,
      'source': 'POS',
      'createdAt': DateTime.now().toIso8601String(),
      'items': [
        for (final line in _cart.values)
          {
            'inventoryId': line.item.id,
            'name': line.item.name,
            'unitPrice': line.item.sellingPrice,
            'quantity': line.quantity,
          },
      ],
      'total': amountBeforeSave,
      'ownerName': details['customer'],
      'ownerPhone': details['phone'],
      'fulfillment': 'Counter sale',
      'paymentTiming': 'Pay at clinic',
      'paymentMethod': details['method'],
      'status': 'Pending Payment',
    };
    setState(() => _submitting = true);
    try {
      final response = await ClinicApi.instance.request(
        'POST',
        '/data/product_orders/sync',
        {
          'changes': [
            {
              'id': '${ClinicApi.instance.accountId}:$saleId',
              'version': 0,
              'data': {'key': saleId, 'value': order},
            },
          ],
          'deletions': const [],
        },
      );
      final records = response['records'] as List? ?? const [];
      if (records.isEmpty || records.first is! Map) {
        throw ClinicApiException('The sale was not saved. Please retry.');
      }
      final data = Map<String, dynamic>.from(records.first['data'] as Map);
      final saved = Map<String, dynamic>.from(data['value'] as Map);
      setState(_cart.clear);
      await DatabaseSync.instance.refreshTables([
        'inventory',
        'product_orders',
        'payments',
      ]);
      await _loadRecentSales();
      if (details['method'] == 'Cash') {
        await _collectCash(saved);
      } else {
        await _showMmqr(saved);
      }
    } on ClinicApiException catch (error) {
      if (mounted) _showInfo(context, 'Sale not completed', error.message);
    } on Object catch (error) {
      if (mounted) {
        _showInfo(
          context,
          'Sale not completed',
          'Could not confirm the sale with the clinic server. $error',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _collectCash(Map<String, dynamic> order) async {
    final amount = (order['total'] as num? ?? 0).toInt();
    final paymentId = order['paymentId'] as String? ?? 'PAY-${order['id']}';
    final tenderController = TextEditingController(text: '$amount');
    final cashDialog = DialogRoute<int>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Collect cash'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount due: ${_formatPosMmk(amount)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tenderController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cash received (MMK)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Collect later'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              int.tryParse(tenderController.text.trim()) ?? -1,
            ),
            child: const Text('Confirm cash'),
          ),
        ],
      ),
    );
    final tendered = await Navigator.of(
      context,
      rootNavigator: true,
    ).push(cashDialog);
    await cashDialog.completed;
    tenderController.dispose();
    if (!mounted) return;
    if (tendered == null) {
      _notice(context, 'Sale ${order['id']} is saved with payment still due.');
      return;
    }
    if (tendered < amount) {
      _notice(
        context,
        'Cash received is below the amount due. Sale is saved as unpaid.',
      );
      return;
    }
    try {
      final response = await ClinicApi.instance.request(
        'POST',
        '/payments/${Uri.encodeComponent(paymentId)}/cash/collect',
        {'tenderedAmount': tendered, 'receiptReference': order['id']},
      );
      final record = Map<String, dynamic>.from(response['record'] as Map);
      final payment = Map<String, dynamic>.from(record['data']['value'] as Map);
      final settlement = Map<String, dynamic>.from(
        payment['settlement'] as Map? ?? const {},
      );
      final receipt = Map<String, dynamic>.from(
        payment['receipt'] as Map? ?? const {},
      );
      await DatabaseSync.instance.refreshTables([
        'inventory',
        'product_orders',
        'payments',
      ]);
      await _loadRecentSales();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded, color: _green, size: 42),
          title: const Text('Sale complete'),
          content: Text(
            'Sale ${order['id']}\n'
            'Total: ${_formatPosMmk(amount)}\n'
            'Change: ${_formatPosMmk((settlement['changeAmount'] as num? ?? 0).toInt())}\n'
            'Receipt: ${receipt['receiptNumber'] ?? 'saved'}',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } on ClinicApiException catch (error) {
      if (mounted) {
        _showInfo(
          context,
          'Payment still due',
          'Sale ${order['id']} is saved. ${error.message}',
        );
      }
    }
  }

  Future<void> _showMmqr(Map<String, dynamic> order) async {
    final mmqr = Map<String, dynamic>.from(order['mmqr'] as Map? ?? const {});
    final paymentId = order['paymentId'] as String? ?? 'PAY-${order['id']}';
    if (mmqr.isEmpty) {
      _showInfo(
        context,
        'Sale saved',
        'Sale ${order['id']} is awaiting payment. Open Billing & Payments to create its QR.',
      );
      return;
    }
    try {
      await ClinicApi.instance.request(
        'POST',
        '/payments/${Uri.encodeComponent(paymentId)}/mmqr/displayed',
      );
    } on Object {
      // Display the already-created QR even if the view event cannot be saved.
    }
    final expiry =
        DateTime.tryParse(mmqr['expiresAt'] as String? ?? '') ??
        DateTime.now().add(const Duration(minutes: 15));
    final amount = (order['total'] as num? ?? 0).toInt();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan to pay'),
        content: SizedBox(
          width: 330,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatPosMmk(amount),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                PaymentQr(
                  amount: amount,
                  imageDataUrl: mmqr['qrImageDataUrl'] as String? ?? '',
                  expiresAt: expiry,
                  personalRecipient: mmqr['providerMode'] == 'kbzpay_personal'
                      ? mmqr['recipientLabel'] as String?
                      : null,
                  useTemporaryImage:
                      mmqr['providerMode'] == 'kbzpay_personal' &&
                      amount == temporaryPersonalPaymentQrAmount,
                ),
                const SizedBox(height: 10),
                Text(
                  'Reference: ${mmqr['reference'] ?? '—'}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Keep this sale pending until you verify the transfer. Reconcile it in Billing & Payments to complete the sale.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _openCart() async {
    final continueToCheckout = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, sheetSetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Current sale', style: _sectionStyle),
                    ),
                    Text(
                      '$_itemCount items',
                      style: const TextStyle(color: _muted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_cart.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Add products to start a sale.'),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final line in _cart.values)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              line.item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${_formatPosMmk(line.item.sellingPrice)} each',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    _changeQuantity(
                                      line.item.id,
                                      line.quantity - 1,
                                    );
                                    sheetSetState(() {});
                                  },
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  '${line.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _changeQuantity(
                                      line.item.id,
                                      line.quantity + 1,
                                    );
                                    sheetSetState(() {});
                                  },
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                const Divider(),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      _formatPosMmk(_total),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _cart.isEmpty || _submitting
                        ? null
                        : () => Navigator.pop(sheetContext, true),
                    child: const Text('Continue to checkout'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (continueToCheckout == true && mounted) {
      await _checkout();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    body: AnimatedBuilder(
      animation: StaffOperationsStore.instance,
      builder: (context, _) {
        final items = _visibleItems;
        return Column(
          children: [
            const _StaffMintHeader(
              title: 'Point of Sale',
              subtitle: 'Counter sales • stock updates automatically',
              icon: Icons.point_of_sale_rounded,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                onSubmitted: _scanOrSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search or scan barcode',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? IconButton(
                          tooltip: 'Scan product barcode',
                          onPressed: _scanBarcode,
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                        )
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _border),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                scrollDirection: Axis.horizontal,
                children: [
                  for (final category in [
                    'All',
                    ...StaffOperationsStore.inventoryCategories,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: category == _category,
                        onSelected: (_) => setState(() => _category = category),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: _muted,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _search.text.isEmpty
                                  ? 'No products available for sale'
                                  : 'No products match your search',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (_search.text.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Text(
                                  'Add products and stock in Inventory first.',
                                  style: TextStyle(color: _muted),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final available = item.availableUnexpiredQuantity;
                        final quantity = _cart[item.id]?.quantity ?? 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: _cardDecoration(),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6FAF2),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  color: _green,
                                ),
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
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      '${item.id} • $available ${item.unit} available',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _formatPosMmk(item.sellingPrice),
                                      style: const TextStyle(
                                        color: _green,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (quantity > 0) ...[
                                IconButton(
                                  onPressed: () =>
                                      _changeQuantity(item.id, quantity - 1),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                              const SizedBox(width: 4),
                              IconButton.filledTonal(
                                tooltip: 'Add ${item.name}',
                                onPressed:
                                    available > quantity &&
                                        item.sellingPrice > 0
                                    ? () => _add(item)
                                    : null,
                                icon: const Icon(Icons.add_rounded),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (_recentSales.isNotEmpty)
              SizedBox(
                height: 104,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: Text(
                        'Recent sales',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _recentSales.length,
                        itemBuilder: (context, index) {
                          final sale = _recentSales[index];
                          return SizedBox(
                            width: 210,
                            child: Card(
                              color: Colors.white,
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  '${sale['id'] ?? 'Sale'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  '${sale['status'] ?? 'Pending'} • ${sale['paymentStatus'] ?? 'Unpaid'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  _formatPosMmk(
                                    (sale['total'] as num? ?? 0).toInt(),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x17000000),
              blurRadius: 12,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _openCart,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_itemCount items • View cart',
                      style: const TextStyle(color: _muted),
                    ),
                    Text(
                      _formatPosMmk(_total),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: _cart.isEmpty || _submitting ? null : _checkout,
              icon: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.shopping_cart_checkout_rounded),
              label: Text(_submitting ? 'Saving…' : 'Checkout'),
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                minimumSize: const Size(130, 48),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PosCartLine {
  _PosCartLine(this.item);
  final InventoryItem item;
  int quantity = 1;
}

class _ProductBarcodeScannerPage extends StatefulWidget {
  const _ProductBarcodeScannerPage();

  @override
  State<_ProductBarcodeScannerPage> createState() =>
      _ProductBarcodeScannerPageState();
}

class _ProductBarcodeScannerPageState
    extends State<_ProductBarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.codabar,
      BarcodeFormat.itf14,
    ],
  );
  bool _returningResult = false;

  void _onDetect(BarcodeCapture capture) {
    if (_returningResult) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value == null || value.isEmpty) continue;
      _returningResult = true;
      Navigator.of(context).pop(value);
      return;
    }
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      title: const Text('Scan product barcode'),
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          tooltip: 'Toggle flashlight',
          onPressed: _controller.toggleTorch,
          icon: const Icon(Icons.flashlight_on_rounded),
        ),
      ],
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(controller: _controller, onDetect: _onDetect),
        IgnorePointer(
          child: Center(
            child: Container(
              width: 310,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: _mint, width: 3),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 36,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Align the product barcode inside the frame.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

String _formatPosMmk(int amount) {
  final digits = amount.toString();
  final formatted = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) formatted.write(',');
    formatted.write(digits[index]);
  }
  return '${formatted.toString()} MMK';
}
