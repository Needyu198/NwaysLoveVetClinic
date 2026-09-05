part of 'staff_portal.dart';

class StaffPatientsPage extends StatelessWidget {
  const StaffPatientsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final pets = <String, StaffAppointment>{};
    for (final item in StaffOperationsStore.instance.appointments) {
      pets[item.pet] = item;
    }
    return Scaffold(
      backgroundColor: _page,
      appBar: _appBar('Patients & Owners'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: TextField(
              decoration: _input(
                'Search owner, phone, pet or pet ID',
                Icons.search_rounded,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              itemCount: pets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final item = pets.values.elementAt(i);
                return ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: _border),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: item.priority == 'Urgent'
                        ? const Color(0xFFFFE4E5)
                        : const Color(0xFFE6FAF2),
                    child: const Icon(Icons.pets_rounded),
                  ),
                  title: Text(
                    item.pet,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '${item.owner} • ${item.phone}\nAllergies: none recorded',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showInfo(
                    context,
                    '${item.pet} • Patient profile',
                    'Basic profile and appointment history are available to staff. Diagnoses, prescriptions, clinical notes, and finalized medical records remain read-only.',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
