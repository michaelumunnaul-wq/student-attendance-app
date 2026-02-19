# Authentication Integration Guide

## Complete Flutter App with Teacher Authentication

This guide shows how to integrate the authentication system into your student attendance app.

## Files Structure

```
student_attendance_app/
├── lib/
│   ├── main.dart          # Main app file (see below for complete code)
│   ├── auth.dart          # Authentication screens (already created)
│   └── app_pages.dart     # All app pages (courses, students, attendance, reports)
├── pubspec.yaml           # Dependencies
└── README.md
```

## Step 1: Update pubspec.yaml

Add the `crypto` package for password hashing:

```yaml
name: student_attendance_app
description: A Flutter app for student attendance tracking with teacher authentication
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.2
  crypto: ^3.0.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
```

##Step 2: Complete main.dart with Auth Integration

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:convert' show utf8;

// Import the auth file
// import 'auth.dart'; // Uncomment this when using separate files

void main() {
  runApp(const StudentAttendanceApp());
}

class StudentAttendanceApp extends StatelessWidget {
  const StudentAttendanceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthenticationWrapper(),
    );
  }
}

// [COPY ALL AUTH CODE FROM auth.dart HERE OR IMPORT IT]
// This includes:
// - Admin class
// - hashPassword function
// - AuthenticationWrapper
// - RegisterPage
// - LoginPage

// HomePage with Logout functionality
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _currentUser = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUser = prefs.getString('current_user') ?? 'Teacher';
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('current_user');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthenticationWrapper()),
        );
      }
    }
  }

  static const List<Widget> _pages = <Widget>[
    CoursesPage(),
    StudentsPage(),
    AttendancePage(),
    ReportsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $_currentUser'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}

// [ADD ALL YOUR EXISTING CODE HERE]
// - Course class
// - Student class  
// - CourseEnrollment class
// - AttendanceRecord class
// - CoursesPage
// - StudentsPage
// - AttendancePage
// - ReportsPage
// - All supporting widgets and classes
```

## How Authentication Works

### 1. First Time Setup (Registration)
- When app launches, it checks if an admin account exists
- If NO admin exists → Shows **RegisterPage**
- Teacher fills in:
  - Full Name
  - Email
  - Username (min 4 characters)
  - Password (min 6 characters, hashed with SHA-256)
  - Confirm Password
- After registration:
  - Admin account is saved to SharedPreferences
  - User is automatically logged in
  - Redirected to HomePage (main app)

### 2. Subsequent Logins
- When app launches, it checks if user is logged in
- If NOT logged in → Shows **LoginPage**
- Teacher enters:
  - Username
  - Password (validated against stored hash)
- On success auth:
  - Login status saved
  - Redirected to HomePage
- On failure:
  - Red error message shown
  - Can retry login

### 3. Logout
- Logout button in app bar (top right)
- Confirmation dialog appears
- On confirm:
  - Login status cleared
  - Returns to LoginPage
  - Admin account remains (won't show registration again)

## Security Features

✅ **Password Hashing**: Passwords are hashed using SHA-256 (crypto package)
✅ **No Plain Text Storage**: Only password hash is stored, never the actual password
✅ **Session Management**: Login state persists across app restarts
✅ **Validation**: 
   - Username minimum 4 characters
   - Password minimum 6 characters
   - Email validation
   - Password confirmation match
✅ **Single Admin**: Only one teacher account per device
✅ **Protected Routes**: Cannot access app features without logging in

## Data Storage Keys

The app uses these SharedPreferences keys:

- `has_admin` (bool): Whether admin account exists
- `is_logged_in` (bool): Current login status
- `admin` (JSON): Admin account details (username, passwordHash, fullName, email)
- `current_user` (String): Display name of logged-in teacher
- `courses` (JSON): All courses data
- `students` (JSON): All students data
- `enrollment_{courseId}` (JSON): Students enrolled in specific course
- `attendance_{courseId}_{date}` (JSON): Attendance records

## Complete Workflow

```
App Launch
    ↓
Check: has_admin exists?
    ├─ NO  → Show RegisterPage
    │         ↓
    │      Register Teacher
    │         ↓
    │      Auto-login
    │         ↓
    └─ YES → Check: is_logged_in?
                ├─ NO  → Show LoginPage
                │          ↓
                │       Validate Credentials
                │          ↓
                └─ YES → Show HomePage
                           ↓
                        Use App Features
                           ↓
                        Logout Button
                           ↓
                        Back to LoginPage
```

## Testing the Authentication

### Test Scenario 1: First Installation
1. Install and run the app
2. Should see Registration screen
3. Fill in teacher details
4. Submit - should go directly to app

### Test Scenario 2: Closing and Reopening
1. Close the app completely
2. Reopen the app
3. Should see Login screen (not registration)
4. Login with credentials from step 1

### Test Scenario 3: Logout
1. While in app, tap logout button
2. Confirm logout
3. Should return to Login screen
4. Can login again with same credentials

### Test Scenario 4: Wrong Password
1. On login screen, enter correct username
2. Enter wrong password
3. Should see error message
4. Can retry with correct password

## Customization Options

### Change Password Requirements
In RegisterPage validators, modify:
```dart
if (value.length < 6) {  // Change 6 to your preferred minimum
  return 'Password must be at least 6 characters';
}
```

### Change App Title/Branding
In main.dart:
```dart
title: 'Your School Name - Attendance',
```

### Add Password Reset
Currently not implemented. To add:
1. Create a password reset page
2. Add security questions or email verification
3. Allow updating the admin password hash

### Multiple Teachers
To support multiple teachers:
1. Change data structure to store array of admins
2. Add teacher ID to all records
3. Filter data by logged-in teacher
4. Add teacher management screen

## Troubleshooting

**Problem**: "Package crypto not found"
**Solution**: Run `flutter pub get`

**Problem**: Can't login after registration
**Solution**: Check that passwords match and meet minimum requirements

**Problem**: Data lost after logout
**Solution**: Data persists - it's separate from login session. Login again to access.

**Problem**: Forgot password
**Solution**: Currently no reset option. Need to clear app data and re-register (loses all attendance data)

## Security Best Practices

⚠️ **For Production Apps:**
1. Use more secure hashing (bcrypt, argon2)
2. Add salt to password hashes
3. Implement password reset via email
4. Add session timeouts
5. Use backend authentication server
6. Encrypt sensitive data
7. Add biometric authentication option

This implementation is suitable for:
✅ Single-device teacher use
✅ Local data storage
✅ Basic security requirements
✅ Offline-first applications

NOT suitable for:
❌ Multi-user environments
❌ Cloud-synced data
❌ High-security requirements
❌ Remote access scenarios
