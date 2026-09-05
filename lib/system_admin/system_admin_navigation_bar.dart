part of 'system_admin_portal.dart';

class SystemAdminNavigationBar extends StatelessWidget {
  const SystemAdminNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    _SystemAdminNavigationItem(
      label: 'Dashboard',
      icon: Icons.desktop_windows_rounded,
      keyValue: 'system-admin-dashboard-tab',
      color: Color(0xFF789A93),
    ),
    _SystemAdminNavigationItem(
      label: 'Management',
      icon: Icons.settings_applications_rounded,
      keyValue: 'system-admin-bookings-tab',
      color: Color(0xFF789A93),
    ),
    _SystemAdminNavigationItem(
      label: 'Account',
      icon: Icons.account_circle_outlined,
      keyValue: 'system-admin-account-tab',
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
          key: const ValueKey('system-admin-navigation-bar'),
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
                  child: _SystemAdminNavigationDestination(
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

class _SystemAdminNavigationItem {
  const _SystemAdminNavigationItem({
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

class _SystemAdminNavigationDestination extends StatelessWidget {
  const _SystemAdminNavigationDestination({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _SystemAdminNavigationItem item;
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
                  Icon(item.icon, color: item.color, size: selected ? 30 : 34),
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
