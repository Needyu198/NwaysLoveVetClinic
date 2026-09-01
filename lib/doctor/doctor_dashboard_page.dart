part of 'doctor_portal.dart';

class DoctorDashboardPage extends StatelessWidget {
  const DoctorDashboardPage({
    required this.onOpenAppointments,
    required this.onOpenProfile,
    super.key,
  });

  final ValueChanged<String> onOpenAppointments;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        DoctorAppointmentStore.instance,
        AppointmentStore.instance,
        EmergencyRequestStore.instance,
      ]),
      builder: (context, _) {
        final records = DoctorAppointmentStore.instance.appointments;
        final today = records
            .where(
              (record) =>
                  DateUtils.isSameDay(record.date, DateTime.now()) &&
                  record.status != 'Cancelled',
            )
            .toList();
        final completed = today
            .where((record) => record.status == 'Completed')
            .length;
        final waiting = today
            .where((record) => record.status != 'Completed')
            .length;
        final upNext = today
            .where(
              (record) => !const {
                'Completed',
                'Cancelled',
                'In Consultation',
              }.contains(record.status),
            )
            .toList();
        final emergencyCases = EmergencyRequestStore.instance.requests
            .where(
              (request) => !const {
                EmergencyStatus.completed,
                EmergencyStatus.declined,
              }.contains(request.status),
            )
            .toList();
        return ListView(
          key: const ValueKey('doctor-dashboard'),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
          children: [
            Text('${_greeting()}, Dr. Aye Chan', style: DoctorStyles.title),
            const SizedBox(height: 5),
            Text(_fullDate(DateTime.now()), style: DoctorStyles.muted),
            const SizedBox(height: 22),
            _DashboardStatCard(
              key: const ValueKey('doctor-emergency-stat'),
              label: 'Emergency Cases',
              value: '${emergencyCases.length}',
              icon: Icons.emergency_rounded,
              color: const Color(0xFFE92832),
              foregroundColor: Colors.white,
              horizontal: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DoctorEmergencyCasesPage(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DashboardStatCard(
                    key: const ValueKey('doctor-waiting-stat'),
                    label: 'Waiting',
                    value: '$waiting',
                    icon: Icons.groups_2_outlined,
                    color: DoctorStyles.mint,
                    onTap: () => onOpenAppointments('Waiting'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DashboardStatCard(
                    key: const ValueKey('doctor-completed-stat'),
                    label: 'Completed',
                    value: '$completed',
                    icon: Icons.task_alt_rounded,
                    color: DoctorStyles.mint,
                    onTap: () => onOpenAppointments('Completed'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DashboardStatCard(
              key: const ValueKey('doctor-total-stat'),
              label: 'Today Total Appointments',
              value: '${today.length}',
              icon: Icons.calendar_today_rounded,
              color: DoctorStyles.mint,
              horizontal: true,
              onTap: () => onOpenAppointments('Today'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text('Up Next', style: DoctorStyles.section),
                ),
                TextButton(
                  key: const ValueKey('doctor-view-all-appointments'),
                  onPressed: () => onOpenAppointments('All'),
                  child: const Text('View All Appointments'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (emergencyCases.isNotEmpty) ...[
              for (final emergency in emergencyCases.take(2)) ...[
                _EmergencyQueueCard(request: emergency),
                const SizedBox(height: 10),
              ],
            ],
            if (upNext.isEmpty && emergencyCases.isEmpty)
              const _EmptyDoctorState(
                icon: Icons.event_available_rounded,
                title: 'No patients waiting',
                message: 'Today’s active queue is clear.',
              )
            else ...[
              for (var index = 0; index < upNext.length; index++) ...[
                _UpNextCard(
                  record: upNext[index],
                  canStart: index == 0 && emergencyCases.isEmpty,
                ),
                const SizedBox(height: 10),
              ],
            ],
            const SizedBox(height: 18),
            const Text('Quick Menu', style: DoctorStyles.section),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('doctor-write-post'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DoctorCreatePostPage(),
                      ),
                    ),
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Write a Post'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(58),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('doctor-medical-records'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DoctorMedicalRecordsPage(),
                      ),
                    ),
                    icon: const Icon(Icons.medical_information_outlined),
                    label: const Text('Medical Records'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(58),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const ValueKey('doctor-dashboard-profile'),
              onPressed: onOpenProfile,
              icon: const Icon(Icons.manage_accounts_outlined),
              label: const Text('Profile & Account Settings'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        );
      },
    );
  }
}
