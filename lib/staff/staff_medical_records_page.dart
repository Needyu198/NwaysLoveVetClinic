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
    body: Column(
      children: [
        const _StaffMintHeader(
          title: 'Medical Records',
          subtitle: 'Finalized clinical records (read only)',
          icon: Icons.folder_shared_outlined,
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: DoctorMedicalRecordStore.instance,
            builder: (context, _) {
              final records = DoctorMedicalRecordStore.instance.records
                  .where((record) => record.finalized)
                  .where(
                    (record) =>
                        '${record.id} ${record.petName} ${record.ownerName}'
                            .toLowerCase()
                            .contains(_query.toLowerCase()),
                  )
                  .toList();
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                    child: TextField(
                      key: const ValueKey('staff-medical-search'),
                      onChanged: (value) => setState(() => _query = value),
                      decoration: _input(
                        'Search pet, owner or record ID',
                        Icons.search_rounded,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 15,
                          color: _muted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Read only • ${records.length} record'
                            '${records.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: records.isEmpty
                        ? const _StaffEmptyState(
                            icon: Icons.folder_off_outlined,
                            title: 'No medical records',
                            message:
                                'Finalized clinical records will appear here.',
                          )
                        : ListView.separated(
                            key: const ValueKey('staff-medical-records'),
                            padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                            itemCount: records.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) =>
                                _MedicalRecordCard(record: records[index]),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _MedicalRecordCard extends StatelessWidget {
  const _MedicalRecordCard({required this.record});
  final DoctorMedicalRecord record;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('staff-medical-${record.id}'),
      onTap: () => _push(context, StaffMedicalRecordDetailPage(record: record)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFE6FAF2),
              child: Icon(Icons.folder_shared_rounded, color: _green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${record.petName} • ${record.service}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${record.ownerName} • ${_shortDate(record.date)}',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: _mint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Finalized',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    ),
  );
}

class StaffMedicalRecordDetailPage extends StatelessWidget {
  const StaffMedicalRecordDetailPage({required this.record, super.key});
  final DoctorMedicalRecord record;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    body: Column(
      children: [
        _StaffMintHeader(
          title: 'Record ${record.id}',
          subtitle: '${record.petName} • ${record.ownerName}',
          icon: Icons.folder_shared_outlined,
        ),
        Expanded(
          child: ListView(
            key: const ValueKey('staff-medical-detail'),
            padding: const EdgeInsets.all(18),
            children: [
              const _Callout(
                icon: Icons.lock_outline_rounded,
                text:
                    'Diagnoses, prescriptions, and clinical notes are read-only for staff.',
              ),
              const SizedBox(height: 14),
              _InfoCard(
                rows: [
                  ('Record ID', record.id),
                  ('Pet', record.petName),
                  ('Owner', record.ownerName),
                  ('Service', record.service),
                  ('Date', _shortDate(record.date)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Clinical details', style: _sectionStyle),
              const SizedBox(height: 8),
              _RecordField('Symptoms', record.symptoms),
              _RecordField('Findings', record.findings),
              _RecordField('Diagnosis', record.diagnosis),
              _RecordField('Treatment', record.treatment),
              _RecordField('Prescription', record.prescription),
              _RecordField('Vaccination', record.vaccination),
              _RecordField('Next dose', record.nextDoseDate),
              _RecordField('Follow-up', record.followUp),
              _RecordField('Test result', record.testResult),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RecordField extends StatelessWidget {
  const _RecordField(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = value.trim().isEmpty ? 'Not recorded' : value;
    final empty = value.trim().isEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              color: empty ? _muted : _ink,
              fontStyle: empty ? FontStyle.italic : FontStyle.normal,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
