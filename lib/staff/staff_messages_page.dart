part of 'staff_portal.dart';

class StaffMessagesPage extends StatefulWidget {
  const StaffMessagesPage({this.standalone = false, super.key});
  final bool standalone;
  @override
  State<StaffMessagesPage> createState() => _StaffMessagesPageState();
}

class _StaffMessagesPageState extends State<StaffMessagesPage> {
  final _reply = TextEditingController();
  String? _conversationId;

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
        final conversations = <String, List<ClinicContactMessage>>{};
        for (final message in messages) {
          conversations
              .putIfAbsent(_conversationKey(message), () => [])
              .add(message);
        }
        for (final thread in conversations.values) {
          thread.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        }
        if (_conversationId == null) {
          return _ConversationList(
            conversations: conversations,
            onOpen: (id, thread) {
              ContactClinicStore.instance.markReadByStaff(
                thread.map((message) => message.id),
              );
              setState(() => _conversationId = id);
            },
          );
        }
        final thread = conversations[_conversationId] ?? const [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 18, 4),
              child: Row(
                children: [
                  TextButton.icon(
                    key: const ValueKey('staff-all-conversations'),
                    onPressed: () => setState(() => _conversationId = null),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('All conversations'),
                  ),
                  const Spacer(),
                  Text(
                    _conversationTitle(thread),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                key: const ValueKey('staff-conversation-thread'),
                padding: const EdgeInsets.all(18),
                itemCount: thread.length,
                itemBuilder: (_, i) {
                  final message = thread[i];
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
                          if (!message.isFromStaff)
                            const Text(
                              'Pet Owner',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
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
                                    onPressed: () => ContactClinicStore.instance
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
                      key: const ValueKey('staff-send-conversation-reply'),
                      onPressed: () {
                        if (_reply.text.trim().isEmpty) return;
                        final ownerMessage = thread
                            .where((message) => !message.isFromStaff)
                            .cast<ClinicContactMessage?>()
                            .firstWhere(
                              (message) => message != null,
                              orElse: () => null,
                            );
                        final ownerId = ownerMessage == null
                            ? null
                            : databaseOwnerOf(ownerMessage);
                        if (ownerId == null && DatabaseSync.instance.active) {
                          _notice(
                            context,
                            'This conversation is not linked to an owner account.',
                          );
                          return;
                        }
                        ContactClinicStore.instance.staffReply(
                          _reply.text.trim(),
                          ownerId: ownerId,
                          conversationId: _conversationId,
                          petName: thread
                              .map((message) => message.petName)
                              .whereType<String>()
                              .lastOrNull,
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

  String _conversationKey(ClinicContactMessage message) {
    if (message.conversationId.isNotEmpty) return message.conversationId;
    final ownerId = databaseOwnerOf(message);
    if (ownerId != null && ownerId.isNotEmpty) return 'owner:$ownerId';
    return 'pet:${message.petName ?? 'general'}';
  }

  String _conversationTitle(List<ClinicContactMessage> thread) {
    for (final message in thread.reversed) {
      if (message.petName?.trim().isNotEmpty == true) {
        return '${message.petName} owner';
      }
    }
    return 'Pet Owner';
  }
}

class _ConversationList extends StatelessWidget {
  const _ConversationList({required this.conversations, required this.onOpen});

  final Map<String, List<ClinicContactMessage>> conversations;
  final void Function(String, List<ClinicContactMessage>) onOpen;

  @override
  Widget build(BuildContext context) {
    final entries = conversations.entries.toList()
      ..sort(
        (a, b) => b.value.last.createdAt.compareTo(a.value.last.createdAt),
      );
    if (entries.isEmpty) {
      return const Center(child: Text('No owner conversations yet'));
    }
    return ListView.separated(
      key: const ValueKey('staff-conversation-list'),
      padding: const EdgeInsets.all(18),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final latest = entry.value.last;
        final petName = entry.value
            .map((message) => message.petName)
            .whereType<String>()
            .where((name) => name.trim().isNotEmpty)
            .lastOrNull;
        final unread = entry.value
            .where(
              (message) =>
                  !message.isFromStaff &&
                  message.status != ContactMessageStatus.read,
            )
            .length;
        return ListTile(
          key: ValueKey('staff-conversation-${entry.key}'),
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _border),
          ),
          leading: const CircleAvatar(
            backgroundColor: _mint,
            foregroundColor: _green,
            child: Icon(Icons.person_rounded),
          ),
          title: Text(
            petName == null ? 'Pet Owner' : '$petName owner',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            latest.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: unread == 0
              ? const Icon(Icons.chevron_right_rounded)
              : CircleAvatar(
                  radius: 13,
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  child: Text('$unread', style: const TextStyle(fontSize: 11)),
                ),
          onTap: () => onOpen(entry.key, entry.value),
        );
      },
    );
  }
}
