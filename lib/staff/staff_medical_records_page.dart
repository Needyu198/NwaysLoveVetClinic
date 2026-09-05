part of 'staff_portal.dart';

class StaffMedicalRecordsPage extends StatefulWidget {
  const StaffMedicalRecordsPage({super.key});

  @override
  State<StaffMedicalRecordsPage> createState() =>
      _StaffMedicalRecordsPageState();
}

class _StaffMedicalRecordsPageState extends State<StaffMedicalRecordsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    appBar: _appBar('Medical Records'),
    body: AnimatedBuilder(
      animation: DoctorMedicalRecordStore.instance,
      builder: (context, _) {
        final records = DoctorMedicalRecordStore.instance.records
            .where((record) => record.finalized)
            .where(
              (record) => '${record.id} ${record.petName} ${record.ownerName}'
                  .toLowerCase()
                  .contains(_query.toLowerCase()),
            )
            .toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const _Callout(
                    icon: Icons.lock_outline_rounded,
                    text:
                        'Finalized diagnoses, prescriptions, clinical notes, and medical records are read-only for staff.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: _input(
                      'Search pet, owner or record ID',
                      Icons.search_rounded,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: records.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Text(
                          'No finalized medical records match this search.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                      itemCount: records.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final record = records[index];
                        return ListTile(
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: _border),
                          ),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE6FAF2),
                            child: Icon(
                              Icons.folder_shared_rounded,
                              color: _green,
                            ),
                          ),
                          title: Text(
                            '${record.petName} • ${record.service}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            '${record.ownerName} • ${_shortDate(record.date)}\nFinalized • Read only',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _showInfo(
                            context,
                            record.id,
                            'Findings: ${record.findings}\n\nDiagnosis: ${record.diagnosis}\n\nTreatment: ${record.treatment}\n\nPrescription: ${record.prescription}',
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    ),
  );
}
