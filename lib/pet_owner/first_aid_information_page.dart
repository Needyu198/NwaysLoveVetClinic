import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'emergency_service_page.dart';

const _firstAidMint = Color(0xFFA1FDD8);
const _firstAidDark = Color(0xFF10231D);
const _firstAidRed = Color(0xFFC62828);

class FirstAidInformationPage extends StatefulWidget {
  const FirstAidInformationPage({super.key});

  static const routeName = '/first-aid-information';

  @override
  State<FirstAidInformationPage> createState() =>
      _FirstAidInformationPageState();
}

class _FirstAidInformationPageState extends State<FirstAidInformationPage> {
  String _petType = 'Dog';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFA),
      appBar: AppBar(
        title: const Text('First Aid Information'),
        backgroundColor: _firstAidMint,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            key: const ValueKey('saved-first-aid-guides'),
            tooltip: 'Saved guides',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SavedFirstAidGuidesPage(),
              ),
            ),
            icon: const Icon(Icons.bookmark_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        key: const ValueKey('first-aid-topic-list'),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        children: [
          const _EmergencyNotice(),
          const SizedBox(height: 20),
          const Text(
            'Choose pet type',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: ['Dog', 'Cat', 'Other']
                .map(
                  (type) => ChoiceChip(
                    key: ValueKey('first-aid-pet-$type'),
                    label: Text(type),
                    selected: _petType == type,
                    onSelected: (_) => setState(() => _petType = type),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'First aid topics',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          const Text(
            'Read-only guidance available without a booking or internet connection.',
            style: TextStyle(color: Color(0xFF53635E), height: 1.35),
          ),
          const SizedBox(height: 14),
          ...firstAidGuides.map(
            (guide) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Color(0xFFD7E4DF)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  key: ValueKey('first-aid-topic-${guide.id}'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE3FFF4),
                    foregroundColor: _firstAidDark,
                    child: Icon(guide.icon),
                  ),
                  title: Text(
                    guide.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(guide.summary),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openGuide(context, guide, _petType),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FirstAidGuidePage extends StatefulWidget {
  const FirstAidGuidePage({
    required this.guide,
    required this.petType,
    super.key,
  });

  final FirstAidGuide guide;
  final String petType;

  @override
  State<FirstAidGuidePage> createState() => _FirstAidGuidePageState();
}

class _FirstAidGuidePageState extends State<FirstAidGuidePage> {
  bool? _needsEmergencyHelp;

  FirstAidGuide get guide => widget.guide;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFA),
      appBar: AppBar(
        title: Text(guide.title),
        backgroundColor: _firstAidMint,
        surfaceTintColor: Colors.transparent,
        actions: [
          AnimatedBuilder(
            animation: FirstAidSavedStore.instance,
            builder: (context, _) {
              final saved = FirstAidSavedStore.instance.contains(guide.id);
              return IconButton(
                key: const ValueKey('save-first-aid-guide'),
                tooltip: saved ? 'Remove saved guide' : 'Save guide',
                onPressed: () => FirstAidSavedStore.instance.toggle(guide.id),
                icon: Icon(
                  saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                ),
              );
            },
          ),
          IconButton(
            key: const ValueKey('share-first-aid-guide'),
            tooltip: 'Share guide',
            onPressed: () => _showShareSheet(context),
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: ListView(
        key: const ValueKey('first-aid-guide-content'),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8E8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: _firstAidRed),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'First aid may help during transport, but it does not replace veterinary treatment. If your pet is unconscious or cannot breathe, seek emergency care now.',
                    style: TextStyle(fontWeight: FontWeight.w700, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '${widget.petType} guide',
            style: const TextStyle(
              color: Color(0xFF436159),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            guide.warning,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          if (widget.petType == 'Other') ...[
            const SizedBox(height: 10),
            const Text(
              'Species differ. Contact the clinic before handling an unfamiliar or exotic pet.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
          _Section(title: 'Possible signs', items: guide.symptoms),
          _StepsSection(items: guide.steps),
          _Section(
            title: 'Do not',
            items: guide.avoid,
            icon: Icons.block_rounded,
            iconColor: _firstAidRed,
            background: const Color(0xFFFFF3F3),
          ),
          _Section(
            title: 'Helpful materials',
            items: guide.materials,
            icon: Icons.check_circle_outline_rounded,
          ),
          const SizedBox(height: 22),
          const Text(
            'Does your pet need professional help now?',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Yes')),
              ButtonSegment(value: false, label: Text('Not sure / No')),
            ],
            emptySelectionAllowed: true,
            selected: _needsEmergencyHelp == null
                ? <bool>{}
                : <bool>{_needsEmergencyHelp!},
            onSelectionChanged: (selection) => setState(
              () => _needsEmergencyHelp = selection.isEmpty
                  ? null
                  : selection.first,
            ),
          ),
          if (_needsEmergencyHelp != null) ...[
            const SizedBox(height: 14),
            Text(
              _needsEmergencyHelp!
                  ? 'Do not delay. Contact the clinic and prepare safe transport.'
                  : 'Continue close monitoring. Contact the clinic if signs persist, worsen, or you are unsure.',
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('first-aid-emergency-service'),
            style: FilledButton.styleFrom(
              backgroundColor: _firstAidRed,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () =>
                Navigator.of(context).pushNamed(EmergencyServicePage.routeName),
            icon: const Icon(Icons.emergency_rounded),
            label: const Text('Open Emergency Service'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('first-aid-call-clinic'),
                  onPressed: () => _confirmClinicCall(context),
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('Call Clinic'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('first-aid-directions'),
                  onPressed: () => _showDirections(context),
                  icon: const Icon(Icons.directions_outlined),
                  label: const Text('Directions'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          const Text(
            'Related topics',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: guide.relatedIds.map((id) {
              final related = firstAidGuides.firstWhere(
                (item) => item.id == id,
              );
              return ActionChip(
                label: Text(related.title),
                onPressed: () => _openGuide(context, related, widget.petType),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _showShareSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share First Aid Guide',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text('Copy a short, safety-focused version to share.'),
            const SizedBox(height: 16),
            ListTile(
              key: const ValueKey('copy-first-aid-guide'),
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy guide text'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: _shareText));
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Guide copied to clipboard')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String get _shareText => [
    '${guide.title} — pet first aid guidance',
    guide.warning,
    ...guide.steps.asMap().entries.map(
      (entry) => '${entry.key + 1}. ${entry.value}',
    ),
    'First aid does not replace veterinary treatment.',
  ].join('\n');
}

class SavedFirstAidGuidesPage extends StatelessWidget {
  const SavedFirstAidGuidesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved First Aid Guides'),
        backgroundColor: _firstAidMint,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: FirstAidSavedStore.instance,
        builder: (context, _) {
          final saved = firstAidGuides
              .where((guide) => FirstAidSavedStore.instance.contains(guide.id))
              .toList();
          if (saved.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No saved guides yet.\nOpen a topic and tap the bookmark icon.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: saved.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) => ListTile(
              title: Text(saved[index].title),
              subtitle: Text(saved[index].summary),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _openGuide(context, saved[index], 'Dog'),
            ),
          );
        },
      ),
    );
  }
}

class FirstAidSavedStore extends ChangeNotifier {
  FirstAidSavedStore._();

  static final instance = FirstAidSavedStore._();
  final Set<String> _savedIds = {};

  bool contains(String id) => _savedIds.contains(id);

  void toggle(String id) {
    _savedIds.contains(id) ? _savedIds.remove(id) : _savedIds.add(id);
    notifyListeners();
  }

  @visibleForTesting
  void clear() {
    _savedIds.clear();
    notifyListeners();
  }
}

class FirstAidGuide {
  const FirstAidGuide({
    required this.id,
    required this.title,
    required this.icon,
    required this.summary,
    required this.warning,
    required this.symptoms,
    required this.steps,
    required this.avoid,
    required this.materials,
    required this.relatedIds,
  });

  final String id;
  final String title;
  final IconData icon;
  final String summary;
  final String warning;
  final List<String> symptoms;
  final List<String> steps;
  final List<String> avoid;
  final List<String> materials;
  final List<String> relatedIds;
}

const firstAidGuides = <FirstAidGuide>[
  FirstAidGuide(
    id: 'bleeding',
    title: 'Bleeding',
    icon: Icons.bloodtype_outlined,
    summary: 'Apply direct pressure and prepare safe transport.',
    warning: 'Heavy, spurting, or uncontrolled bleeding is an emergency.',
    symptoms: [
      'Visible blood',
      'Pale gums, weakness, or collapse',
      'Blood soaking through a dressing',
    ],
    steps: [
      'Keep yourself safe and keep the pet as still as possible.',
      'Place clean gauze or cloth over the wound and apply firm, steady pressure for at least three minutes.',
      'If blood soaks through, add more layers without removing the first layer.',
      'Transport to a veterinary clinic promptly.',
    ],
    avoid: [
      'Do not repeatedly lift the cloth to check the wound.',
      'Do not use a tight tourniquet unless a veterinary professional directs you.',
      'Do not apply powders, medicine, or household chemicals.',
    ],
    materials: [
      'Clean gauze or cloth',
      'Towel or blanket for transport',
      'Gloves if available',
    ],
    relatedIds: ['animal-bite', 'fracture'],
  ),
  FirstAidGuide(
    id: 'burns',
    title: 'Burns',
    icon: Icons.local_fire_department_outlined,
    summary: 'Stop exposure, cool gently, and protect the area.',
    warning:
        'Electrical, chemical, deep, or widespread burns need urgent care.',
    symptoms: [
      'Red, painful, or blistered skin',
      'Singed hair or chemical residue',
      'Breathing difficulty after smoke exposure',
    ],
    steps: [
      'Remove the pet from the source only when it is safe.',
      'For a heat burn, gently cool the area with room-temperature or cool running water.',
      'Cover loosely with a clean, non-stick cloth.',
      'Call the clinic and arrange an examination.',
    ],
    avoid: [
      'Do not use ice or very cold water.',
      'Do not apply butter, oils, creams, or human medication.',
      'Do not burst blisters or peel stuck material.',
    ],
    materials: [
      'Cool water',
      'Clean non-stick cloth',
      'Gloves for chemical exposure',
    ],
    relatedIds: ['breathing', 'unconscious'],
  ),
  FirstAidGuide(
    id: 'choking',
    title: 'Choking',
    icon: Icons.air_rounded,
    summary:
        'Keep calm, check only for a visible object, and seek urgent care.',
    warning:
        'Blue or pale gums, collapse, or inability to breathe require immediate emergency transport.',
    symptoms: [
      'Gagging or choking sounds',
      'Pawing at the mouth',
      'Difficulty breathing or blue-tinged gums',
    ],
    steps: [
      'Keep the pet calm and contact the clinic immediately.',
      'Only if safe, look in the mouth for a clearly visible, easily removable object.',
      'If the pet can breathe, do not delay transport while trying repeated home techniques.',
      'Transport immediately and keep the neck in a comfortable, open position.',
    ],
    avoid: [
      'Do not blindly sweep fingers deep into the mouth.',
      'Do not push an object farther down.',
      'Do not offer food, water, or medication.',
    ],
    materials: [
      'Towel or blanket',
      'Safe transport carrier if appropriate',
      'Clinic phone number',
    ],
    relatedIds: ['breathing', 'unconscious'],
  ),
  FirstAidGuide(
    id: 'poisoning',
    title: 'Poisoning',
    icon: Icons.science_outlined,
    summary: 'Prevent more exposure and contact a veterinary professional.',
    warning: 'Suspected poisoning can be serious even before symptoms appear.',
    symptoms: [
      'Vomiting, drooling, diarrhea, or weakness',
      'Tremors, seizures, or unusual behavior',
      'Known contact with a toxic product, plant, food, or medicine',
    ],
    steps: [
      'Move the pet away from the substance without exposing yourself.',
      'Call the clinic or an animal poison-control service immediately.',
      'Keep the product package, plant sample, or a photo for identification.',
      'Follow only the instructions given by the veterinary professional.',
    ],
    avoid: [
      'Do not induce vomiting unless specifically instructed.',
      'Do not give food, milk, oil, charcoal, human medicine, or home remedies.',
      'Do not wait for symptoms to appear.',
    ],
    materials: [
      'Product packaging or photo',
      'Gloves',
      'Towel and safe carrier',
    ],
    relatedIds: ['seizure', 'unconscious'],
  ),
  FirstAidGuide(
    id: 'seizure',
    title: 'Seizure',
    icon: Icons.electric_bolt_outlined,
    summary: 'Clear hazards, time the seizure, and contact the clinic.',
    warning:
        'A seizure lasting more than five minutes, repeated seizures, or failure to recover is an emergency.',
    symptoms: [
      'Falling, stiffening, or paddling',
      'Uncontrolled movements or drooling',
      'Confusion after the episode',
    ],
    steps: [
      'Move nearby objects and other pets away.',
      'Dim lights, reduce noise, and time the episode.',
      'After movement stops, keep the pet quiet and away from stairs.',
      'Contact the clinic; seek emergency care for a prolonged or repeated seizure.',
    ],
    avoid: [
      'Do not restrain the pet.',
      'Do not place hands or objects in the mouth.',
      'Do not give medicine unless it was prescribed for this pet and situation.',
    ],
    materials: [
      'Phone timer',
      'Towel or blanket',
      'A video for the veterinarian if safely recorded',
    ],
    relatedIds: ['poisoning', 'unconscious'],
  ),
  FirstAidGuide(
    id: 'heatstroke',
    title: 'Heatstroke',
    icon: Icons.thermostat_rounded,
    summary: 'Move to a cooler place, begin gentle cooling, and go to a vet.',
    warning:
        'Heatstroke is life-threatening and requires veterinary care even if the pet seems to improve.',
    symptoms: [
      'Heavy panting or rapid breathing',
      'Excess drooling, weakness, confusion, vomiting, or diarrhea',
      'Abnormally colored, dry, or sticky gums',
    ],
    steps: [
      'Move the pet out of direct heat into shade or a comfortably cool area.',
      'Wet towels with room-temperature water and place them around the neck, armpits, and groin; refresh often.',
      'Use a fan to move cool air over the pet.',
      'Call ahead and transport to the nearest veterinary clinic immediately.',
    ],
    avoid: [
      'Do not immerse the pet in ice water.',
      'Do not delay veterinary care after apparent improvement.',
      'Do not force water into the mouth.',
    ],
    materials: ['Room-temperature water', 'Towels', 'Fan if available'],
    relatedIds: ['breathing', 'unconscious'],
  ),
  FirstAidGuide(
    id: 'breathing',
    title: 'Breathing Difficulty',
    icon: Icons.waves_rounded,
    summary: 'Minimize stress and transport immediately.',
    warning:
        'Breathing difficulty is always urgent, especially with pale or blue gums.',
    symptoms: [
      'Open-mouth or labored breathing',
      'Noisy, rapid, or shallow breaths',
      'Pale or blue gums, weakness, or collapse',
    ],
    steps: [
      'Call the clinic while arranging immediate transport.',
      'Keep the pet calm, cool, and in a comfortable position.',
      'Keep the neck straight without forcing a posture.',
      'Handle as little as possible during transport.',
    ],
    avoid: [
      'Do not muzzle a pet struggling to breathe.',
      'Do not give food, water, or medication.',
      'Do not compress the chest or delay departure.',
    ],
    materials: [
      'Ventilated carrier when tolerated',
      'Towel or firm transport surface',
      'Clinic phone number',
    ],
    relatedIds: ['choking', 'unconscious'],
  ),
  FirstAidGuide(
    id: 'fracture',
    title: 'Fracture or Injury',
    icon: Icons.healing_outlined,
    summary: 'Limit movement and support the pet during transport.',
    warning:
        'Major trauma, inability to stand, severe pain, or an open fracture needs immediate care.',
    symptoms: [
      'Limping, swelling, or an abnormal limb position',
      'Pain, reluctance to move, or inability to stand',
      'Wound over a suspected fracture',
    ],
    steps: [
      'Approach carefully; pain may cause even a gentle pet to bite.',
      'Keep the pet still and support the whole body.',
      'Use a firm board, carrier base, or blanket to move the pet.',
      'Transport to the clinic promptly.',
    ],
    avoid: [
      'Do not straighten the limb or push exposed bone back.',
      'Do not give human pain medication.',
      'Do not apply a splint unless trained and instructed.',
    ],
    materials: [
      'Firm board or carrier',
      'Blanket',
      'Clean cloth for an open wound',
    ],
    relatedIds: ['bleeding', 'animal-bite'],
  ),
  FirstAidGuide(
    id: 'animal-bite',
    title: 'Animal Bite',
    icon: Icons.pets_outlined,
    summary: 'Control bleeding and arrange a veterinary examination.',
    warning:
        'Bites may hide deep tissue damage and infection even when the skin wound looks small.',
    symptoms: [
      'Puncture wounds, swelling, or bleeding',
      'Pain, limping, or hiding',
      'Weakness or breathing difficulty after an attack',
    ],
    steps: [
      'Separate animals without putting yourself at risk.',
      'Apply direct pressure to active bleeding with clean cloth.',
      'Gently rinse a superficial dirty area with clean water.',
      'Arrange prompt veterinary care.',
    ],
    avoid: [
      'Do not probe, squeeze, or close a puncture wound.',
      'Do not apply alcohol, peroxide, creams, or human medicine.',
      'Do not delay care because the wound looks small.',
    ],
    materials: [
      'Clean cloth or gauze',
      'Clean water',
      'Towel and safe carrier',
    ],
    relatedIds: ['bleeding', 'fracture'],
  ),
  FirstAidGuide(
    id: 'unconscious',
    title: 'Unconsciousness',
    icon: Icons.snooze_rounded,
    summary: 'Check breathing and seek emergency care immediately.',
    warning: 'An unresponsive pet is an immediate emergency.',
    symptoms: [
      'No response to voice or gentle touch',
      'Abnormal or absent breathing',
      'Pale or blue gums',
    ],
    steps: [
      'Call for emergency veterinary help immediately.',
      'Check for breathing without delaying transport.',
      'If breathing, place the pet on its side with the neck straight and keep warm.',
      'If not breathing, follow CPR instructions from a trained professional or emergency dispatcher while arranging transport.',
    ],
    avoid: [
      'Do not give anything by mouth.',
      'Do not shake the pet or delay emergency care.',
      'Do not attempt untrained procedures that delay transport.',
    ],
    materials: [
      'Firm transport surface',
      'Blanket',
      'A second person to call and assist if available',
    ],
    relatedIds: ['breathing', 'seizure'],
  ),
];

class _EmergencyNotice extends StatelessWidget {
  const _EmergencyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFC6C6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Emergency warning',
            style: TextStyle(
              color: _firstAidRed,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'If your pet is unconscious, cannot breathe, has a prolonged seizure, or is bleeding heavily, go to emergency care now.',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pushNamed(EmergencyServicePage.routeName),
            style: FilledButton.styleFrom(
              backgroundColor: _firstAidRed,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.emergency_rounded),
            label: const Text('Emergency Service'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    this.icon = Icons.circle,
    this.iconColor = _firstAidDark,
    this.background = Colors.white,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final Color iconColor;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCE7E3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(icon, size: 15, color: iconColor),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(item, style: const TextStyle(height: 1.35)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepsSection extends StatelessWidget {
  const _StepsSection({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What to do',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ...items.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: _firstAidMint,
                    foregroundColor: _firstAidDark,
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _openGuide(BuildContext context, FirstAidGuide guide, String petType) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => FirstAidGuidePage(guide: guide, petType: petType),
    ),
  );
}

Future<void> _confirmClinicCall(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Call Clinic?'),
      content: const Text('Clinic phone numbers:\n09-5312717\n09-965805940'),
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
  if (confirmed == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Call 09-5312717 or 09-965805940')),
    );
  }
}

Future<void> _showDirections(BuildContext context) async {
  const address =
      'Chindwin street, Mingalardipa quarter, Popba Thiri Township, Nay Pyi Taw';
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Clinic Directions'),
      content: const Text(address),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(const ClipboardData(text: address));
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
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
}
