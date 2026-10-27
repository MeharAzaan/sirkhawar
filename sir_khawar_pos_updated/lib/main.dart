
import 'package:flutter/material.dart';
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
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/app_data.dart'; // <-- ADDED
import 'package:cloud_firestore/cloud_firestore.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
  await AppData().initialize(); // <-- ADDED
  await AppData().seedInitialDataIfEmpty(); // <-- ADDED

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
  int _selectedIndex = 0;
  bool _userManuallyCollapsed = false;

  @override
  Widget build(BuildContext context) {
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
      default: return const DashboardScreen();
    }
  }
}