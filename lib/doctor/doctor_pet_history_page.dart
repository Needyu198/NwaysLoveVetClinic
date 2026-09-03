part of 'doctor_portal.dart';

enum _DoctorPetHistoryTab { medical, vaccination }

class DoctorPetHistoryPage extends StatefulWidget {
  const DoctorPetHistoryPage({
    required this.petName,
    required this.currentRecord,
    super.key,
  });

  final String petName;
  final DoctorAppointmentRecord currentRecord;

  @override
  State<DoctorPetHistoryPage> createState() => _DoctorPetHistoryPageState();
}

class _DoctorPetHistoryPageState extends State<DoctorPetHistoryPage> {
  var _selectedTab = _DoctorPetHistoryTab.medical;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('doctor-pet-history-page'),
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            DoctorAppointmentStore.instance,
            AppointmentStore.instance,
            DoctorMedicalRecordStore.instance,
          ]),
          builder: (context, _) {
            final appointments = _appointmentsForPet;
            final visibleAppointments =
                _selectedTab == _DoctorPetHistoryTab.medical
                ? appointments
                : appointments.where(_isVaccinationAppointment).toList();

            return Column(
              children: [
                _DoctorHistoryHeader(
                  title: _selectedTab == _DoctorPetHistoryTab.medical
                      ? 'Medical History'
                      : 'Vaccination History',
                ),
                Expanded(
                  child: visibleAppointments.isEmpty
                      ? _DoctorHistoryEmptyState(tab: _selectedTab)
                      : ListView.separated(
                          key: ValueKey(
                            'doctor-${_selectedTab.name}-history-list',
                          ),
                          padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
                          itemCount: visibleAppointments.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 20),
                          itemBuilder: (context, index) => _DoctorHistoryCard(
                            record: visibleAppointments[index],
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(44, 4, 44, 8),
        child: _DoctorHistoryNavigation(
          selectedTab: _selectedTab,
          onSelected: (tab) => setState(() => _selectedTab = tab),
        ),
      ),
    );
  }

  List<DoctorAppointmentRecord> get _appointmentsForPet {
    final matches = DoctorAppointmentStore.instance.appointments
        .where(
          (item) => item.petName.toLowerCase() == widget.petName.toLowerCase(),
        )
        .toList();
    if (!matches.any((item) => item.id == widget.currentRecord.id)) {
      matches.add(widget.currentRecord);
    }
    matches.sort((a, b) => b.date.compareTo(a.date));
    return matches;
  }

  bool _isVaccinationAppointment(DoctorAppointmentRecord appointment) {
    final service = appointment.service.toLowerCase();
    if (service.contains('vaccin') || service.contains('immun')) return true;
    return DoctorMedicalRecordStore.instance
        .recordsFor(appointment.petName)
        .any(
          (item) =>
              item.appointmentId == appointment.id &&
              item.vaccination.trim().isNotEmpty,
        );
  }
}

class _DoctorHistoryHeader extends StatelessWidget {
  const _DoctorHistoryHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(28, 24, 28, 22),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      boxShadow: [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 5,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        InkWell(
          key: const ValueKey('doctor-pet-history-back'),
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.chevron_left_rounded, size: 28),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DoctorHistoryCard extends StatelessWidget {
  const _DoctorHistoryCard({required this.record});

  final DoctorAppointmentRecord record;

  @override
  Widget build(BuildContext context) {
    final bookingDate = record.source?.createdAt ?? record.date;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 14, 14),
      decoration: BoxDecoration(
        color: DoctorStyles.mint,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          _DoctorHistoryRow(label: 'Booking ID', value: '#${record.id}'),
          _DoctorHistoryRow(
            label: 'Booking Date',
            value: _doctorHistoryDate(bookingDate),
          ),
          _DoctorHistoryRow(
            label: 'Appointment Date',
            value: _doctorHistoryDate(record.date),
          ),
          _DoctorHistoryRow(label: 'Time', value: record.time),
          const _DoctorHistoryRow(
            label: 'Veterinarian',
            value: DoctorAppointmentStore.doctorName,
          ),
          _DoctorHistoryRow(label: 'Status', value: record.status),
          _DoctorHistoryRow(
            label: 'Symptoms',
            value: _doctorHistoryValue(record.symptoms),
          ),
          _DoctorHistoryRow(
            label: 'Visit Reason',
            value: _doctorHistoryValue(record.reason),
          ),
        ],
      ),
    );
  }
}

class _DoctorHistoryRow extends StatelessWidget {
  const _DoctorHistoryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 7),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xAA303030))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9AA9A3),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(color: Color(0xFF9AA9A3), fontSize: 16),
        ),
        Expanded(
          flex: 5,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DoctorHistoryEmptyState extends StatelessWidget {
  const _DoctorHistoryEmptyState({required this.tab});

  final _DoctorPetHistoryTab tab;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tab == _DoctorPetHistoryTab.medical
                ? Icons.medical_information_outlined
                : Icons.vaccines_outlined,
            size: 58,
            color: const Color(0xFF82978F),
          ),
          const SizedBox(height: 14),
          Text(
            tab == _DoctorPetHistoryTab.medical
                ? 'No medical history yet'
                : 'No vaccination history yet',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

class _DoctorHistoryNavigation extends StatelessWidget {
  const _DoctorHistoryNavigation({
    required this.selectedTab,
    required this.onSelected,
  });

  final _DoctorPetHistoryTab selectedTab;
  final ValueChanged<_DoctorPetHistoryTab> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(32),
    ),
    child: Row(
      children: [
        Expanded(
          child: _DoctorHistoryNavigationItem(
            key: const ValueKey('doctor-medical-history-tab'),
            selected: selectedTab == _DoctorPetHistoryTab.medical,
            icon: Icons.medical_services_rounded,
            iconColor: const Color(0xFFD9473D),
            label: 'Medical',
            onTap: () => onSelected(_DoctorPetHistoryTab.medical),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DoctorHistoryNavigationItem(
            key: const ValueKey('doctor-vaccination-history-tab'),
            selected: selectedTab == _DoctorPetHistoryTab.vaccination,
            icon: Icons.vaccines_outlined,
            iconColor: const Color(0xFF789E99),
            label: 'Vaccination',
            onTap: () => onSelected(_DoctorPetHistoryTab.vaccination),
          ),
        ),
      ],
    ),
  );
}

class _DoctorHistoryNavigationItem extends StatelessWidget {
  const _DoctorHistoryNavigationItem({
    required this.selected,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    super.key,
  });

  final bool selected;
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: SizedBox.expand(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 25),
            if (selected) ...[
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(color: Colors.black, fontSize: 17),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

String _doctorHistoryDate(DateTime date) {
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

String _doctorHistoryValue(String value) =>
    value.trim().isEmpty ? '------' : value;
