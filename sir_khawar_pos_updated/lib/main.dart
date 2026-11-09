import 'package:flutter/material.dart';
import 'package:sir_khawar_pos_updated/screens/login_screen.dart';
import 'package:sir_khawar_pos_updated/screens/customers_screen.dart';
import 'package:sir_khawar_pos_updated/screens/employees_screen.dart';
import 'package:sir_khawar_pos_updated/screens/settings_screen.dart';
import 'package:sir_khawar_pos_updated/screens/templates_screen.dart';
import 'widgets/sidebar.dart';
import 'screens/dashboard_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/bank_cash_screen.dart';
import 'screens/customer_cheques_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/quotation_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/vendors_screen.dart';
import 'screens/purchases_screen.dart';
import 'screens/reports_screen.dart';


import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/app_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
  await AppData().initialize();
  await AppData().seedInitialDataIfEmpty();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AES Business Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1a2332),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final AppData data = AppData();
  int _selectedIndex = 0;
  bool _userManuallyCollapsed = false;

  // Keys matching sidebar order (14 screens)
  static const List<String> _screenKeys = [
    'dashboard', 'expenses', 'bank_cash', 'customer_cheques',
    'inventory', 'quotations', 'invoices', 'customers',
    'employees', 'templates', 'settings', 'vendors',
    'purchases', 'reports',
  ];

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

  @override
  Widget build(BuildContext context) {
    // Show login screen if no user selected
    if (data.currentUser == null) {
      return const LoginScreen();
    }

    // Auto-select first allowed screen if current is not allowed
    final allowed = data.allowedScreenKeys;
    if (allowed.isNotEmpty && !allowed.contains(_screenKeys[_selectedIndex])) {
      final firstAllowed = _screenKeys.indexWhere((k) => allowed.contains(k));
      if (firstAllowed != -1 && firstAllowed != _selectedIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedIndex = firstAllowed);
        });
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isCollapsed = screenWidth < 900 || _userManuallyCollapsed;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 1024) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.desktop_windows_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Window too small',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please resize the window to at least 1024px wide.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Row(
            children: [
              Sidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
                isCollapsed: isCollapsed,
                onToggle: () {
                  setState(() {
                    _userManuallyCollapsed = !_userManuallyCollapsed;
                  });
                },
                allowedKeys: data.allowedScreenKeys,
              ),
              Expanded(
                child: _buildScreen(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScreen() {
    // Access denied if screen not allowed for this user
    if (!data.canAccess(_screenKeys[_selectedIndex])) {
      return _accessDeniedScreen();
    }

    switch (_selectedIndex) {
      case 0: return const DashboardScreen();
      case 1: return const ExpensesScreen();
      case 2: return const BankCashScreen();
      case 3: return const CustomerChequesScreen();
      case 4: return const InventoryScreen();
      case 5: return const QuotationScreen();
      case 6: return const InvoicesScreen();
      case 7: return const CustomersScreen();
      case 8: return const EmployeesScreen();
      case 9: return const TemplatesScreen();
      case 10: return const SettingsScreen();
      case 11: return const VendorsScreen();
      case 12: return const PurchasesScreen();
      case 13: return const ReportsScreen();
      default: return const DashboardScreen();
    }
  }

  Widget _accessDeniedScreen() {
    return Container(
      color: const Color(0xFFF5F6FA),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'You are not allowed to see this',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Contact your administrator to request access.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Switch User'),
              onPressed: () => data.logout(),
            ),
          ],
        ),
      ),
    );
  }
}