part of 'staff_portal.dart';

class StaffMessagesPage extends StatefulWidget {
  const StaffMessagesPage({this.standalone = false, super.key});
  final bool standalone;
  @override
  State<StaffMessagesPage> createState() => _StaffMessagesPageState();
}

class _StaffMessagesPageState extends State<StaffMessagesPage> {
  final _reply = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Opening the inbox clears the staff unread badge.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ContactClinicStore.instance.markAllReadByStaff(),
    );
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _StaffScaffold(
    title: 'Messages',
    onBack: widget.standalone ? () => Navigator.pop(context) : null,
    child: AnimatedBuilder(
      animation: ContactClinicStore.instance,
      builder: (_, _) {
        final messages = ContactClinicStore.instance.messages;
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 8, 18, 4),
              child: _Callout(
                icon: Icons.health_and_safety_outlined,
                text:
                    'Forward medical questions to a veterinarian. Escalate emergency content immediately.',
              ),
            ),
            Expanded(
              child: messages.isEmpty
                  ? const Center(child: Text('No owner conversations yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(18),
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        final message = messages[i];
                        return Align(
                          alignment: message.isFromStaff
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(13),
                            constraints: const BoxConstraints(maxWidth: 310),
                            decoration: BoxDecoration(
                              color: message.isFromStaff ? _mint : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.category.label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _muted,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(message.text),
                                if (!message.isFromStaff)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Wrap(
                                      spacing: 4,
                                      children: [
                                        TextButton(
                                          onPressed: () => ContactClinicStore
                                              .instance
                                              .staffUpdateStatus(
                                                message.id,
                                                ContactMessageStatus.read,
                                              ),
                                          child: const Text('Resolve'),
                                        ),
                                        TextButton(
                                          onPressed: () => _notice(
                                            context,
                                            'Forwarded to the on-duty veterinarian.',
                                          ),
                                          child: const Text('Forward'),
                                        ),
                                        if (message.category ==
                                            ContactCategory.emergency)
                                          TextButton(
                                            onPressed: () => _push(
                                              context,
                                              const StaffEmergencyPage(),
                                            ),
                                            child: const Text(
                                              'Escalate',
                                              style: TextStyle(color: _red),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _reply,
                        decoration: _input(
                          'Administrative reply',
                          Icons.reply_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () {
                        if (_reply.text.trim().isEmpty) return;
                        ContactClinicStore.instance.staffReply(
                          _reply.text.trim(),
                        );
                        _reply.clear();
                      },
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
