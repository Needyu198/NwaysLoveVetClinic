import '../data/database_sync.dart';
import '../data/clinic_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'clinic_phone.dart';
import 'pet_owner_page_header.dart';

class ContactClinicPage extends StatelessWidget {
  const ContactClinicPage({super.key});

  static const routeName = '/contact-clinic';
  static const clinicName = "Nway's Love Vet Clinic";
  static const phonePrimary = '09-5312717';
  static const phoneSecondary = '09-965805940';
  static const email = 'contact@nwayslovevetclinic.com';
  static const address =
      'Chindwin street, Mingalardipa quarter, Popba Thiri Township, Nay Pyi Taw';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      body: SafeArea(
        child: Column(
          children: [
            PetOwnerPageHeader(
              title: 'Contact Clinic',
              actions: [
                IconButton(
                  key: const ValueKey('contact-history'),
                  tooltip: 'Contact history',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ClinicConversationPage(),
                    ),
                  ),
                  icon: const Icon(Icons.history_rounded),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                key: const ValueKey('contact-clinic-content'),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  const _ClinicInformationCard(),
                  const SizedBox(height: 22),
                  _ClinicAiChatCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ClinicAiChatPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'How would you like to contact us?',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    children: [
                      _ContactMethodCard(
                        key: const ValueKey('contact-call'),
                        icon: Icons.call_outlined,
                        title: 'Call Clinic',
                        subtitle: 'Speak with clinic staff',
                        onTap: () => _confirmCall(context),
                      ),
                      _ContactMethodCard(
                        key: const ValueKey('contact-directions'),
                        icon: Icons.directions_outlined,
                        title: 'Directions',
                        subtitle: 'View or copy our address',
                        onTap: () => _showDirections(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClinicAiChatCard extends StatelessWidget {
  const _ClinicAiChatCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFE5FFF5),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      key: const ValueKey('clinic-ai-chat-entry'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFB8F1DB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF167A58),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ask the Clinic Assistant',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Get help with services, hours, and booking',
                    style: TextStyle(fontSize: 13, color: Color(0xFF52625C)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

class ClinicAiChatPage extends StatefulWidget {
  const ClinicAiChatPage({super.key});

  @override
  State<ClinicAiChatPage> createState() => _ClinicAiChatPageState();
}

class _ClinicAiChatPageState extends State<ClinicAiChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<(String, bool)> _messages = [
    (
      "Hello! I'm the Nway's Love Vet Clinic assistant. I can help with clinic services, hours, and booking. What would you like to know?",
      false,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? prompt]) {
    final message = (prompt ?? _controller.text).trim();
    if (message.isEmpty) return;
    setState(() {
      _messages.add((message, true));
      _messages.add((
        "Thanks for your question. The clinic assistant will be connected when the AI service is configured. For medical advice, please contact the clinic directly.",
        false,
      ));
      _controller.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FAF9),
    body: SafeArea(
      child: Column(
        children: [
          const PetOwnerPageHeader(title: 'Clinic Assistant'),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'For clinic information only. This assistant does not diagnose or prescribe. For medical advice, please contact the clinic.',
              style: TextStyle(fontSize: 12.5, height: 1.35),
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                if (_messages.length == 1) ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: Text(
                      'You can ask about',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF52625C),
                      ),
                    ),
                  ),
                  _suggestion('What services do you offer?'),
                  _suggestion('How do I book an appointment?'),
                  _suggestion('What are the clinic hours?'),
                  const SizedBox(height: 18),
                ],
                for (final (text, isUser) in _messages)
                  Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * .82,
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isUser ? const Color(0xFFB8F1DB) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x10000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(text, style: const TextStyle(height: 1.35)),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('clinic-ai-chat-input'),
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Ask a question…',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const ValueKey('clinic-ai-chat-send'),
                    onPressed: _send,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF9BE6C8),
                      foregroundColor: const Color(0xFF123D2E),
                    ),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _suggestion(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ActionChip(
        label: Text(text),
        onPressed: () => _send(text),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFDCE8E4)),
      ),
    ),
  );
}

class ClinicConversationPage extends StatefulWidget {
  const ClinicConversationPage({super.key});

  @override
  State<ClinicConversationPage> createState() => _ClinicConversationPageState();
}

class _ClinicConversationPageState extends State<ClinicConversationPage> {
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedPet;
  ContactCategory _category = ContactCategory.other;

  static const _pets = ['Max', 'Bella', 'Luna', 'Bruno'];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      body: SafeArea(
        child: Column(
          children: [
            const PetOwnerPageHeader(title: 'Chat with Clinic'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: const Color(0xFFFFF4D6),
              child: const Text(
                'Clinic hours: 8:00 AM–7:00 PM. After-hours replies depend on staff availability. Chat advice does not replace an examination.',
                style: TextStyle(fontSize: 12.5, height: 1.3),
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: ContactClinicStore.instance,
                builder: (context, _) {
                  final messages = ContactClinicStore.instance.messages;
                  if (messages.isEmpty) {
                    return const _EmptyConversation();
                  }
                  return ListView.builder(
                    key: const ValueKey('clinic-conversation-list'),
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) =>
                        _MessageBubble(message: messages[index]),
                  );
                },
              ),
            ),
            _MessageComposer(
              formKey: _formKey,
              controller: _messageController,
              selectedPet: _selectedPet,
              category: _category,
              pets: _pets,
              onPetChanged: (value) => setState(() => _selectedPet = value),
              onCategoryChanged: (value) => setState(() => _category = value),
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ContactClinicStore.instance.send(
      text: _messageController.text.trim(),
      category: _category,
      petName: _selectedPet,
    );
    _messageController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message sent • Clinic staff notified')),
    );
  }
}

class ContactClinicStore extends ChangeNotifier {
  void connectDatabase() {
    DatabaseSync.instance.bind(
      'clinic_messages',
      this,
      () => {
        for (final item in _messages)
          databaseRecordKey(item, item.id): item.toDb(),
      },
      (rows) {
        _messages
          ..clear()
          ..addAll(
            rows.entries.map(
              (e) => databaseRestoreKey(
                ClinicContactMessage.fromDb(e.value),
                e.key,
              ),
            ),
          );
      },
    );
  }

  ContactClinicStore._();

  static final instance = ContactClinicStore._();
  final List<ClinicContactMessage> _messages = [];

  List<ClinicContactMessage> get messages => List.unmodifiable(_messages);

  /// Owner messages the clinic has not marked as read yet.
  int get staffUnreadCount => _messages
      .where((m) => !m.isFromStaff && m.status != ContactMessageStatus.read)
      .length;

  /// Marks every owner message as read (called when staff open Messages).
  void markAllReadByStaff() {
    var changed = false;
    for (final message in _messages) {
      if (!message.isFromStaff && message.status != ContactMessageStatus.read) {
        message.status = ContactMessageStatus.read;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void markReadByStaff(Iterable<String> messageIds) {
    final ids = messageIds.toSet();
    var changed = false;
    for (final message in _messages) {
      if (ids.contains(message.id) &&
          !message.isFromStaff &&
          message.status != ContactMessageStatus.read) {
        message.status = ContactMessageStatus.read;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void send({
    required String text,
    required ContactCategory category,
    String? petName,
  }) {
    final ownerId = ClinicApi.instance.accountId;
    _messages.add(
      ClinicContactMessage(
        id: 'MSG-${DateTime.now().microsecondsSinceEpoch}',
        text: text,
        createdAt: DateTime.now(),
        category: category,
        petName: petName,
        status: ContactMessageStatus.sent,
        isFromStaff: false,
        conversationId: ownerId.isEmpty ? '' : 'owner:$ownerId',
        senderId: ownerId,
        recipientId: 'clinic',
      ),
    );
    notifyListeners();
  }

  void staffUpdateStatus(String id, ContactMessageStatus status) {
    final message = _messages.firstWhere((item) => item.id == id);
    message.status = status;
    notifyListeners();
  }

  void staffReply(
    String text, {
    String? ownerId,
    String? conversationId,
    String? petName,
  }) {
    final resolvedOwnerId = ownerId ?? '';
    final reply = ClinicContactMessage(
      id: 'STAFF-${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      createdAt: DateTime.now(),
      category: ContactCategory.other,
      status: ContactMessageStatus.read,
      isFromStaff: true,
      conversationId:
          conversationId ??
          (resolvedOwnerId.isEmpty ? '' : 'owner:$resolvedOwnerId'),
      senderId: ClinicApi.instance.accountId,
      recipientId: resolvedOwnerId,
      petName: petName,
    );
    _messages.add(databaseAssignOwner(reply, reply.id, ownerId));
    notifyListeners();
  }

  @visibleForTesting
  void clear() {
    _messages.clear();
    notifyListeners();
  }
}

enum ContactCategory {
  appointment('Appointment'),
  medicalService('Medical Service'),
  petCare('Pet Care'),
  other('Other');

  const ContactCategory(this.label);
  final String label;
}

enum ContactMessageStatus {
  pending('Pending'),
  sent('Sent'),
  delivered('Delivered'),
  read('Read');

  const ContactMessageStatus(this.label);
  final String label;
}

class ClinicContactMessage {
  Map<String, dynamic> toDb() => {
    'id': id,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'category': category.name,
    'isFromStaff': isFromStaff,
    'petName': petName,
    'status': status.name,
    'conversationId': conversationId,
    'senderId': senderId,
    'recipientId': recipientId,
  };
  static ClinicContactMessage fromDb(Map<String, dynamic> data) {
    final value = ClinicContactMessage(
      id: data['id'] as String,
      text: data['text'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
      category: ContactCategory.values.byName(data['category'] as String),
      isFromStaff: data['isFromStaff'] as bool,
      petName: data['petName'] == null ? null : data['petName'] as String,
      status: ContactMessageStatus.values.byName(data['status'] as String),
      conversationId: data['conversationId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      recipientId: data['recipientId'] as String? ?? '',
    );
    return value;
  }

  ClinicContactMessage({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.category,
    required this.status,
    required this.isFromStaff,
    this.petName,
    this.conversationId = '',
    this.senderId = '',
    this.recipientId = '',
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final ContactCategory category;
  final bool isFromStaff;
  final String? petName;
  final String conversationId;
  final String senderId;
  final String recipientId;
  ContactMessageStatus status;
}

class _ClinicInformationCard extends StatelessWidget {
  const _ClinicInformationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8E5E0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ContactClinicPage.clinicName,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 16),
          _InformationRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: ContactClinicPage.address,
          ),
          _InformationRow(
            icon: Icons.schedule_rounded,
            label: 'Clinic hours',
            value: '8:00 AM–7:00 PM',
          ),
          _InformationRow(
            icon: Icons.call_outlined,
            label: 'Phone',
            value:
                '${ContactClinicPage.phonePrimary}\n${ContactClinicPage.phoneSecondary}',
          ),
          _InformationRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: ContactClinicPage.email,
            bottomPadding: 0,
          ),
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
    this.bottomPadding = 14,
  });

  final IconData icon;
  final String label;
  final String value;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: const Color(0xFF24845F)),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactMethodCard extends StatelessWidget {
  const _ContactMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFD8E5E0)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF177D58)),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF56635F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 52, color: Color(0xFF7A9189)),
            SizedBox(height: 12),
            Text(
              'No messages yet',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 5),
            Text(
              'Choose an optional pet, select a category, and send your question.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ClinicContactMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isFromStaff
          ? Alignment.centerLeft
          : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: message.isFromStaff ? Colors.white : const Color(0xFFD9FFF0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD1E0DA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.isFromStaff ? 'Clinic Staff' : 'You',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(message.text, style: const TextStyle(height: 1.35)),
            if (message.petName != null) ...[
              const SizedBox(height: 7),
              Text(
                'Pet: ${message.petName}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              '${message.category.label} • ${message.status.label}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF52625D)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.formKey,
    required this.controller,
    required this.selectedPet,
    required this.category,
    required this.pets,
    required this.onPetChanged,
    required this.onCategoryChanged,
    required this.onSend,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final String? selectedPet;
  final ContactCategory category;
  final List<String> pets;
  final ValueChanged<String?> onPetChanged;
  final ValueChanged<ContactCategory> onCategoryChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        key: const ValueKey('contact-select-pet'),
                        initialValue: selectedPet,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Pet (optional)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('No pet attached'),
                          ),
                          ...pets.map(
                            (pet) => DropdownMenuItem<String?>(
                              value: pet,
                              child: Text(pet),
                            ),
                          ),
                        ],
                        onChanged: onPetChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<ContactCategory>(
                        key: const ValueKey('contact-message-category'),
                        initialValue: category,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: ContactCategory.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(
                                  item.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) onCategoryChanged(value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const ValueKey('contact-message-field'),
                        controller: controller,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          hintText: 'Type your message…',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter a message before sending'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      key: const ValueKey('contact-send-message'),
                      tooltip: 'Send',
                      onPressed: onSend,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmCall(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Call Clinic?'),
      content: const Text('Call ${ContactClinicPage.phonePrimary}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Confirm Call'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final opened = await openClinicPhoneApp(ContactClinicPage.phonePrimary);
  if (opened || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Clinic phone number'),
      content: const Text(
        'If the phone application does not open automatically, call manually:\n\n${ContactClinicPage.phonePrimary}\n${ContactClinicPage.phoneSecondary}',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(
              const ClipboardData(text: ContactClinicPage.phonePrimary),
            );
            Navigator.of(dialogContext).pop();
          },
          child: const Text('Copy Number'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}

Future<void> _showDirections(BuildContext context) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: const Text('Clinic Directions'),
    content: const Text(
      '${ContactClinicPage.address}\n\nIf a map application is unavailable, use this address for navigation.',
    ),
    actions: [
      TextButton(
        onPressed: () {
          Clipboard.setData(
            const ClipboardData(text: ContactClinicPage.address),
          );
          Navigator.of(dialogContext).pop();
        },
        child: const Text('Copy Address'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(dialogContext).pop(),
        child: const Text('Done'),
      ),
    ],
  ),
);
