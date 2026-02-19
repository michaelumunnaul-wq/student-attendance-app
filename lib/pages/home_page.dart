import 'package:flutter/material.dart';
import '../utils/auth_helper.dart';
import 'auth/login_page.dart';
import 'courses_page.dart';
import 'students_page.dart';
import 'attendance_page.dart';
import 'reports_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _idx = 0;
  String _currentUser = 'Teacher';

  static const _pages = [
    CoursesPage(),
    StudentsPage(),
    AttendancePage(),
    ReportsPage(),
  ];

  @override
  void initState() {
    super.initState();
    AuthHelper.getCurrentUser().then((u) => setState(() => _currentUser = u));
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await AuthHelper.logout();
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(children: [
          const Icon(Icons.school, size: 20),
          const SizedBox(width: 8),
          Text('Welcome, $_currentUser'),
        ]),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout),
        ],
      ),
      body: _pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.book), label: 'Courses'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Students'),
          NavigationDestination(
              icon: Icon(Icons.check_circle_outline), label: 'Attendance'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Reports'),
        ],
      ),
    );
  }
}
