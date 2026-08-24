import 'package:flutter/material.dart';

import '../doctor/doctor_portal.dart';
import 'appointment_booking_page.dart';
import 'emergency_service_page.dart';
import 'home_visit_booking_page.dart';
import 'pet_care_booking_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  static const routeName = '/history';

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

enum HistoryCategory {
  appointments,
  medical,
  petCare,
  homeVisits,
  emergency,
  queue,
}

class HistoryRecord {
  const HistoryRecord({
    required this.id,
    required this.petName,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.time,
    required this.status,
    required this.details,
    required this.source,
    required this.completed,
  });

  final String id;
  final String petName;
  final HistoryCategory category;
  final String title;
  final String subtitle;
  final DateTime date;
  final String time;
  final String status;
  final Map<String, String> details;
  final Object source;
  final bool completed;

  String get searchable => [
    id,
    petName,
    title,
    subtitle,
    status,
    ...details.values,
  ].join(' ').toLowerCase();
}

class HistoryReviewStore extends ChangeNotifier {
  HistoryReviewStore._();

  static final instance = HistoryReviewStore._();

  final Map<String, ({int rating, String review})> _reviews = {};

  ({int rating, String review})? reviewFor(String id) => _reviews[id];

  void save(String id, int rating, String review) {
    _reviews[id] = (rating: rating, review: review);
    notifyListeners();
  }

  @visibleForTesting
  void clear() {
    _reviews.clear();
    notifyListeners();
  }
}

class _HistoryPageState extends State<HistoryPage> {
  static const _defaultPetNames = ['Max', 'Bella', 'Luna'];
  final _search = TextEditingController();

  String? _petName;
  HistoryCategory _category = HistoryCategory.appointments;
  String _dateRange = 'All time';
  String _status = 'All statuses';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    QueueStore.instance.syncConfirmedAppointments(
      AppointmentStore.instance.appointments,
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: const Color(0xFFA1FDD8),
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          AppointmentStore.instance,
          QueueStore.instance,
          PetCareBookingStore.instance,
          HomeVisitStore.instance,
          EmergencyRequestStore.instance,
          DoctorMedicalRecordStore.instance,
        ]),
        builder: (context, _) {
          if (_petName == null) return _petSelection();
          final records = _filteredRecords();
          return Column(
            children: [
              _historyControls(),
              Expanded(
                child: records.isEmpty
                    ? const _HistoryEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                        itemCount: records.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _HistoryCard(
                          record: records[index],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  HistoryDetailsPage(record: records[index]),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _petSelection() {
    final petNames = {
      ..._defaultPetNames,
      ..._allRecords().map((record) => record.petName),
    }.toList()..sort();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Select Pet', style: _HistoryText.title),
        const SizedBox(height: 6),
        const Text(
          'Choose a pet to view previous and current records.',
          style: _HistoryText.body,
        ),
        const SizedBox(height: 20),
        for (final petName in petNames) ...[
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              key: ValueKey('history-pet-$petName'),
              onTap: () => setState(() => _petName = petName),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFA1FDD8),
                      child: Icon(Icons.pets_rounded, color: Color(0xFF16855E)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(petName, style: _HistoryText.cardTitle),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _historyControls() {
    return Material(
      color: Colors.white,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('$_petName Records', style: _HistoryText.section),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _petName = null;
                    _search.clear();
                  }),
                  child: const Text('Change Pet'),
                ),
              ],
            ),
            TextField(
              key: const ValueKey('history-search'),
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search ID, veterinarian, or service',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF2F7F4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final category in HistoryCategory.values) ...[
                    ChoiceChip(
                      key: ValueKey('history-category-${category.name}'),
                      label: Text(_categoryLabel(category)),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _dateRange,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Date range',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const ['All time', 'Last 30 days', 'Last 90 days']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _dateRange = value!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items:
                        const [
                              'All statuses',
                              'Active',
                              'Confirmed',
                              'Cancelled',
                              'Completed',
                            ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => setState(() => _status = value!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<HistoryRecord> _filteredRecords() {
    final query = _search.text.trim().toLowerCase();
    final records = _allRecords()
        .where((record) => record.petName == _petName)
        .where((record) => record.category == _category)
        .where((record) => query.isEmpty || record.searchable.contains(query))
        .where((record) {
          if (_dateRange == 'All time') return true;
          final days = _dateRange == 'Last 30 days' ? 30 : 90;
          return record.date.isAfter(
            DateTime.now().subtract(Duration(days: days)),
          );
        })
        .where(
          (record) => switch (_status) {
            'Active' =>
              !record.completed && record.status.toLowerCase() != 'cancelled',
            'Confirmed' => record.status.toLowerCase() == 'confirmed',
            'Cancelled' => record.status.toLowerCase() == 'cancelled',
            'Completed' => record.completed,
            _ => true,
          },
        )
        .toList();
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  List<HistoryRecord> _allRecords() {
    final records = <HistoryRecord>[];

    for (final appointment in AppointmentStore.instance.appointments) {
      if (appointment.service.homeVisit) continue;
      records.add(
        HistoryRecord(
          id: appointment.id,
          petName: appointment.pet.name,
          category: HistoryCategory.appointments,
          title: appointment.service.name,
          subtitle: appointment.veterinarian,
          date: appointment.date,
          time: appointment.time,
          status: appointment.status,
          completed: false,
          source: appointment,
          details: {
            'Booking ID': '#${appointment.id}',
            'Booking date': _historyDate(appointment.createdAt),
            'Appointment date': _historyDate(appointment.date),
            'Time': appointment.time,
            'Veterinarian': appointment.veterinarian,
            'Status': appointment.status,
            'Symptoms': appointment.symptoms,
            'Visit reason': appointment.reason,
            if (appointment.cancellation case final cancellation?) ...{
              'Cancellation ID': cancellation.id,
              'Cancellation reason': cancellation.reason,
              if (cancellation.additionalReason.isNotEmpty)
                'Cancellation explanation': cancellation.additionalReason,
              'Cancelled at': _historyDate(cancellation.cancelledAt),
              'Cancellation fee': 'MMK 0 — No cancellation fee',
              'Refund': 'No payment collected; no refund required',
              'Notification': cancellation.notificationsSent
                  ? 'Pet owner and clinic staff notified'
                  : 'Notification pending',
            },
          },
        ),
      );
    }

    for (final booking in PetCareBookingStore.instance.bookings) {
      records.add(
        HistoryRecord(
          id: booking.id,
          petName: booking.pet.name,
          category: HistoryCategory.petCare,
          title: booking.service.name,
          subtitle: booking.provider,
          date: booking.date,
          time: booking.time,
          status: _petCareStatus(booking.status),
          completed: booking.status == PetCareStatus.completed,
          source: booking,
          details: {
            'Booking ID': '#${booking.id}',
            'Service': booking.service.name,
            'Date': _historyDate(booking.date),
            'Time': booking.time,
            'Provider': booking.provider,
            'Price': booking.service.price,
            'Location': booking.location,
            'Status': _petCareStatus(booking.status),
          },
        ),
      );
    }

    for (final visit in HomeVisitStore.instance.visits) {
      records.add(
        HistoryRecord(
          id: visit.id,
          petName: visit.pet.name,
          category: HistoryCategory.homeVisits,
          title: 'Home Visit',
          subtitle: visit.veterinarian,
          date: visit.date,
          time: visit.time,
          status: _homeVisitStatus(visit.status),
          completed: visit.status == HomeVisitStatus.completed,
          source: visit,
          details: {
            'Booking ID': '#${visit.id}',
            'Veterinarian': visit.veterinarian,
            'Visit date': _historyDate(visit.date),
            'Time': visit.time,
            'Address': visit.address,
            'Reason': visit.reason,
            'Symptoms': visit.symptoms,
            'Treatment': visit.treatmentNotes.isEmpty
                ? 'Not recorded yet'
                : visit.treatmentNotes,
            'Status': _homeVisitStatus(visit.status),
          },
        ),
      );
    }

    for (final request in EmergencyRequestStore.instance.requests) {
      if (request.status != EmergencyStatus.completed) continue;
      records.add(
        HistoryRecord(
          id: request.id,
          petName: request.pet.name,
          category: HistoryCategory.emergency,
          title: 'Emergency Service',
          subtitle: request.priority,
          date: request.createdAt,
          time: _historyTime(request.createdAt),
          status: 'Completed',
          completed: true,
          source: request,
          details: {
            'Request ID': '#${request.id}',
            'Date': _historyDate(request.createdAt),
            'Symptoms': request.symptoms.join(', '),
            'Description': request.description,
            'Priority': request.priority,
            'Findings': request.findings,
            'Diagnosis': request.diagnosis,
            'Treatment': request.treatmentResult,
            'Recommendations': request.recommendations,
            'Status': 'Completed',
          },
        ),
      );
    }

    for (final medical in DoctorMedicalRecordStore.instance.records) {
      if (!medical.finalized) continue;
      records.add(
        HistoryRecord(
          id: medical.id,
          petName: medical.petName,
          category: HistoryCategory.medical,
          title: medical.service,
          subtitle: DoctorAppointmentStore.doctorName,
          date: medical.date,
          time: _historyTime(medical.date),
          status: 'Completed',
          completed: true,
          source: medical,
          details: {
            'Medical record ID': '#${medical.id}',
            'Symptoms': medical.symptoms,
            'Examination findings': medical.findings,
            'Diagnosis': medical.diagnosis,
            'Treatment': medical.treatment,
            'Prescription': medical.prescription.isEmpty
                ? 'No prescription recorded'
                : medical.prescription,
            'Vaccination': medical.vaccination.isEmpty
                ? 'No vaccine administered'
                : medical.vaccination,
            'Next dose': medical.nextDoseDate.isEmpty
                ? 'Not required'
                : medical.nextDoseDate,
            'Follow-up': medical.followUp.isEmpty
                ? 'No follow-up recorded'
                : medical.followUp,
            'Test result': medical.testResult.isEmpty
                ? 'No attachment'
                : medical.testResult,
            'Veterinarian': DoctorAppointmentStore.doctorName,
            'Date': _historyDate(medical.date),
          },
        ),
      );
    }

    final queueEntries = [
      ...QueueStore.instance.active,
      ...QueueStore.instance.history,
    ];
    for (final entry in queueEntries) {
      final completed = entry.status == QueueStatus.completed;
      final common = {
        'Queue number': entry.queueNumber,
        'Booking ID': '#${entry.appointment.id}',
        'Veterinarian': entry.appointment.veterinarian,
        'Appointment date': _historyDate(entry.appointment.date),
        'Time': entry.appointment.time,
        'Status': _queueHistoryStatus(entry.status),
        if (entry.room.isNotEmpty) 'Consultation room': entry.room,
      };
      records.add(
        HistoryRecord(
          id: 'QUEUE-${entry.appointment.id}',
          petName: entry.appointment.pet.name,
          category: HistoryCategory.queue,
          title: 'Queue ${entry.queueNumber}',
          subtitle: entry.appointment.veterinarian,
          date: entry.appointment.date,
          time: entry.appointment.time,
          status: _queueHistoryStatus(entry.status),
          completed: completed,
          source: entry,
          details: {
            ...common,
            if (completed) 'Consultation': entry.consultationSummary,
            if (completed) 'Diagnosis': entry.diagnosis,
            if (completed) 'Treatment': entry.treatment,
            if (completed) 'Prescription': entry.prescription,
            if (completed) 'Recommendations': entry.recommendations,
          },
        ),
      );
      if (completed &&
          !DoctorMedicalRecordStore.instance.records.any(
            (record) =>
                record.appointmentId == entry.appointment.id &&
                record.finalized,
          )) {
        records.add(
          HistoryRecord(
            id: 'MED-${entry.appointment.id}',
            petName: entry.appointment.pet.name,
            category: HistoryCategory.medical,
            title: entry.appointment.service.name,
            subtitle: entry.appointment.veterinarian,
            date: entry.appointment.date,
            time: entry.appointment.time,
            status: 'Completed',
            completed: true,
            source: entry,
            details: {
              'Medical record ID': '#MED-${entry.appointment.id}',
              'Symptoms': entry.appointment.symptoms,
              'Diagnosis': entry.diagnosis,
              'Treatment': entry.treatment,
              'Prescription': entry.prescription,
              'Recommendations': entry.recommendations,
              'Veterinarian': entry.appointment.veterinarian,
              'Date': _historyDate(entry.appointment.date),
            },
          ),
        );
      }
    }
    return records;
  }
}

class HistoryDetailsPage extends StatelessWidget {
  const HistoryDetailsPage({required this.record, super.key});

  final HistoryRecord record;

  @override
  Widget build(BuildContext context) {
    final canViewMedicalRecord =
        record.completed &&
        (record.category == HistoryCategory.medical ||
            record.category == HistoryCategory.queue ||
            record.category == HistoryCategory.homeVisits ||
            record.category == HistoryCategory.emergency);
    final canBookFollowUp =
        record.completed &&
        (record.category == HistoryCategory.medical ||
            record.category == HistoryCategory.queue ||
            record.category == HistoryCategory.emergency);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        title: const Text('History Details'),
        backgroundColor: const Color(0xFFA1FDD8),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFA1FDD8),
                foregroundColor: Color(0xFF16855E),
                child: Icon(Icons.history_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.title, style: _HistoryText.title),
                    Text(record.petName, style: _HistoryText.body),
                  ],
                ),
              ),
              _HistoryStatus(status: record.status),
            ],
          ),
          const SizedBox(height: 18),
          _HistoryDetailsPanel(details: record.details),
          if (canViewMedicalRecord) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const ValueKey('view-history-medical-record'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => HistoryMedicalRecordPage(record: record),
                ),
              ),
              icon: const Icon(Icons.description_outlined),
              label: const Text('View Medical Record'),
            ),
          ],
          if (canBookFollowUp) ...[
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const ValueKey('book-history-follow-up'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      AppointmentBookingPage(initialPetName: record.petName),
                ),
              ),
              icon: const Icon(Icons.event_repeat_outlined),
              label: const Text('Book Follow-up'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16855E),
                foregroundColor: Colors.white,
              ),
            ),
          ],
          if (record.completed) ...[
            const SizedBox(height: 22),
            HistoryReviewSection(recordId: record.id),
          ],
        ],
      ),
    );
  }
}

class HistoryMedicalRecordPage extends StatelessWidget {
  const HistoryMedicalRecordPage({required this.record, super.key});

  final HistoryRecord record;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        title: const Text('Medical Record'),
        backgroundColor: const Color(0xFFA1FDD8),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '${record.petName} • ${record.title}',
            style: _HistoryText.title,
          ),
          const SizedBox(height: 16),
          _HistoryDetailsPanel(details: record.details),
        ],
      ),
    );
  }
}

class HistoryReviewSection extends StatefulWidget {
  const HistoryReviewSection({required this.recordId, super.key});

  final String recordId;

  @override
  State<HistoryReviewSection> createState() => _HistoryReviewSectionState();
}

class _HistoryReviewSectionState extends State<HistoryReviewSection> {
  final _review = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saved = HistoryReviewStore.instance.reviewFor(widget.recordId);
    if (saved != null) {
      return _HistoryDetailsPanel(
        details: {
          'Rating': '${saved.rating} / 5',
          'Review': saved.review.isEmpty ? 'No written review' : saved.review,
        },
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rating and Review', style: _HistoryText.section),
        Row(
          children: [
            for (var star = 1; star <= 5; star++)
              IconButton(
                key: ValueKey('history-rating-$star'),
                onPressed: () => setState(() => _rating = star),
                icon: Icon(
                  star <= _rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: const Color(0xFFFFB000),
                ),
              ),
          ],
        ),
        TextField(
          controller: _review,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Write a review',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _rating == 0
              ? null
              : () {
                  HistoryReviewStore.instance.save(
                    widget.recordId,
                    _rating,
                    _review.text.trim(),
                  );
                  setState(() {});
                },
          child: const Text('Save Review'),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.record, required this.onTap});

  final HistoryRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: ValueKey('history-record-${record.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFA1FDD8),
                foregroundColor: Color(0xFF16855E),
                child: Icon(Icons.description_outlined),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.title, style: _HistoryText.cardTitle),
                    const SizedBox(height: 3),
                    Text(record.subtitle, style: _HistoryText.body),
                    Text(
                      '${_historyDate(record.date)} • ${record.time}',
                      style: _HistoryText.caption,
                    ),
                  ],
                ),
              ),
              _HistoryStatus(status: record.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryStatus extends StatelessWidget {
  const _HistoryStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 105),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F8EF),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        status,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF087F50),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HistoryDetailsPanel extends StatelessWidget {
  const _HistoryDetailsPanel({required this.details});

  final Map<String, String> details;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD6EEE4)),
      ),
      child: Column(
        children: [
          for (final entry in details.entries) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 112,
                  child: Text(entry.key, style: _HistoryText.label),
                ),
                Expanded(
                  child: Text(entry.value, style: _HistoryText.bodyDark),
                ),
              ],
            ),
            if (entry.key != details.keys.last) const Divider(height: 22),
          ],
        ],
      ),
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 68,
              color: Color(0xFF61736D),
            ),
            SizedBox(height: 14),
            Text('No matching records', style: _HistoryText.section),
            SizedBox(height: 6),
            Text(
              'Try another category, date range, status, or search term.',
              textAlign: TextAlign.center,
              style: _HistoryText.body,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryText {
  static const title = TextStyle(
    color: Color(0xFF101814),
    fontSize: 27,
    fontWeight: FontWeight.w900,
  );
  static const section = TextStyle(
    color: Color(0xFF101814),
    fontSize: 19,
    fontWeight: FontWeight.w900,
  );
  static const cardTitle = TextStyle(
    color: Color(0xFF101814),
    fontSize: 17,
    fontWeight: FontWeight.w900,
  );
  static const body = TextStyle(
    color: Color(0xFF61736D),
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w600,
  );
  static const bodyDark = TextStyle(
    color: Color(0xFF25312D),
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w700,
  );
  static const caption = TextStyle(
    color: Color(0xFF61736D),
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const label = TextStyle(
    color: Color(0xFF61736D),
    fontSize: 13,
    fontWeight: FontWeight.w800,
  );
}

String _categoryLabel(HistoryCategory category) => switch (category) {
  HistoryCategory.appointments => 'Appointments',
  HistoryCategory.medical => 'Medical Services',
  HistoryCategory.petCare => 'Pet Care Services',
  HistoryCategory.homeVisits => 'Home Visits',
  HistoryCategory.emergency => 'Emergency Services',
  HistoryCategory.queue => 'Queue',
};

String _petCareStatus(PetCareStatus status) => switch (status) {
  PetCareStatus.confirmed => 'Confirmed',
  PetCareStatus.checkedIn => 'Checked In',
  PetCareStatus.inProgress => 'In Progress',
  PetCareStatus.completed => 'Completed',
};

String _homeVisitStatus(HomeVisitStatus status) => switch (status) {
  HomeVisitStatus.confirmed => 'Confirmed',
  HomeVisitStatus.onTheWay => 'On the Way',
  HomeVisitStatus.arrived => 'Arrived',
  HomeVisitStatus.consultation => 'Consultation',
  HomeVisitStatus.treatmentProposed => 'Treatment Proposed',
  HomeVisitStatus.completed => 'Completed',
};

String _queueHistoryStatus(QueueStatus status) => switch (status) {
  QueueStatus.waiting => 'Waiting',
  QueueStatus.almostTurn => 'Almost Your Turn',
  QueueStatus.called => 'Called',
  QueueStatus.inConsultation => 'In Consultation',
  QueueStatus.completed => 'Completed',
};

String _historyDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _historyTime(DateTime date) {
  final hour = date.hour == 0
      ? 12
      : date.hour > 12
      ? date.hour - 12
      : date.hour;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}
