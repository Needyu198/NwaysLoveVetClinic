part of 'doctor_portal.dart';

class DoctorNavigationBar extends StatelessWidget {
  const DoctorNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    _DoctorNavigationItem(
      label: 'Dashboard',
      asset: 'assets/photos/icon/doctor_dashboard_nav.png',
      keyValue: 'doctor-dashboard-tab',
      color: Color(0xFF789A93),
    ),
    _DoctorNavigationItem(
      label: 'Appointments',
      asset: 'assets/photos/icon/clinic_booking.png',
      keyValue: 'doctor-appointments-tab',
      color: Color(0xFFEF4E43),
    ),
    _DoctorNavigationItem(
      label: 'Profile',
      icon: Icons.account_circle_outlined,
      keyValue: 'doctor-profile-tab',
      color: Color(0xFF789A93),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(34, 8, 34, 14),
        child: Container(
          key: const ValueKey('doctor-navigation-bar'),
          height: 68,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(38),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 9,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var index = 0; index < _items.length; index++)
                Expanded(
                  flex: selectedIndex == index ? 5 : 2,
                  child: _DoctorNavigationDestination(
                    item: _items[index],
                    selected: selectedIndex == index,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorNavigationItem {
  const _DoctorNavigationItem({
    required this.label,
    required this.keyValue,
    required this.color,
    this.icon,
    this.asset,
  });

  final String label;
  final IconData? icon;
  final String? asset;
  final String keyValue;
  final Color color;
}

class _DoctorNavigationDestination extends StatelessWidget {
  const _DoctorNavigationDestination({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _DoctorNavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: item.label,
      button: true,
      selected: selected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          key: ValueKey(item.keyValue),
          color: selected ? const Color(0xFFF8FAF9) : Colors.transparent,
          borderRadius: BorderRadius.circular(34),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 14 : 8,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.asset != null)
                    Image.asset(
                      item.asset!,
                      key: ValueKey('${item.keyValue}-icon'),
                      width: selected ? 34 : 38,
                      height: selected ? 34 : 38,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    )
                  else
                    Icon(
                      item.icon,
                      color: item.color,
                      size: selected ? 30 : 34,
                    ),
                  if (selected) ...[
                    const SizedBox(width: 9),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          item.label,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
