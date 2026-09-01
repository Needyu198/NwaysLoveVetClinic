part of 'doctor_portal.dart';

class DoctorConsultationPage extends StatefulWidget {
  const DoctorConsultationPage({required this.record, super.key});

  final DoctorAppointmentRecord record;

  @override
  State<DoctorConsultationPage> createState() => _DoctorConsultationPageState();
}

class _DoctorConsultationPageState extends State<DoctorConsultationPage> {
  late final _notes = TextEditingController(
    text: widget.record.consultationNotes,
  );
  late final _diagnosis = TextEditingController(text: widget.record.diagnosis);
  late final _treatment = TextEditingController(text: widget.record.treatment);
  late final _medicine = TextEditingController();
  late final _dosage = TextEditingController();
  late final _frequency = TextEditingController();
  late final _duration = TextEditingController();
  late final _vaccination = TextEditingController(
    text: widget.record.vaccination,
  );
  late final _nextDose = TextEditingController(
    text: widget.record.nextDoseDate,
  );
  late final _followUp = TextEditingController(text: widget.record.followUp);
  String _testResult = '';

  @override
  void dispose() {
    _notes.dispose();
    _diagnosis.dispose();
    _treatment.dispose();
    _medicine.dispose();
    _dosage.dispose();
    _frequency.dispose();
    _duration.dispose();
    _vaccination.dispose();
    _nextDose.dispose();
    _followUp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    return Scaffold(
      backgroundColor: DoctorStyles.page,
      appBar: AppBar(
        title: const Text('Consultation'),
        backgroundColor: DoctorStyles.mint,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: DoctorStyles.softMint,
                child: Icon(Icons.pets_rounded, size: 30),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.petName, style: DoctorStyles.title),
                    Text(record.petDetails, style: DoctorStyles.muted),
                    Text(
                      'Owner: ${record.ownerName}',
                      style: DoctorStyles.body,
                    ),
                  ],
                ),
              ),
              const _StatusBadge(status: 'In Consultation'),
            ],
          ),
          const SizedBox(height: 20),
          _DoctorDetailsCard(
            rows: [
              ('Booking ID', '#${record.id}'),
              ('Service', record.service),
              ('Date and time', '${_fullDate(record.date)} • ${record.time}'),
              ('Visit reason', record.reason),
              ('Symptoms', record.symptoms),
              ('Allergies', record.allergies),
              ('Existing conditions', record.existingConditions),
              (
                'Previous records',
                DoctorMedicalRecordStore.instance
                        .recordsFor(record.petName)
                        .isEmpty
                    ? 'No previous finalized records'
                    : '${DoctorMedicalRecordStore.instance.recordsFor(record.petName).length} record(s) available',
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            key: const ValueKey('consultation-notes'),
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Examination notes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 13),
          TextField(
            key: const ValueKey('consultation-diagnosis'),
            controller: _diagnosis,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Diagnosis',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 13),
          TextField(
            key: const ValueKey('consultation-treatment'),
            controller: _treatment,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Treatment and recommendations',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Prescription', style: DoctorStyles.section),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('consultation-medicine'),
            controller: _medicine,
            decoration: const InputDecoration(
              labelText: 'Medicine name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('consultation-dosage'),
                  controller: _dosage,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const ValueKey('consultation-frequency'),
                  controller: _frequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('consultation-duration'),
            controller: _duration,
            decoration: const InputDecoration(
              labelText: 'Duration',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Vaccination and Follow-up', style: DoctorStyles.section),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('consultation-vaccine'),
            controller: _vaccination,
            decoration: const InputDecoration(
              labelText: 'Administered vaccine (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('consultation-next-dose'),
            controller: _nextDose,
            decoration: const InputDecoration(
              labelText: 'Next-dose date',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('consultation-follow-up'),
            controller: _followUp,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Follow-up recommendation',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('upload-consultation-result'),
            onPressed: () => setState(
              () => _testResult = 'Diagnostic test result attachment added',
            ),
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(
              _testResult.isEmpty ? 'Upload Test Result' : 'Test Result Added',
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            key: const ValueKey('save-consultation-draft'),
            onPressed: _saveDraft,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Draft'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            key: const ValueKey('complete-doctor-consultation'),
            onPressed: _completeConsultation,
            icon: const Icon(Icons.task_alt_rounded),
            label: const Text('Complete Consultation'),
            style: FilledButton.styleFrom(
              backgroundColor: DoctorStyles.green,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeConsultation() async {
    if (_diagnosis.text.trim().isEmpty || _treatment.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the diagnosis and treatment before finalizing.'),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Complete consultation?'),
        content: const Text(
          'The appointment will move to Completed and today’s dashboard totals will update automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Continue Consulting'),
          ),
          FilledButton(
            key: const ValueKey('confirm-complete-consultation'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    widget.record
      ..consultationNotes = _notes.text.trim()
      ..diagnosis = _diagnosis.text.trim()
      ..treatment = _treatment.text.trim()
      ..prescription = _prescriptionText()
      ..vaccination = _vaccination.text.trim()
      ..nextDoseDate = _nextDose.text.trim()
      ..followUp = _followUp.text.trim();
    DoctorMedicalRecordStore.instance.saveFromConsultation(
      widget.record,
      finalized: true,
      testResult: _testResult,
    );
    DoctorAppointmentStore.instance.updateStatus(widget.record, 'Completed');
    DoctorNotificationStore.instance.add(
      'Medical record finalized',
      '${widget.record.petName}’s consultation record is available in History.',
    );
    Navigator.of(context).pop();
  }

  void _saveDraft() {
    widget.record
      ..consultationNotes = _notes.text.trim()
      ..diagnosis = _diagnosis.text.trim()
      ..treatment = _treatment.text.trim()
      ..prescription = _prescriptionText()
      ..vaccination = _vaccination.text.trim()
      ..nextDoseDate = _nextDose.text.trim()
      ..followUp = _followUp.text.trim();
    DoctorMedicalRecordStore.instance.saveFromConsultation(
      widget.record,
      finalized: false,
      testResult: _testResult,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Consultation draft saved.')));
  }

  String _prescriptionText() {
    if (_medicine.text.trim().isEmpty) return '';
    return '${_medicine.text.trim()} • ${_dosage.text.trim()} • '
        '${_frequency.text.trim()} • ${_duration.text.trim()}';
  }
}
