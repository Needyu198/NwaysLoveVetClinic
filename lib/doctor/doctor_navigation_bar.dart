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
      icon: Icons.desktop_windows_outlined,
      keyValue: 'doctor-dashboard-tab',
      color: Color(0xFF789A93),
    ),
    _DoctorNavigationItem(
      label: 'Appointments',
      icon: Icons.add_rounded,
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
      color: DoctorStyles.page,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          key: const ValueKey('doctor-navigation-bar'),
          height: 78,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(42),
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
    required this.icon,
    required this.keyValue,
    required this.color,
  });

  final String label;
  final IconData icon;
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
                  Icon(item.icon, color: item.color, size: selected ? 35 : 38),
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
                            fontSize: 21,
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
