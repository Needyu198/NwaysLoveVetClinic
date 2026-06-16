import 'package:flutter/material.dart';

import 'pet_owner_home_page.dart';
import 'pet_reminder_page.dart';

class PetProfile {
  const PetProfile({
    required this.name,
    required this.species,
    required this.breed,
    required this.sex,
    required this.weight,
    required this.imageAsset,
    this.imageAlignment = Alignment.center,
  });

  final String name;
  final String species;
  final String breed;
  final String sex;
  final String weight;
  final String imageAsset;
  final Alignment imageAlignment;
}

class PetProfilePage extends StatelessWidget {
  const PetProfilePage({super.key});

  static const String routeName = '/pet-profile';

  static const PetProfile fallbackProfile = PetProfile(
    name: 'Max',
    species: 'Dog',
    breed: 'Golden Retriever',
    sex: 'Male',
    weight: '18 kg',
    imageAsset: PetOwnerHomePage.dogAsset,
  );

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final profile = args is PetProfile ? args : fallbackProfile;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _ProfileHero(profile: profile)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
              sliver: SliverList.list(
                children: [
                  _BasicInfoPanel(profile: profile),
                  const SizedBox(height: 18),
                  const _MedicalInfoPanel(),
                  const SizedBox(height: 18),
                  const _AppointmentHistoryPanel(),
                  const SizedBox(height: 18),
                  const _TreatmentRecordPanel(),
                  const SizedBox(height: 26),
                  const _EmergencyButton(),
                  const SizedBox(height: 34),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile});

  final PetProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA1FDD8), Color(0xFFD8FFF0), Color(0xFFF7FAF8)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RoundIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Pet Profile', style: _PetProfileStyles.pageTitle),
              ),
              _RoundIconButton(icon: Icons.edit_rounded, onTap: () {}),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 310,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(34),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x240B2F25),
                  blurRadius: 26,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  profile.imageAsset,
                  fit: BoxFit.cover,
                  alignment: profile.imageAlignment,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0x22000000),
                        Color(0xB8000000),
                      ],
                      stops: [0.38, 0.66, 1],
                    ),
                  ),
                ),
                Positioned(
                  right: 18,
                  top: 18,
                  child: _GlassIconButton(
                    icon: Icons.add_photo_alternate_outlined,
                    onTap: () {},
                  ),
                ),
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name, style: _PetProfileStyles.heroName),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children: [
                          _HeroChip(
                            icon: Icons.cruelty_free_rounded,
                            label: profile.species,
                          ),
                          _HeroChip(
                            icon: Icons.monitor_weight_rounded,
                            label: profile.weight,
                          ),
                          _HeroChip(
                            icon: Icons.favorite_rounded,
                            label: 'Healthy',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BasicInfoPanel extends StatelessWidget {
  const _BasicInfoPanel({required this.profile});

  final PetProfile profile;

  @override
  Widget build(BuildContext context) {
    return _SectionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Basic Info',
            icon: Icons.assignment_ind_rounded,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.72,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _InfoTile(
                icon: Icons.pets_rounded,
                label: 'Name',
                value: profile.name,
              ),
              _InfoTile(
                icon: Icons.biotech_rounded,
                label: 'Breed',
                value: profile.breed,
              ),
              _InfoTile(
                icon: Icons.cruelty_free_rounded,
                label: 'Species',
                value: profile.species,
              ),
              _InfoTile(
                icon: Icons.monitor_weight_rounded,
                label: 'Weight',
                value: profile.weight,
              ),
              _InfoTile(
                icon: Icons.transgender_rounded,
                label: 'Sex',
                value: profile.sex,
              ),
              const _InfoTile(
                icon: Icons.cake_rounded,
                label: 'Age',
                value: '2 years',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MedicalInfoPanel extends StatelessWidget {
  const _MedicalInfoPanel();

  @override
  Widget build(BuildContext context) {
    return _SectionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionHeader(
                  title: 'Medical Info',
                  icon: Icons.medical_information_rounded,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(PetReminderPage.routeName);
                },
                icon: const Icon(Icons.notifications_active_rounded, size: 18),
                label: const Text('Reminder'),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFFFE9E5),
                  foregroundColor: const Color(0xFFCE3D2E),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _MedicalCard(
            icon: Icons.vaccines_rounded,
            title: 'Vaccination history',
            detail: 'Rabies vaccine completed',
            meta: 'Last update: May 2026',
          ),
          const SizedBox(height: 12),
          const _MedicalCard(
            icon: Icons.event_available_rounded,
            title: 'Upcoming vaccination',
            detail: 'Annual booster check',
            meta: 'Due this week',
            accentColor: Color(0xFFEF5B4E),
          ),
          const SizedBox(height: 12),
          const _MedicalCard(
            icon: Icons.health_and_safety_rounded,
            title: 'Allergies',
            detail: 'No known allergies',
            meta: 'Confirmed by clinic',
          ),
        ],
      ),
    );
  }
}

class _AppointmentHistoryPanel extends StatelessWidget {
  const _AppointmentHistoryPanel();

  @override
  Widget build(BuildContext context) {
    return const _SectionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Appointment History',
            icon: Icons.history_rounded,
          ),
          SizedBox(height: 18),
          _TimelineVisit(
            doctor: 'Dr. Nway',
            time: 'Jun 12, 2026 - 10:30 AM',
            reason: 'Checkup',
            status: 'Completed',
          ),
          SizedBox(height: 14),
          _TimelineVisit(
            doctor: 'Clinic Team',
            time: 'May 21, 2026 - 2:00 PM',
            reason: 'Grooming consultation',
            status: 'Completed',
          ),
        ],
      ),
    );
  }
}

class _TreatmentRecordPanel extends StatelessWidget {
  const _TreatmentRecordPanel();

  @override
  Widget build(BuildContext context) {
    return const _SectionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Treatment Records',
            icon: Icons.receipt_long_rounded,
          ),
          SizedBox(height: 18),
          _RecordRow(icon: Icons.fact_check_rounded, text: 'Diagnosis'),
          _RecordRow(icon: Icons.healing_rounded, text: 'Treatment details'),
          _RecordRow(icon: Icons.medication_rounded, text: 'Medicines'),
          _RecordRow(icon: Icons.schedule_rounded, text: 'Dosage instructions'),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FFFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8F4EA)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFE8FFF5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Color(0xFF16785B), size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _PetProfileStyles.tileLabel),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _PetProfileStyles.tileValue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicalCard extends StatelessWidget {
  const _MedicalCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.meta,
    this.accentColor = const Color(0xFF16785B),
  });

  final IconData icon;
  final String title;
  final String detail;
  final String meta;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3F3ED)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 25),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _PetProfileStyles.cardTitle),
                const SizedBox(height: 4),
                Text(detail, style: _PetProfileStyles.cardDetail),
                const SizedBox(height: 6),
                Text(
                  meta,
                  style: _PetProfileStyles.cardMeta.copyWith(
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineVisit extends StatelessWidget {
  const _TimelineVisit({
    required this.doctor,
    required this.time,
    required this.reason,
    required this.status,
  });

  final String doctor;
  final String time;
  final String reason;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Color(0xFF18A77B),
                shape: BoxShape.circle,
              ),
            ),
            Container(width: 2, height: 72, color: const Color(0xFFD3EFE5)),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE3F3ED)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(doctor, style: _PetProfileStyles.cardTitle),
                    ),
                    _StatusPill(label: status),
                  ],
                ),
                const SizedBox(height: 7),
                Text(time, style: _PetProfileStyles.cardDetail),
                const SizedBox(height: 5),
                Text(reason, style: _PetProfileStyles.cardMeta),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFE8FFF5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Color(0xFF16785B), size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: _PetProfileStyles.recordText)),
        ],
      ),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33FF1E17),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: () {},
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFF1E17),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emergency_share_rounded, size: 34),
            SizedBox(width: 12),
            Text(
              'Emergency',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFD7FCEB),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120B2F25),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Color(0xFF16785B), size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: _PetProfileStyles.sectionTitle)),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.86),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: Colors.black, size: 24),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: Colors.black, size: 30),
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF16785B), size: 16),
          const SizedBox(width: 6),
          Text(label, style: _PetProfileStyles.heroChip),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FFF5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: _PetProfileStyles.status),
    );
  }
}

class _PetProfileStyles {
  static const pageTitle = TextStyle(
    color: Colors.black,
    fontSize: 30,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );

  static const heroName = TextStyle(
    color: Colors.white,
    fontSize: 42,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
    shadows: [
      Shadow(color: Color(0x99000000), blurRadius: 14, offset: Offset(0, 4)),
    ],
  );

  static const heroChip = TextStyle(
    color: Colors.black,
    fontSize: 13,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const sectionTitle = TextStyle(
    color: Colors.black,
    fontSize: 24,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
    height: 1.1,
  );

  static const tileLabel = TextStyle(
    color: Color(0xFF6B7F78),
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const tileValue = TextStyle(
    color: Colors.black,
    fontSize: 15,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );

  static const cardTitle = TextStyle(
    color: Colors.black,
    fontSize: 16,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );

  static const cardDetail = TextStyle(
    color: Color(0xFF50645D),
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const cardMeta = TextStyle(
    color: Color(0xFF16785B),
    fontSize: 13,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const recordText = TextStyle(
    color: Colors.black,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const status = TextStyle(
    color: Color(0xFF16785B),
    fontSize: 12,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );
}
