part of 'doctor_portal.dart';

class DoctorMedicalRecordsPage extends StatefulWidget {
  const DoctorMedicalRecordsPage({super.key});

  @override
  State<DoctorMedicalRecordsPage> createState() =>
      _DoctorMedicalRecordsPageState();
}

class _DoctorMedicalRecordsPageState extends State<DoctorMedicalRecordsPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorStyles.page,
      appBar: AppBar(
        title: const Text('Medical Records'),
        backgroundColor: DoctorStyles.mint,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: DoctorMedicalRecordStore.instance,
        builder: (context, _) {
          final query = _search.text.trim().toLowerCase();
          final records = DoctorMedicalRecordStore.instance.records
              .where(
                (record) =>
                    query.isEmpty ||
                    record.petName.toLowerCase().contains(query) ||
                    record.id.toLowerCase().contains(query),
              )
              .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  key: const ValueKey('doctor-medical-search'),
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search pet or medical record ID',
                    prefixIcon: Icon(Icons.search_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: records.isEmpty
                    ? const _EmptyDoctorState(
                        icon: Icons.medical_information_outlined,
                        title: 'No medical records found',
                        message:
                            'Saved consultation drafts and finalized records appear here.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                        itemCount: records.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return ListTile(
                            key: ValueKey('doctor-medical-${record.id}'),
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: const BorderSide(
                                color: DoctorStyles.border,
                              ),
                            ),
                            leading: const CircleAvatar(
                              backgroundColor: DoctorStyles.softMint,
                              child: Icon(Icons.description_outlined),
                            ),
                            title: Text(record.petName),
                            subtitle: Text(
                              '${record.service} • ${record.finalized ? 'Finalized' : 'Draft'}',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => DoctorMedicalRecordDetailsPage(
                                  record: record,
                                ),
                              ),
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
}

class DoctorMedicalRecordDetailsPage extends StatelessWidget {
  const DoctorMedicalRecordDetailsPage({required this.record, super.key});

  final DoctorMedicalRecord record;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DoctorStyles.page,
    appBar: AppBar(
      title: const Text('Medical Record'),
      backgroundColor: DoctorStyles.mint,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _DoctorDetailsCard(
          rows: [
            ('Record ID', record.id),
            ('Pet', record.petName),
            ('Owner', record.ownerName),
            ('Status', record.finalized ? 'Finalized' : 'Draft'),
            ('Symptoms', record.symptoms),
            ('Findings', _orNotRecorded(record.findings)),
            ('Diagnosis', _orNotRecorded(record.diagnosis)),
            ('Treatment', _orNotRecorded(record.treatment)),
            ('Prescription', _orNotRecorded(record.prescription)),
            ('Vaccination', _orNotRecorded(record.vaccination)),
            ('Next dose', _orNotRecorded(record.nextDoseDate)),
            ('Follow-up', _orNotRecorded(record.followUp)),
            ('Test result', _orNotRecorded(record.testResult)),
          ],
        ),
      ],
    ),
  );
}
