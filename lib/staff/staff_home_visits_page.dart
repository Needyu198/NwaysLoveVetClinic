part of 'staff_portal.dart';

class StaffHomeVisitsPage extends StatelessWidget {
  const StaffHomeVisitsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    appBar: _appBar('Home Visits'),
    body: AnimatedBuilder(
      animation: HomeVisitStore.instance,
      builder: (_, _) {
        final visits = HomeVisitStore.instance.visits;
        if (visits.isEmpty) {
          return const Center(child: Text('No home visit requests yet'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: visits.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final visit = visits[i];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${visit.pet.name} • ${visit.reason}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_shortDate(visit.date)} at ${visit.time}\n${visit.address}\n${visit.veterinarian}',
                    style: const TextStyle(color: _muted, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Chip(
                        label: Text(_homeLabel(visit.status)),
                        backgroundColor: const Color(0xFFE6FAF2),
                      ),
                      const Spacer(),
                      if (visit.status != HomeVisitStatus.completed)
                        OutlinedButton(
                          onPressed: () => _showInfo(
                            context,
                            'Address verified',
                            'The address is inside the clinic service area.',
                          ),
                          child: const Text('Verify address'),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}
