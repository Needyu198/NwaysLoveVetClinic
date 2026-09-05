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
  var _urgent = false;
  @override
  void dispose() {
    _owner.dispose();
    _pet.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    appBar: _appBar('Register Walk-In'),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const _Callout(
          icon: Icons.info_outline_rounded,
          text: 'Suspected emergencies must use the emergency workflow.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _owner,
          decoration: _input('Owner name', Icons.person_outline_rounded),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pet,
          decoration: _input('Pet name', Icons.pets_outlined),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _service,
          decoration: _input('Service', Icons.medical_services_outlined),
          items: [
            'General Checkup',
            'Vaccination',
            'Follow-up',
            'Pet Care',
          ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => _service = v!),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _doctor,
          decoration: _input('Available doctor', Icons.person_search_rounded),
          items: _doctors
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (v) => setState(() => _doctor = v!),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _reason,
          maxLines: 3,
          decoration: _input('Visit reason', Icons.notes_rounded),
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          value: _urgent,
          activeThumbColor: _green,
          title: const Text('Urgent priority'),
          subtitle: const Text(
            'Provisional only; veterinarian confirms medical priority.',
          ),
          onChanged: (v) => setState(() => _urgent = v),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          key: const ValueKey('register-walk-in'),
          onPressed: () {
            if (_owner.text.trim().isEmpty ||
                _pet.text.trim().isEmpty ||
                _reason.text.trim().isEmpty) {
              _notice(context, 'Complete the owner, pet, and visit reason.');
              return;
            }
            StaffOperationsStore.instance.addWalkIn(
              owner: _owner.text.trim(),
              pet: _pet.text.trim(),
              service: _service,
              doctor: _doctor,
              reason: _reason.text.trim(),
              urgent: _urgent,
            );
            Navigator.pop(context);
            _notice(context, 'Walk-in registered and added to the queue.');
          },
          icon: const Icon(Icons.add_circle_rounded),
          label: const Text('Register Walk-In'),
        ),
      ],
    ),
  );
}
