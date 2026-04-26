import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class SideNav extends StatelessWidget {
  final String activeRoute;
  const SideNav({super.key, required this.activeRoute});

  static const _mainItems = [
    {'icon': Icons.dashboard_outlined,   'label': 'Dashboard',    'route': '/coordinator/dashboard'},
    {'icon': Icons.input_outlined,        'label': 'Intake Hub',   'route': '/coordinator/intake'},
    {'icon': Icons.view_kanban_outlined,  'label': 'Assignments',  'route': '/coordinator/assignments'},
    {'icon': Icons.group_outlined,        'label': 'Team Manager', 'route': '/coordinator/team'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.security, color: Colors.black, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text('CRISIS_FLOW', style: AppTextStyles.h3().copyWith(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 3),
                Text('ACTIVE OPS CENTRAL',
                    style: AppTextStyles.technical(color: AppColors.outline).copyWith(fontSize: 9)),
              ],
            ),
          ),

          // Main nav
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Text('NAVIGATION',
                    style: AppTextStyles.labelCaps(color: AppColors.outline).copyWith(fontSize: 9)),
                const SizedBox(height: 8),
                ..._mainItems.map((item) => _navItem(context,
                    icon: item['icon'] as IconData,
                    label: item['label'] as String,
                    route: item['route'] as String)),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: Column(
              children: [
                _navItem(context, icon: Icons.settings_outlined, label: 'Settings', route: '/settings', isFooter: true),
                const SizedBox(height: 8),
                // User card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 30, height: 30,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceVariant,
                        ),
                        child: const Icon(Icons.person, color: AppColors.onSurfaceVar, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Alex Rivera',
                                style: AppTextStyles.technical().copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                                overflow: TextOverflow.ellipsis),
                            Text('Lead Coordinator',
                                style: AppTextStyles.labelCaps(color: AppColors.outline).copyWith(fontSize: 9)),
                          ],
                        ),
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

  Widget _navItem(BuildContext context,
      {required IconData icon, required String label, required String route, bool isFooter = false}) {
    final isActive = activeRoute == route;
    return InkWell(
      onTap: () {
        if (!isActive) {
          if (route.startsWith('/coordinator') || route.startsWith('/volunteer')) {
            context.go(route);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(bottom: 32, right: 32, left: 32),
                backgroundColor: AppColors.surface,
                content: Text('$label — coming soon',
                    style: AppTextStyles.technical()),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: Colors.white.withValues(alpha: 0.12)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18,
                color: isActive ? AppColors.primary : AppColors.outline),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.technical(
                      color: isActive ? AppColors.primary : AppColors.outline).copyWith(fontSize: 13)),
            ),
            if (isActive)
              Container(
                width: 5, height: 5,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
