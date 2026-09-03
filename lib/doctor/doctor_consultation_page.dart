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
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _ConsultationHeader(),
            Expanded(
              child: ListView(
                key: const ValueKey('doctor-consultation-page'),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ConsultationPatientCard(record: record),
                      const SizedBox(height: 18),
                      _ConsultationSection(
                        icon: Icons.event_note_rounded,
                        title: 'Appointment Information',
                        child: _DoctorDetailsCard(
                          rows: [
                            ('Booking ID', '#${record.id}'),
                            ('Service', record.service),
                            (
                              'Date and time',
                              '${_fullDate(record.date)} • ${record.time}',
                            ),
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
                      ),
                      const SizedBox(height: 18),
                      _ConsultationSection(
                        icon: Icons.medical_services_outlined,
                        title: 'Examination',
                        child: Column(
                          children: [
                            TextField(
                              key: const ValueKey('consultation-notes'),
                              controller: _notes,
                              maxLines: 3,
                              decoration: _consultationDecoration(
                                'Examination notes',
                                Icons.edit_note_rounded,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              key: const ValueKey('consultation-diagnosis'),
                              controller: _diagnosis,
                              maxLines: 2,
                              decoration: _consultationDecoration(
                                'Diagnosis',
                                Icons.medical_information_outlined,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              key: const ValueKey('consultation-treatment'),
                              controller: _treatment,
                              maxLines: 3,
                              decoration: _consultationDecoration(
                                'Treatment and recommendations',
                                Icons.healing_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ConsultationSection(
                        icon: Icons.medication_rounded,
                        title: 'Prescription',
                        child: Column(
                          children: [
                            TextField(
                              key: const ValueKey('consultation-medicine'),
                              controller: _medicine,
                              decoration: _consultationDecoration(
                                'Medicine name',
                                Icons.medication_outlined,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    key: const ValueKey('consultation-dosage'),
                                    controller: _dosage,
                                    decoration: _consultationDecoration(
                                      'Dosage',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    key: const ValueKey(
                                      'consultation-frequency',
                                    ),
                                    controller: _frequency,
                                    decoration: _consultationDecoration(
                                      'Frequency',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              key: const ValueKey('consultation-duration'),
                              controller: _duration,
                              decoration: _consultationDecoration(
                                'Duration',
                                Icons.schedule_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ConsultationSection(
                        icon: Icons.vaccines_rounded,
                        title: 'Vaccination and Follow-up',
                        child: Column(
                          children: [
                            TextField(
                              key: const ValueKey('consultation-vaccine'),
                              controller: _vaccination,
                              decoration: _consultationDecoration(
                                'Administered vaccine (optional)',
                                Icons.vaccines_outlined,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              key: const ValueKey('consultation-next-dose'),
                              controller: _nextDose,
                              decoration: _consultationDecoration(
                                'Next-dose date',
                                Icons.calendar_month_rounded,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              key: const ValueKey('consultation-follow-up'),
                              controller: _followUp,
                              maxLines: 2,
                              decoration: _consultationDecoration(
                                'Follow-up recommendation',
                                Icons.follow_the_signs_rounded,
                              ),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              key: const ValueKey('upload-consultation-result'),
                              onPressed: () => setState(
                                () => _testResult =
                                    'Diagnostic test result attachment added',
                              ),
                              icon: Icon(
                                _testResult.isEmpty
                                    ? Icons.upload_file_outlined
                                    : Icons.check_circle_rounded,
                              ),
                              label: Text(
                                _testResult.isEmpty
                                    ? 'Upload Test Result'
                                    : 'Test Result Added',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                side: const BorderSide(
                                  color: Colors.black,
                                  width: 1.5,
                                ),
                                minimumSize: const Size.fromHeight(50),
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      OutlinedButton.icon(
                        key: const ValueKey('save-consultation-draft'),
                        onPressed: _saveDraft,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save Draft'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(
                            color: Colors.black,
                            width: 1.5,
                          ),
                          minimumSize: const Size.fromHeight(54),
                          shape: const StadiumBorder(),
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
                          minimumSize: const Size.fromHeight(56),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
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

class _ConsultationHeader extends StatelessWidget {
  const _ConsultationHeader();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 16, 24, 18),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      boxShadow: [
        BoxShadow(
          color: Color(0x28000000),
          blurRadius: 7,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        InkWell(
          key: const ValueKey('doctor-consultation-back'),
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(22),
          child: const Padding(
            padding: EdgeInsets.all(7),
            child: Icon(Icons.chevron_left_rounded, size: 30),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Consultation',
            style: TextStyle(
              color: Colors.black,
              fontSize: 29,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ConsultationPatientCard extends StatelessWidget {
  const _ConsultationPatientCard({required this.record});

  final DoctorAppointmentRecord record;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: DoctorStyles.mint,
      borderRadius: BorderRadius.circular(30),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 7,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 66,
            height: 66,
            child: Image.asset(
              'assets/photos/logoandphoto/nways_photo.png',
              fit: BoxFit.cover,
              alignment: Alignment.topRight,
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.petName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(record.petDetails, style: DoctorStyles.body),
              Text(
                'Pet Owner : ${record.ownerName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DoctorStyles.body,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const _StatusBadge(status: 'In Consultation'),
      ],
    ),
  );
}

class _ConsultationSection extends StatelessWidget {
  const _ConsultationSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
    decoration: BoxDecoration(
      color: DoctorStyles.mint,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Icon(icon, color: Colors.black, size: 25),
              const SizedBox(width: 9),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        child,
      ],
    ),
  );
}

InputDecoration _consultationDecoration(String label, [IconData? icon]) {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(22)),
    borderSide: BorderSide(color: Colors.transparent),
  );
  return InputDecoration(
    labelText: label,
    prefixIcon: icon == null ? null : Icon(icon, color: DoctorStyles.green),
    filled: true,
    fillColor: Colors.white,
    border: border,
    enabledBorder: border,
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(22)),
      borderSide: BorderSide(color: DoctorStyles.green, width: 1.8),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  );
}
