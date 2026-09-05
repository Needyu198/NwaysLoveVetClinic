part of 'staff_portal.dart';

class StaffReportsPage extends StatefulWidget {
  const StaffReportsPage({super.key});
  @override
  State<StaffReportsPage> createState() => _StaffReportsPageState();
}

class _StaffReportsPageState extends State<StaffReportsPage> {
  var _type = 'Appointments';
  @override
  Widget build(BuildContext context) {
    final items = StaffOperationsStore.instance.appointments;
    final completed = items.where((a) => a.status == 'Completed').length;
    final cancelled = items.where((a) => a.status == 'Cancelled').length;
    return Scaffold(
      backgroundColor: _page,
      appBar: _appBar('Operational Reports'),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: _input('Report type', Icons.bar_chart_rounded),
            items: [
              'Appointments',
              'Queues',
              'Cancellations',
              'Payments',
              'Home Visits',
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ReportMetric(
                  value: '${items.length}',
                  label: 'Total records',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ReportMetric(value: '$completed', label: 'Completed'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ReportMetric(value: '$cancelled', label: 'Cancelled'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 190,
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_type trend',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [45.0, 85.0, 60.0, 110.0, 76.0, 125.0, 96.0]
                      .map(
                        (h) => Container(
                          width: 22,
                          height: h,
                          decoration: BoxDecoration(
                            color: _mint,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(7),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => _showInfo(
              context,
              'Report exported',
              '$_type report generated. Audit recorded for Mya Thu at ${DateTime.now().toLocal()}.',
            ),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Export Report'),
          ),
        ],
      ),
    );
  }
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: _cardDecoration(),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: _muted),
        ),
      ],
    ),
  );
}
