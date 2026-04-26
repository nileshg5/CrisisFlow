import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../widgets/shared/glass_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loadingCoordinator = false;
  bool _loadingVolunteer = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.6, -0.4),
                radius: 1.5,
                colors: [Color(0xFF1A1C1C), AppColors.background],
              ),
            ),
          ).animate().fade(duration: 1.seconds),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: 440,
                child: GlassCard(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.emergency,
                          color: AppColors.background,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('CrisisFlow', style: AppTextStyles.h2()),
                      const SizedBox(height: 6),
                      Text(
                        'Anonymous demo login',
                        style: AppTextStyles.technical(color: AppColors.onSurfaceVar),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.background,
                          ),
                          onPressed: _loadingCoordinator
                              ? null
                              : () => _loginAsRole('coordinator'),
                          child: _loadingCoordinator
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  'LOGIN AS COORDINATOR',
                                  style: AppTextStyles.labelCaps(
                                    color: AppColors.background,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          onPressed: _loadingVolunteer
                              ? null
                              : () => _loginAsRole('volunteer'),
                          child: _loadingVolunteer
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text('LOGIN AS VOLUNTEER', style: AppTextStyles.labelCaps()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loginAsRole(String role) async {
    setState(() {
      if (role == 'coordinator') {
        _loadingCoordinator = true;
      } else {
        _loadingVolunteer = true;
      }
    });

    try {
      await FirebaseAuth.instance.signInAnonymously();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);
      if (role == 'volunteer') {
        await prefs.setString(
          'volunteer_id',
          FirebaseAuth.instance.currentUser?.uid ?? '',
        );
      }

      if (!mounted) return;
      if (role == 'coordinator') {
        context.go('/coordinator/dashboard');
      } else {
        context.go('/volunteer/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          content: Text('Login failed: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingCoordinator = false;
          _loadingVolunteer = false;
        });
      }
    }
  }
}
