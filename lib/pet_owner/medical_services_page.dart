import 'package:flutter/material.dart';

class MedicalServicesPage extends StatelessWidget {
  const MedicalServicesPage({super.key});

  static const routeName = '/medical-services';

  static const _groups = [
    _MedicalServiceGroup(
      title: 'Diagnostic Services',
      services: [
        _MedicalService('Rapid Test', Icons.fact_check_outlined),
        _MedicalService('Ultra Sound', Icons.monitor_heart_outlined),
        _MedicalService('Blood Testing', Icons.biotech_outlined),
      ],
    ),
    _MedicalServiceGroup(
      title: 'Treatment & Medical Care',
      services: [
        _MedicalService(
          'Inpatient/Hospitalization',
          Icons.local_hospital_outlined,
        ),
        _MedicalService(
          'General Medical Treatments',
          Icons.medical_information_outlined,
        ),
        _MedicalService('Skin Disease Treatments', Icons.coronavirus_outlined),
      ],
    ),
    _MedicalServiceGroup(
      title: 'Preventive Care',
      services: [
        _MedicalService('6 in 1 Vaccination', Icons.vaccines_outlined),
        _MedicalService('5 in 1 Vaccination', Icons.vaccines_outlined),
        _MedicalService('4 in 1 Vaccination', Icons.vaccines_outlined),
        _MedicalService('Rabies Vaccination', Icons.vaccines_outlined),
      ],
    ),
    _MedicalServiceGroup(
      title: 'Operational Services',
      services: [
        _MedicalService('Surgical Treatments', Icons.monitor_heart_outlined),
        _MedicalService(
          'Neutering (Birth Control)',
          Icons.content_cut_outlined,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Medical Services',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        toolbarHeight: 112,
        backgroundColor: const Color(0xFFA1FDD8),
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
        ),
      ),
      body: ListView(
        key: const ValueKey('medical-services-catalog'),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 40),
        children: [
          for (final group in _groups) ...[
            Text(
              group.title,
              style: const TextStyle(
                color: Color(0xFF111815),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _ServiceGroupCard(group: group),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

class _ServiceGroupCard extends StatelessWidget {
  const _ServiceGroupCard({required this.group});

  final _MedicalServiceGroup group;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFB8F9E1),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          for (var index = 0; index < group.services.length; index++) ...[
            _ServiceRow(service: group.services[index]),
            if (index != group.services.length - 1)
              const Divider(height: 1, indent: 48, color: Color(0xFF4F7569)),
          ],
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service});

  final _MedicalService service;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: service.name,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 38,
              child: Icon(
                service.icon,
                color: const Color(0xFF07120E),
                size: 27,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                service.name,
                style: const TextStyle(
                  color: Color(0xFF07120E),
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicalServiceGroup {
  const _MedicalServiceGroup({required this.title, required this.services});

  final String title;
  final List<_MedicalService> services;
}

class _MedicalService {
  const _MedicalService(this.name, this.icon);

  final String name;
  final IconData icon;
}
