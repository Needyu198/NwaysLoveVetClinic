import 'package:flutter/material.dart';

import 'pet_owner_home_page.dart';
import 'pet_owner_nav_bar.dart';
import 'pet_owner_profile_page.dart';
import 'pet_products_page.dart';

class PetOwnerClinicPage extends StatelessWidget {
  const PetOwnerClinicPage({super.key});

  static const String routeName = '/pet-owner-clinic';

  static const Color softMintColor = Color(0xFFE8FFF6);
  static const Color infoColor = Color(0xFFDCE8E4);
  static const Color inkColor = Color(0xFF050505);
  static const Color mutedTextColor = Color(0xFF3F4845);
  static const String clinicBannerAsset =
      'assets/photos/logoandphoto/clinic_banner.png';

  static const _doctors = [
    _DoctorProfile(
      name: 'Dr. Hnin Thiri Aung',
      qualification: 'B.V.Sc',
      specialty: 'General veterinary care',
      nextAvailable: 'Today, 4:30 PM',
    ),
    _DoctorProfile(
      name: 'Dr. Cindy Lynn',
      qualification: 'B.V.Sc',
      specialty: 'Pet wellness and surgery',
      nextAvailable: 'Tomorrow, 10:00 AM',
    ),
    _DoctorProfile(
      name: 'Dr. Myat Noe',
      qualification: 'M.V.Sc',
      specialty: 'Vaccination and consultation',
      nextAvailable: 'Friday, 2:00 PM',
    ),
  ];

  static const _primaryServices = [
    _ClinicService(
      'Booking',
      Icons.calendar_month_outlined,
      'Choose your pet, doctor, date, and preferred time slot.',
    ),
    _ClinicService(
      'Queue',
      Icons.groups_2_outlined,
      'Check the current waiting queue before visiting the clinic.',
    ),
    _ClinicService(
      'Home Visit',
      Icons.home_outlined,
      'Request a vet visit at your home for pets who cannot travel easily.',
    ),
    _ClinicService(
      'Medical Services',
      Icons.medical_services_outlined,
      'Consultation, vaccination, surgery, dental care, and lab tests.',
    ),
    _ClinicService(
      'Pet Care Services',
      Icons.spa_outlined,
      'Grooming, pet spa, bathing, nail trimming, and wellness care.',
    ),
  ];

  static const _secondaryServices = [
    _ClinicService(
      'Emergency Services',
      Icons.emergency_outlined,
      'Find urgent care information and emergency contact options.',
    ),
    _ClinicService(
      'History',
      Icons.history_rounded,
      'Review previous visits, prescriptions, and vaccination records.',
    ),
    _ClinicService(
      'First Aid Info',
      Icons.health_and_safety_outlined,
      'Quick guidance for bleeding, poisoning, choking, and heat stroke.',
    ),
    _ClinicService(
      'Contact Clinic',
      Icons.call_outlined,
      'Call the clinic or prepare directions for your visit.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),
                      const Center(
                        child: Image(
                          image: AssetImage(PetOwnerHomePage.logoAsset),
                          width: 132,
                          height: 132,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 34),
                      const _ClinicInfoCard(),
                      const SizedBox(height: 46),
                      const _SectionHeading('Doctor Profiles'),
                      const SizedBox(height: 18),
                      const _DoctorProfileList(doctors: _doctors),
                      const SizedBox(height: 48),
                      const _SectionHeading('Categories'),
                      const SizedBox(height: 20),
                      const _ServiceList(services: _primaryServices),
                      const SizedBox(height: 26),
                      const _ServiceList(services: _secondaryServices),
                      const SizedBox(height: 138),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: PetOwnerNavBar(
              selectedItem: PetOwnerNavItem.appointments,
              onPetsTap: () {
                Navigator.of(
                  context,
                ).pushReplacementNamed(PetOwnerHomePage.routeName);
              },
              onShopTap: () {
                Navigator.of(
                  context,
                ).pushReplacementNamed(PetProductsPage.routeName);
              },
              onProfileTap: () {
                Navigator.of(
                  context,
                ).pushReplacementNamed(PetOwnerProfilePage.routeName);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicInfoCard extends StatelessWidget {
  const _ClinicInfoCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: PetOwnerClinicPage.infoColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 2.08,
                child: Image.asset(
                  PetOwnerClinicPage.clinicBannerAsset,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 24, 34),
                child: Column(
                  children: [
                    const _StatusStrip(),
                    const SizedBox(height: 22),
                    _InfoRow(
                      icon: Icons.location_on,
                      iconColor: Color(0xFFD71920),
                      title: 'Address',
                      value:
                          'Chindwin street,Mingalardipa quarter,\nPopba Thiri Township,Nay Pyi Taw',
                    ),
                    SizedBox(height: 18),
                    _InfoRow(
                      icon: Icons.phone,
                      iconColor: Color(0xFF0099BD),
                      title: 'Phone',
                      value: '09-5312717, 09-965805940',
                    ),
                    SizedBox(height: 18),
                    _InfoRow(
                      icon: Icons.alarm_on_rounded,
                      iconColor: Color(0xFFFF6B00),
                      title: 'Clinic Hours',
                      value: '9AM - 12PM\n4PM - 7PM',
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _ClinicActionButton(
                            icon: Icons.call_rounded,
                            label: 'Call',
                            onTap: () => _showActionMessage(
                              context,
                              'Call clinic: 09-5312717',
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _ClinicActionButton(
                            icon: Icons.route_rounded,
                            label: 'Directions',
                            onTap: () => _showActionMessage(
                              context,
                              'Directions for Chindwin street, Nay Pyi Taw',
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _ClinicActionButton(
                            icon: Icons.event_available_rounded,
                            label: 'Book',
                            highlighted: true,
                            onTap: () => _showActionMessage(
                              context,
                              'Booking feature coming next.',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.circle, color: Color(0xFF20A45A), size: 12),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Open today',
              style: TextStyle(
                color: PetOwnerClinicPage.inkColor,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          Text(
            'Next closes 7:00 PM',
            style: TextStyle(
              color: PetOwnerClinicPage.mutedTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicActionButton extends StatelessWidget {
  const _ClinicActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final background = highlighted ? const Color(0xFF0F201B) : Colors.white;
    final foreground = highlighted ? Colors.white : PetOwnerClinicPage.inkColor;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 52,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: foreground, size: 22),
                  const SizedBox(width: 7),
                  Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 58, child: Icon(icon, color: iconColor, size: 45)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: PetOwnerClinicPage.inkColor,
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  color: PetOwnerClinicPage.inkColor,
                  fontSize: 23,
                  height: 1.22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Text(
        title,
        style: const TextStyle(
          color: PetOwnerClinicPage.inkColor,
          fontSize: 31,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _DoctorProfileList extends StatelessWidget {
  const _DoctorProfileList({required this.doctors});

  final List<_DoctorProfile> doctors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 286,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) => _DoctorCard(doctor: doctors[index]),
        separatorBuilder: (context, index) => const SizedBox(width: 48),
        itemCount: doctors.length,
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({required this.doctor});

  final _DoctorProfile doctor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 214,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: PetOwnerClinicPage.softMintColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 116,
              width: double.infinity,
              color: const Color(0xFFD8D8D8),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF9FA8A5),
                size: 64,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            doctor.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PetOwnerClinicPage.inkColor,
              fontSize: 21,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${doctor.qualification} • ${doctor.specialty}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PetOwnerClinicPage.mutedTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                color: Color(0xFF20A45A),
                size: 16,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  doctor.nextAvailable,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PetOwnerClinicPage.inkColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 38,
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _showActionMessage(
                context,
                'Selected ${doctor.name} for booking.',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F201B),
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Book Appointment',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceList extends StatelessWidget {
  const _ServiceList({required this.services});

  final List<_ClinicService> services;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) => _ServiceItem(service: services[index]),
        separatorBuilder: (context, index) => const SizedBox(width: 26),
        itemCount: services.length,
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  const _ServiceItem({required this.service});

  final _ClinicService service;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showServiceDetails(context, service),
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 112,
          child: Column(
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F4FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  service.icon,
                  color: PetOwnerClinicPage.inkColor,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                service.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 15,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showServiceDetails(BuildContext context, _ClinicService service) {
  final pageContext = context;

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F4FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(service.icon, color: PetOwnerClinicPage.inkColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    service.title,
                    style: const TextStyle(
                      color: PetOwnerClinicPage.inkColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              service.description,
              style: const TextStyle(
                color: PetOwnerClinicPage.mutedTextColor,
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showActionMessage(pageContext, '${service.title} selected.');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F201B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void _showActionMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _DoctorProfile {
  const _DoctorProfile({
    required this.name,
    required this.qualification,
    required this.specialty,
    required this.nextAvailable,
  });

  final String name;
  final String qualification;
  final String specialty;
  final String nextAvailable;
}

class _ClinicService {
  const _ClinicService(this.title, this.icon, this.description);

  final String title;
  final IconData icon;
  final String description;
}
