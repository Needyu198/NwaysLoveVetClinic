part of 'staff_portal.dart';

class StaffPaymentsPage extends StatefulWidget {
  const StaffPaymentsPage({super.key});
  @override
  State<StaffPaymentsPage> createState() => _StaffPaymentsPageState();
}

class _StaffPaymentsPageState extends State<StaffPaymentsPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    appBar: _appBar('Billing & Payments'),
    body: ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: StaffOperationsStore.instance.payments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final payment = StaffOperationsStore.instance.payments[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFE6FAF2),
                    child: Icon(Icons.receipt_long_rounded, color: _green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.id,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '${payment.pet} • ${payment.owner}',
                          style: const TextStyle(color: _muted),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${payment.amount} MMK',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        payment.status,
                        style: TextStyle(
                          color: payment.status == 'Paid' ? _green : _red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (payment.status != 'Paid') ...[
                const Divider(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final method = await showModalBottomSheet<String>(
                        context: context,
                        builder: (_) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                [
                                      'Cash',
                                      'Card',
                                      'Bank Transfer',
                                      'Online Payment',
                                    ]
                                    .map(
                                      (m) => ListTile(
                                        title: Text(m),
                                        leading: const Icon(
                                          Icons.payments_outlined,
                                        ),
                                        onTap: () => Navigator.pop(context, m),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      );
                      if (method != null) {
                        setState(() => payment.status = 'Paid');
                        if (context.mounted) {
                          _showInfo(
                            context,
                            'Payment recorded',
                            'Receipt generated for ${payment.id} • $method. The audit entry cannot be deleted.',
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirm Payment'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}
