part of 'staff_portal.dart';

class StaffReportsPage extends StatefulWidget {
  const StaffReportsPage({super.key});

  @override
  State<StaffReportsPage> createState() => _StaffReportsPageState();
}

class _StaffReportsPageState extends State<StaffReportsPage> {
  static const _types = [
    'Appointments',
    'Queues',
    'Cancellations',
    'Payments',
    'Home Visits',
  ];

  var _type = _types.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      appBar: _appBar('Operational Reports'),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          StaffOperationsStore.instance,
          AppointmentStore.instance,
          HomeVisitStore.instance,
        ]),
        builder: (context, _) {
          final report = _reportFor(_type);
          return ListView(
            key: const ValueKey('staff-reports-scroll'),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
            children: [
              _ReportsIntro(report: report),
              const SizedBox(height: 20),
              const _ReportsSectionTitle(
                title: 'Report type',
                subtitle: 'Choose the clinic activity you want to review.',
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  key: const ValueKey('staff-report-types'),
                  scrollDirection: Axis.horizontal,
                  itemCount: _types.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final type = _types[index];
                    return ChoiceChip(
                      key: ValueKey('staff-report-type-$type'),
                      label: Text(type),
                      selected: _type == type,
                      onSelected: (_) => setState(() => _type = type),
                      selectedColor: _green,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _type == type ? Colors.white : _ink,
                        fontWeight: FontWeight.w800,
                      ),
                      side: BorderSide(color: _type == type ? _green : _border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const _ReportsSectionTitle(
                title: 'At a glance',
                subtitle: 'Live totals from the clinic workspace.',
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.55,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: report.metrics.length,
                itemBuilder: (context, index) =>
                    _ReportMetricCard(metric: report.metrics[index]),
              ),
              const SizedBox(height: 24),
              _ActivityBreakdown(report: report),
              const SizedBox(height: 18),
              _ReportInsight(text: report.insight),
              const SizedBox(height: 22),
              FilledButton.icon(
                key: const ValueKey('staff-export-report'),
                onPressed: () => _showInfo(
                  context,
                  'Report exported',
                  '$_type report generated. Audit recorded for Mya Thu at ${DateTime.now().toLocal()}.',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                icon: const Icon(Icons.download_rounded),
                label: Text('Export $_type Report'),
              ),
              const SizedBox(height: 10),
              const Text(
                'Exports are recorded in the clinic audit log.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  _ReportViewData _reportFor(String type) {
    final operations = StaffOperationsStore.instance;
    final appointments = operations.appointments;
    switch (type) {
      case 'Queues':
        final queued = appointments
            .where((item) => item.queueNumber.isNotEmpty)
            .toList();
        final waiting = queued
            .where(
              (item) => const {'Waiting', 'Checked In'}.contains(item.status),
            )
            .length;
        final active = queued
            .where(
              (item) =>
                  const {'Called', 'In Consultation'}.contains(item.status),
            )
            .length;
        final urgent = queued.where((item) => item.priority == 'Urgent').length;
        return _ReportViewData(
          type: type,
          icon: Icons.format_list_numbered_rounded,
          description: 'Monitor patient flow and urgent queue demand.',
          metrics: [
            _ReportMetricData(
              'Total queued',
              '${queued.length}',
              queued.length,
              Icons.groups_rounded,
              const Color(0xFF2767C9),
            ),
            _ReportMetricData(
              'Waiting',
              '$waiting',
              waiting,
              Icons.hourglass_top_rounded,
              const Color(0xFFE28B16),
            ),
            _ReportMetricData(
              'In service',
              '$active',
              active,
              Icons.meeting_room_rounded,
              _green,
            ),
            _ReportMetricData(
              'Urgent',
              '$urgent',
              urgent,
              Icons.emergency_rounded,
              _red,
            ),
          ],
          insight: urgent == 0
              ? 'No urgent patients are currently recorded in the queue.'
              : '$urgent urgent patient${urgent == 1 ? '' : 's'} should remain prioritized in the live queue.',
        );
      case 'Cancellations':
        final cancelled = appointments
            .where((item) => item.status == 'Cancelled')
            .length;
        final missed = appointments
            .where((item) => item.status == 'Missed')
            .length;
        final total = appointments.length;
        final rate = total == 0 ? 0 : ((cancelled / total) * 100).round();
        return _ReportViewData(
          type: type,
          icon: Icons.event_busy_rounded,
          description: 'Review released bookings and missed appointments.',
          metrics: [
            _ReportMetricData(
              'Cancelled',
              '$cancelled',
              cancelled,
              Icons.event_busy_rounded,
              _red,
            ),
            _ReportMetricData(
              'Missed',
              '$missed',
              missed,
              Icons.person_off_rounded,
              const Color(0xFFE28B16),
            ),
            _ReportMetricData(
              'Slots released',
              '$cancelled',
              cancelled,
              Icons.event_available_rounded,
              _green,
            ),
            _ReportMetricData(
              'Cancellation rate',
              '$rate%',
              rate,
              Icons.percent_rounded,
              const Color(0xFF6D55C5),
            ),
          ],
          insight: cancelled == 0
              ? 'No appointment cancellations are currently recorded.'
              : '$cancelled appointment slot${cancelled == 1 ? ' was' : 's were'} released after cancellation.',
        );
      case 'Payments':
        final payments = operations.payments;
        final paid = payments.where((item) => item.status == 'Paid').toList();
        final pending = payments.length - paid.length;
        final collected = paid.fold<int>(0, (sum, item) => sum + item.amount);
        final outstanding = payments
            .where((item) => item.status != 'Paid')
            .fold<int>(0, (sum, item) => sum + item.amount);
        return _ReportViewData(
          type: type,
          icon: Icons.payments_rounded,
          description: 'See payment completion and outstanding balances.',
          metrics: [
            _ReportMetricData(
              'Invoices',
              '${payments.length}',
              payments.length,
              Icons.receipt_long_rounded,
              const Color(0xFF2767C9),
            ),
            _ReportMetricData(
              'Paid',
              '${paid.length}',
              paid.length,
              Icons.check_circle_rounded,
              _green,
            ),
            _ReportMetricData(
              'Pending',
              '$pending',
              pending,
              Icons.schedule_rounded,
              const Color(0xFFE28B16),
            ),
            _ReportMetricData(
              'Collected',
              _compactMoney(collected),
              collected,
              Icons.account_balance_wallet_rounded,
              const Color(0xFF6D55C5),
            ),
          ],
          insight: outstanding == 0
              ? 'All recorded invoices are paid.'
              : '${_compactMoney(outstanding)} MMK remains outstanding across $pending invoice${pending == 1 ? '' : 's'}.',
        );
      case 'Home Visits':
        final visits = HomeVisitStore.instance.visits;
        final confirmed = visits
            .where((item) => item.status == HomeVisitStatus.confirmed)
            .length;
        final active = visits
            .where(
              (item) => !const {
                HomeVisitStatus.confirmed,
                HomeVisitStatus.completed,
              }.contains(item.status),
            )
            .length;
        final completed = visits
            .where((item) => item.status == HomeVisitStatus.completed)
            .length;
        return _ReportViewData(
          type: type,
          icon: Icons.home_work_rounded,
          description: 'Track confirmed, active, and completed home visits.',
          metrics: [
            _ReportMetricData(
              'Total visits',
              '${visits.length}',
              visits.length,
              Icons.home_work_rounded,
              const Color(0xFF2767C9),
            ),
            _ReportMetricData(
              'Confirmed',
              '$confirmed',
              confirmed,
              Icons.event_available_rounded,
              const Color(0xFFE28B16),
            ),
            _ReportMetricData(
              'In progress',
              '$active',
              active,
              Icons.route_rounded,
              const Color(0xFF6D55C5),
            ),
            _ReportMetricData(
              'Completed',
              '$completed',
              completed,
              Icons.task_alt_rounded,
              _green,
            ),
          ],
          insight: active == 0
              ? 'No home visits are currently in progress.'
              : '$active home visit${active == 1 ? ' is' : 's are'} currently in progress.',
        );
      default:
        final completed = appointments
            .where((item) => item.status == 'Completed')
            .length;
        final cancelled = appointments
            .where((item) => item.status == 'Cancelled')
            .length;
        final active = appointments.length - completed - cancelled;
        return _ReportViewData(
          type: 'Appointments',
          icon: Icons.calendar_month_rounded,
          description: 'Understand booking volume and appointment outcomes.',
          metrics: [
            _ReportMetricData(
              'Total bookings',
              '${appointments.length}',
              appointments.length,
              Icons.calendar_month_rounded,
              const Color(0xFF2767C9),
            ),
            _ReportMetricData(
              'Active',
              '$active',
              active,
              Icons.pending_actions_rounded,
              const Color(0xFFE28B16),
            ),
            _ReportMetricData(
              'Completed',
              '$completed',
              completed,
              Icons.task_alt_rounded,
              _green,
            ),
            _ReportMetricData(
              'Cancelled',
              '$cancelled',
              cancelled,
              Icons.event_busy_rounded,
              _red,
            ),
          ],
          insight: active == 0
              ? 'There are no active appointments requiring follow-up.'
              : '$active appointment${active == 1 ? '' : 's'} currently require clinic follow-up.',
        );
    }
  }
}

String _compactMoney(int amount) {
  if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
  return '$amount';
}

class _ReportViewData {
  const _ReportViewData({
    required this.type,
    required this.icon,
    required this.description,
    required this.metrics,
    required this.insight,
  });

  final String type;
  final IconData icon;
  final String description;
  final List<_ReportMetricData> metrics;
  final String insight;
}

class _ReportMetricData {
  const _ReportMetricData(
    this.label,
    this.value,
    this.numericValue,
    this.icon,
    this.color,
  );

  final String label;
  final String value;
  final int numericValue;
  final IconData icon;
  final Color color;
}

class _ReportsIntro extends StatelessWidget {
  const _ReportsIntro({required this.report});

  final _ReportViewData report;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFDDF8EC),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFC7EDDE)),
    ),
    child: Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(report.icon, color: _green, size: 31),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.type,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                report.description,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ReportsSectionTitle extends StatelessWidget {
  const _ReportsSectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: _ink,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: const TextStyle(
          color: _muted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _ReportMetricCard extends StatelessWidget {
  const _ReportMetricCard({required this.metric});

  final _ReportMetricData metric;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _border),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: metric.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(metric.icon, color: metric.color, size: 22),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.value,
                maxLines: 1,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                metric.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ActivityBreakdown extends StatelessWidget {
  const _ActivityBreakdown({required this.report});

  final _ReportViewData report;

  @override
  Widget build(BuildContext context) {
    final maximum = report.metrics.fold<int>(
      0,
      (value, metric) =>
          metric.numericValue > value ? metric.numericValue : value,
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity breakdown',
            style: TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Compare the current report totals.',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          for (final metric in report.metrics) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    metric.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  metric.value,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: maximum == 0
                    ? 0
                    : (metric.numericValue / maximum).clamp(0, 1),
                backgroundColor: const Color(0xFFE8EFEC),
                color: metric.color,
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _ReportInsight extends StatelessWidget {
  const _ReportInsight({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4D9),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFFFDF91)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF9A6500)),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF654600),
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
