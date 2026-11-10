import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/app_user.dart';
import '../constants/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AppData data = AppData();

  @override
  void initState() {
    super.initState();
    data.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    data.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _promptPasswordAndLogin(AppUser user) async {
    final passwordCtrl = TextEditingController();
    bool obscure = true;
    String? errorText;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('Login as ${user.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter password for ${user.isAdmin ? "Admin" : "Employee"} profile:',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordCtrl,
                obscureText: obscure,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setD(() => obscure = !obscure),
                  ),
                ),
                onSubmitted: (_) {
                  _attemptLogin(ctx, user, passwordCtrl.text.trim(), (err) {
                    setD(() => errorText = err);
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bankBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _attemptLogin(ctx, user, passwordCtrl.text.trim(), (err) {
                  setD(() => errorText = err);
                });
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }

  void _attemptLogin(
      BuildContext dialogContext, AppUser user, String enteredPassword, Function(String) onError) {
    if (user.password == enteredPassword) {
      Navigator.pop(dialogContext);
      data.login(user);
    } else {
      onError('Incorrect password. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2332),
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
              const Icon(Icons.bolt, color: Colors.amber, size: 48),
              const SizedBox(height: 12),
              const Text(
                'AES Business Management',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select your profile to continue',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 28),
              if (data.users.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.bankBlue),
                )
              else
                ...data.users.map((user) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          icon: Icon(
                            user.isAdmin
                                ? Icons.admin_panel_settings
                                : Icons.person,
                            color: Colors.white,
                          ),
                          label: Row(
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: user.isAdmin
                                      ? Colors.amber.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  user.isAdmin ? 'Admin' : 'Employee',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: user.isAdmin
                                        ? Colors.amber
                                        : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: user.isAdmin
                                ? const Color(0xFF1A2332)
                                : const Color(0xFF2D3A4A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _promptPasswordAndLogin(user),
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}