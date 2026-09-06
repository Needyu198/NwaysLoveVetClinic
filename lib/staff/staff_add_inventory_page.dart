part of 'staff_portal.dart';

class StaffAddInventoryPage extends StatefulWidget {
  const StaffAddInventoryPage({this.existing, super.key});

  /// When set, the form edits an existing item instead of creating a new one.
  final InventoryItem? existing;

  @override
  State<StaffAddInventoryPage> createState() => _StaffAddInventoryPageState();
}

class _StaffAddInventoryPageState extends State<StaffAddInventoryPage> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _sku = TextEditingController(text: widget.existing?.id ?? '');
  late final _unit = TextEditingController(text: widget.existing?.unit ?? '');
  late final _quantity = TextEditingController(
    text: widget.existing != null ? '${widget.existing!.quantity}' : '',
  );
  late final _reorder = TextEditingController(
    text: widget.existing != null ? '${widget.existing!.reorderLevel}' : '',
  );
  late final _purchase = TextEditingController(
    text: widget.existing != null ? '${widget.existing!.purchasePrice}' : '',
  );
  late final _selling = TextEditingController(
    text: widget.existing != null ? '${widget.existing!.sellingPrice}' : '',
  );
  late String _category =
      widget.existing?.category ??
      StaffOperationsStore.inventoryCategories.first;
  late DateTime _expiry =
      widget.existing?.expiresOn ??
      DateTime.now().add(const Duration(days: 365));
  late String? _imagePath = widget.existing?.imageAsset;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _unit.dispose();
    _quantity.dispose();
    _reorder.dispose();
    _purchase.dispose();
    _selling.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            if (_imagePath != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFB3261E),
                ),
                title: const Text(
                  'Remove photo',
                  style: TextStyle(color: Color(0xFFB3261E)),
                ),
                onTap: () {
                  setState(() => _imagePath = null);
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (source == null) {
      // Sheet dismissed or "Remove photo" tapped.
      return;
    }
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 82,
      );
      if (picked != null && mounted) {
        setState(() => _imagePath = picked.path);
      }
    } on Exception {
      if (mounted) _notice(context, 'Could not open the image picker.');
    }
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 15),
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final store = StaffOperationsStore.instance;
    if (_isEdit) {
      final item = widget.existing!
        ..name = _name.text.trim()
        ..category = _category
        ..unit = _unit.text.trim()
        ..reorderLevel = int.parse(_reorder.text.trim())
        ..purchasePrice = int.parse(_purchase.text.trim())
        ..sellingPrice = int.parse(_selling.text.trim())
        ..imageAsset = _imagePath
        ..expiresOn = _expiry;
      store.notifyChanged();
      Navigator.pop(context);
      _notice(context, '${item.name} updated.');
      return;
    }

    final sku = _sku.text.trim();
    if (store.isDuplicateSku(sku)) {
      _notice(context, 'Item ID "$sku" already exists.');
      return;
    }
    store.addItem(
      InventoryItem(
        id: sku,
        name: _name.text.trim(),
        category: _category,
        quantity: int.parse(_quantity.text.trim()),
        reorderLevel: int.parse(_reorder.text.trim()),
        unit: _unit.text.trim(),
        purchasePrice: int.parse(_purchase.text.trim()),
        sellingPrice: int.parse(_selling.text.trim()),
        imageAsset: _imagePath,
        expiresOn: _expiry,
      ),
    );
    Navigator.pop(context);
    _notice(context, 'Item added successfully.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    body: Column(
      children: [
        _StaffMintHeader(
          title: _isEdit ? 'Edit Item' : 'Add New Item',
          subtitle: _isEdit
              ? widget.existing!.name
              : 'Create a clinic inventory item',
          icon: Icons.add_box_outlined,
        ),
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
              children: [
                _InventoryPhotoPicker(imagePath: _imagePath, onTap: _pickPhoto),
                const SizedBox(height: 18),
                const _AddSectionLabel('Item information'),
                const SizedBox(height: 10),
                _AddField(
                  controller: _name,
                  label: 'Item name',
                  icon: Icons.label_outline_rounded,
                  validator: _required,
                ),
                _AddField(
                  controller: _sku,
                  label: 'Item ID / SKU',
                  icon: Icons.qr_code_rounded,
                  enabled: !_isEdit,
                  validator: _required,
                ),
                _AddDropdown(
                  label: 'Category',
                  value: _category,
                  items: StaffOperationsStore.inventoryCategories,
                  onChanged: (v) => setState(() => _category = v),
                ),
                const SizedBox(height: 8),
                const _AddSectionLabel('Stock'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _AddField(
                        controller: _quantity,
                        label: _isEdit
                            ? 'Quantity (locked)'
                            : 'Initial quantity',
                        icon: Icons.numbers_rounded,
                        keyboardType: TextInputType.number,
                        enabled: !_isEdit,
                        validator: _isEdit ? null : _positiveIntValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AddField(
                        controller: _unit,
                        label: 'Unit',
                        icon: Icons.straighten_rounded,
                        validator: _required,
                      ),
                    ),
                  ],
                ),
                _AddField(
                  controller: _reorder,
                  label: 'Low-stock threshold',
                  icon: Icons.production_quantity_limits_rounded,
                  keyboardType: TextInputType.number,
                  validator: _positiveIntValidator,
                ),
                const SizedBox(height: 8),
                const _AddSectionLabel('Pricing'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _AddField(
                        controller: _purchase,
                        label: 'Purchase price',
                        icon: Icons.payments_outlined,
                        keyboardType: TextInputType.number,
                        validator: _positiveIntValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AddField(
                        controller: _selling,
                        label: 'Selling price',
                        icon: Icons.sell_outlined,
                        keyboardType: TextInputType.number,
                        validator: _positiveIntValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const _AddSectionLabel('Expiry'),
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: _border),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.event_busy_outlined,
                      color: _green,
                    ),
                    title: const Text('Expiry date'),
                    subtitle: Text(_shortDate(_expiry)),
                    trailing: TextButton(
                      onPressed: _pickExpiry,
                      child: const Text('Pick'),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  key: const ValueKey('save-inventory-item'),
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(_isEdit ? 'Save Changes' : 'Add Item'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: const StadiumBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _AddSectionLabel extends StatelessWidget {
  const _AddSectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w900,
      color: _ink,
    ),
  );
}

class _InventoryPhotoPicker extends StatelessWidget {
  const _InventoryPhotoPicker({required this.imagePath, required this.onTap});

  final String? imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        key: const ValueKey('inventory-photo-picker'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 148,
          height: 148,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border, width: 1.4),
          ),
          clipBehavior: Clip.antiAlias,
          child: imagePath == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 40, color: _green),
                    SizedBox(height: 8),
                    Text(
                      'Add item photo',
                      style: TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(imagePath!),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: _green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    }
    return Image.file(File(path), fit: BoxFit.cover);
  }
}

class _AddField extends StatelessWidget {
  const _AddField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      decoration: _input(label, icon),
    ),
  );
}

class _AddDropdown extends StatelessWidget {
  const _AddDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      decoration: _input(label, Icons.category_outlined),
      items: items
          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    ),
  );
}

String? _required(String? value) =>
    (value ?? '').trim().isEmpty ? 'Required' : null;

Future<void> _editItem(BuildContext context, InventoryItem item) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StaffAddInventoryPage(existing: item),
      ),
    );

Future<void> _requestRestock(BuildContext context, InventoryItem item) async {
  final quantity = TextEditingController(
    text:
        '${item.restockQuantity > 0 ? item.restockQuantity : item.reorderLevel * 2}',
  );
  final note = TextEditingController(text: item.restockNote);
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Request restock'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantity,
              keyboardType: TextInputType.number,
              decoration: _input('Requested quantity', Icons.add_box_outlined),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: note,
              maxLines: 2,
              decoration: _input('Note (optional)', Icons.notes_rounded),
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
          onPressed: () {
            final value = int.tryParse(quantity.text.trim());
            if (value == null || value <= 0) return;
            StaffOperationsStore.instance.requestRestock(
              item,
              value,
              note.text.trim(),
            );
            Navigator.pop(dialogContext, true);
          },
          child: const Text('Submit request'),
        ),
      ],
    ),
  );
  if (saved == true && context.mounted) {
    _notice(context, 'Restock request submitted (Pending Approval).');
  }
  quantity.dispose();
  note.dispose();
}
