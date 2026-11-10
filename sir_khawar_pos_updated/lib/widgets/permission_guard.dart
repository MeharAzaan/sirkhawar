import 'package:flutter/material.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';

class PermissionGuard extends StatelessWidget {
  final String screenKey;
  final Widget child;

  const PermissionGuard({
    super.key,
    required this.screenKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final data = AppData();
    final user = data.currentUser;

    // Check if access is granted
    if (user != null && user.hasAccess(screenKey)) {
      return child;
    }

    // Access restricted fallback screen
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.expenseRed.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.block_outlined,
                  size: 54,
                  color: AppColors.expenseRed,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Access Restricted',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'You are not allowed to access this screen.\nPlease contact your administrator to grant permission.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bankBlue,
                  foregroundColor: AppColors.cardBg,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  // If navigation pop fails, user stays on dashboard
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 