part of 'staff_portal.dart';

class StaffPaymentsPage extends StatefulWidget {
  const StaffPaymentsPage({super.key});
  @override
  State<StaffPaymentsPage> createState() => _StaffPaymentsPageState();
}

class _StaffPaymentsPageState extends State<StaffPaymentsPage> {
  final Set<String> _busy = {};

  Future<void> _call(
    StaffPayment payment,
    String suffix, [
    Map<String, dynamic>? body,
  ]) async {
    setState(() => _busy.add(payment.id));
    try {
      await ClinicApi.instance.request(
        'POST',
        '/payments/${Uri.encodeComponent(payment.id)}/mmqr$suffix',
        body,
      );
      await DatabaseSync.instance.refreshTable('payments');
    } on ClinicApiException catch (error) {
      if (mounted) _showInfo(context, 'Payment not changed', error.message);
    } finally {
      if (mounted) setState(() => _busy.remove(payment.id));
    }
  }

  Future<Map<String, String>?> _twoFieldDialog({
    required String title,
    required String firstLabel,
    required String secondLabel,
    String help = '',
    bool secondObscured = false,
  }) async {
    final first = TextEditingController();
    final second = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (help.isNotEmpty) ...[
              Text(help, style: const TextStyle(color: _muted)),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: first,
              decoration: InputDecoration(labelText: firstLabel),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: second,
              obscureText: secondObscured,
              maxLines: secondObscured ? 1 : 3,
              decoration: InputDecoration(labelText: secondLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, {
              'first': first.text.trim(),
              'second': second.text.trim(),
            }),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    first.dispose();
    second.dispose();
    return result;
  }

  Future<void> _providerSettlement(StaffPayment payment) async {
    final mmqr = payment.mmqr!;
    final result = await _twoFieldDialog(
      title: 'Verify provider settlement',
      firstLabel: 'Provider transaction ID',
      secondLabel: 'Provider settlement proof',
      help:
          'The proof must come from the configured MMQR provider. A transaction ID alone cannot mark this invoice paid.',
      secondObscured: true,
    );
    if (result == null) return;
    await _call(payment, '/settle', {
      'reference': mmqr.reference,
      'amount': payment.amount,
      'providerTransactionId': result['first'],
      'settlementProof': result['second'],
    });
  }

  Future<void> _reconcile(StaffPayment payment) async {
    final result = await _twoFieldDialog(
      title: 'Reconcile MMQR receipt',
      firstLabel: 'Receipt reference',
      secondLabel: 'Reconciliation note',
      help:
          'Use only after independently checking the settlement. This is labeled as staff reconciliation in the permanent audit history.',
    );
    if (result == null) return;
    await _call(payment, '/reconcile', {
      'reference': payment.mmqr!.reference,
      'amount': payment.amount,
      'receiptReference': result['first'],
      'note': result['second'],
    });
  }

  Future<void> _cancel(StaffPayment payment) async {
    final reason = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel pending MMQR'),
        content: TextField(
          controller: reason,
          decoration: const InputDecoration(labelText: 'Cancellation reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep pending'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, reason.text.trim()),
            child: const Text('Cancel payment'),
          ),
        ],
      ),
    );
    reason.dispose();
    if (result != null) await _call(payment, '/cancel', {'reason': result});
  }

  void _showAudit(StaffPayment payment) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('${payment.id} audit history'),
      content: SizedBox(
        width: 520,
        child: payment.auditTrail.isEmpty
            ? const Text('No MMQR lifecycle events have been recorded.')
            : ListView.separated(
                shrinkWrap: true,
                itemCount: payment.auditTrail.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (_, index) {
                  final event = payment.auditTrail.reversed.toList()[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.verified_user_outlined),
                    title: Text(event.action),
                    subtitle: Text(
                      '${event.fromStatus} → ${event.toStatus}\n'
                      '${event.at.toLocal()} • ${event.actorRole}: ${event.actorId}',
                    ),
                  );
                },
              ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Done'),
        ),
      ],
    ),
  );

  Color _statusColor(String status) => switch (status) {
    'Paid' => _green,
    'Pending' => const Color(0xFFB26A00),
    _ => _red,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    appBar: _appBar('Billing & Payments'),
    body: AnimatedBuilder(
      animation: StaffOperationsStore.instance,
      builder: (context, _) => ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: StaffOperationsStore.instance.payments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final payment = StaffOperationsStore.instance.payments[index];
          final mmqr = payment.mmqr;
          final busy = _busy.contains(payment.id);
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFE6FAF2),
                      child: Icon(Icons.qr_code_2_rounded, color: _green),
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
                          style: TextStyle(color: _statusColor(payment.status)),
                        ),
                      ],
                    ),
                  ],
                ),
                if (mmqr != null) ...[
                  const Divider(height: 24),
                  Text(
                    'MMQR reference: ${mmqr.reference}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    mmqr.qrPayload,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MMQR status: ${mmqr.status} • Audit events: ${payment.auditTrail.length}',
                    style: const TextStyle(color: _muted),
                  ),
                ],
                const Divider(height: 24),
                if (busy)
                  const Center(child: CircularProgressIndicator())
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if ((payment.status == 'Unpaid' ||
                              payment.status == 'Failed') &&
                          !payment.hasPendingMmqr)
                        FilledButton.icon(
                          onPressed: () => _call(payment, ''),
                          icon: const Icon(Icons.qr_code_rounded),
                          label: const Text('Create MMQR'),
                        ),
                      if (payment.hasPendingMmqr) ...[
                        FilledButton.icon(
                          onPressed: () => _providerSettlement(payment),
                          icon: const Icon(Icons.verified_rounded),
                          label: const Text('Verify provider settlement'),
                        ),
                        OutlinedButton(
                          onPressed: () => _reconcile(payment),
                          child: const Text('Reconcile receipt'),
                        ),
                        TextButton(
                          onPressed: () => _cancel(payment),
                          child: const Text('Cancel MMQR'),
                        ),
                      ],
                      OutlinedButton.icon(
                        onPressed: () => _showAudit(payment),
                        icon: const Icon(Icons.history_rounded),
                        label: const Text('Audit history'),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
