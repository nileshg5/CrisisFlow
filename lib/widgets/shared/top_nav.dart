import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';

class TopNav extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const TopNav({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(64); // h-16

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Title and Breadcrumbs/Tabs
          Row(
            children: [
              Text(
                title.toUpperCase(),
                style: AppTextStyles.technical().copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 24),
              Container(width: 1, height: 16, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(width: 24),
              _buildTab('Overview', isActive: true),
              const SizedBox(width: 24),
              _buildTab('Live Feed', isActive: false),
              const SizedBox(width: 24),
              _buildTab('Dispatch', isActive: false),
            ],
          ),

          // Right side: Search and Actions
          Row(
            children: [
              // Search
              Container(
                width: 200,
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 16, color: AppColors.outline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search operational data...',
                        style: AppTextStyles.bodyMd(color: AppColors.outline).copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.notifications_none, color: AppColors.outline),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.account_circle_outlined, color: AppColors.outline),
                tooltip: 'Back to role selection',
                onPressed: () => _goToRoleSelection(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, {required bool isActive}) {
    return Container(
      padding: const EdgeInsets.only(bottom: 22, top: 22),
      decoration: BoxDecoration(
        border: isActive ? const Border(bottom: BorderSide(color: AppColors.primary, width: 2)) : null,
      ),
      child: Text(
        label,
        style: AppTextStyles.technical(
          color: isActive ? AppColors.primary : AppColors.outline,
        ).copyWith(fontSize: 14),
      ),
    );
  }

  Future<void> _goToRoleSelection(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await prefs.remove('volunteer_id');
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      context.go('/login');
    }
  }
}
