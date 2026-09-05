part of 'staff_portal.dart';

class StaffWalkInPage extends StatefulWidget {
  const StaffWalkInPage({super.key});
  @override
  State<StaffWalkInPage> createState() => _StaffWalkInPageState();
}

class _StaffWalkInPageState extends State<StaffWalkInPage> {
  final _owner = TextEditingController();
  final _pet = TextEditingController();
  final _reason = TextEditingController();
  var _service = 'General Checkup';
  var _doctor = 'Dr. Aye Chan';

  static const _services = [
    'General Checkup',
    'Vaccination',
    'Follow-up',
    'Pet Care',
  ];

  @override
  void dispose() {
    _owner.dispose();
    _pet.dispose();
    _reason.dispose();
    super.dispose();
  }

  bool _validate() {
    if (_owner.text.trim().isEmpty ||
        _pet.text.trim().isEmpty ||
        _reason.text.trim().isEmpty) {
      _notice(context, 'Complete the owner, pet, and visit reason.');
      return false;
    }
    return true;
  }

  void _register({required bool urgent}) {
    if (!_validate()) return;
    StaffOperationsStore.instance.addWalkIn(
      owner: _owner.text.trim(),
      pet: _pet.text.trim(),
      service: _service,
      doctor: _doctor,
      reason: _reason.text.trim(),
      urgent: urgent,
    );
    Navigator.pop(context);
    _notice(
      context,
      urgent
          ? 'Emergency walk-in registered and prioritized in the queue.'
          : 'Walk-in registered and added to the queue.',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        const _WalkInHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
            children: [
              _WalkInField(
                controller: _owner,
                hint: 'Owner Name',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
              _WalkInField(
                controller: _pet,
                hint: 'Pet Name',
                icon: Icons.pets_outlined,
              ),
              const SizedBox(height: 16),
              _WalkInDropdown(
                label: 'Service',
                icon: Icons.medical_services_outlined,
                value: _service,
                items: _services,
                onChanged: (v) => setState(() => _service = v),
              ),
              const SizedBox(height: 16),
              _WalkInDropdown(
                label: 'Available Doctor',
                icon: Icons.person_search_rounded,
                value: _doctor,
                items: _doctors,
                onChanged: (v) => setState(() => _doctor = v),
              ),
              const SizedBox(height: 16),
              _WalkInField(
                controller: _reason,
                hint: 'Visit Reason',
                icon: Icons.notes_rounded,
                maxLines: 5,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 62,
                      child: FilledButton(
                        key: const ValueKey('register-walk-in'),
                        onPressed: () => _register(urgent: false),
                        style: FilledButton.styleFrom(
                          backgroundColor: _mint,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('Register Walk-in'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Tooltip(
                    message: 'Register as emergency',
                    child: SizedBox(
                      width: 64,
                      height: 62,
                      child: FilledButton(
                        key: const ValueKey('register-walk-in-emergency'),
                        onPressed: () => _register(urgent: true),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF0000),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: const Text(
                          'E',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
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
  );
}

class _WalkInHeader extends StatelessWidget {
  const _WalkInHeader();

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
        padding: const EdgeInsets.fromLTRB(8, 6, 18, 22),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.chevron_left_rounded, size: 30),
            ),
            const Expanded(
              child: Text(
                'Register Walk in',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  color: _ink,
                ),
              ),
            ),
            Image.asset(
              'assets/photos/logoandphoto/nways_love_logo.png',
              width: 56,
              height: 56,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    ),
  );
}

class _WalkInField extends StatelessWidget {
  const _WalkInField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _border),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      crossAxisAlignment: maxLines > 1
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(top: maxLines > 1 ? 18 : 0),
          child: Icon(icon, color: _green, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 17, color: _ink),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _muted, fontSize: 17),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                vertical: maxLines > 1 ? 18 : 20,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _WalkInDropdown extends StatelessWidget {
  const _WalkInDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: _green, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _ink,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                  items: items
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onChanged(v);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      Positioned(
        left: 18,
        top: -8,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            label,
            style: const TextStyle(
              color: _green,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ],
  );
}
