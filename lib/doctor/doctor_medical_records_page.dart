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
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _DoctorSubpageHeader(title: 'Medical Records'),
            Expanded(
              child: AnimatedBuilder(
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
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                        child: TextField(
                          key: const ValueKey('doctor-medical-search'),
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search pet or record ID',
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
                      Expanded(
                        child: records.isEmpty
                            ? const _EmptyDoctorState(
                                icon: Icons.medical_information_outlined,
                                title: 'No medical records found',
                                message:
                                    'Saved consultation drafts and finalized records appear here.',
                              )
                            : ListView.separated(
                                key: const ValueKey('doctor-medical-records'),
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  28,
                                ),
                                itemCount: records.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) =>
                                    _DoctorMedicalRecordCard(
                                      record: records[index],
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
}

class _DoctorMedicalRecordCard extends StatelessWidget {
  const _DoctorMedicalRecordCard({required this.record});

  final DoctorMedicalRecord record;

  @override
  Widget build(BuildContext context) => Material(
    color: DoctorStyles.mint,
    borderRadius: BorderRadius.circular(28),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('doctor-medical-${record.id}'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DoctorMedicalRecordDetailsPage(record: record),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.description_outlined,
                color: DoctorStyles.green,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.petName,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.service,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DoctorStyles.body,
                  ),
                  Text(_fullDate(record.date), style: DoctorStyles.muted),
                ],
              ),
            ),
            _StatusBadge(status: record.finalized ? 'Completed' : 'Draft'),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

class DoctorMedicalRecordDetailsPage extends StatelessWidget {
  const DoctorMedicalRecordDetailsPage({required this.record, super.key});

  final DoctorMedicalRecord record;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const _DoctorSubpageHeader(title: 'Medical Record'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DoctorStyles.mint,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.pets_rounded, size: 30),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(record.petName, style: DoctorStyles.title),
                            Text(
                              'Pet Owner : ${record.ownerName}',
                              style: DoctorStyles.body,
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(
                        status: record.finalized ? 'Completed' : 'Draft',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _DoctorMintSection(
                  title: 'Clinical Information',
                  icon: Icons.medical_information_outlined,
                  child: _DoctorDetailsCard(
                    rows: [
                      ('Record ID', record.id),
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
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
