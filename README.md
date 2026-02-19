# Student Attendance App with Teacher Authentication

A comprehensive Flutter application for managing student enrollment, course management, and tracking daily attendance with secure teacher authentication.

## 🔐 Authentication Features

### Teacher Registration & Login
- **First-time Setup**: Register with full name, email, username, and password
- **Secure Login**: SHA-256 password hashing for security
- **Session Management**: Stay logged in across app restarts  
- **Logout**: Secure logout with confirmation dialog
- **Single Admin**: One authorized teacher per device

### Security
✅ Password hashing (SHA-256)  
✅ No plain-text password storage  
✅ Protected routes - must login to access features  
✅ Session persistence  
✅ Input validation (min 4 char username, min 6 char password)  

## 📚 Core Features

### 1. Course Management
- Add courses with name, code (unique), and description
- **Duplicate course code prevention**
- View all courses in organized list
- Manage course enrollments
- Delete courses (removes all associated data)

### 2. Student Management
- Add students with name and ID number
- **Duplicate ID Prevention**: System validates and rejects duplicate IDs
- View all registered students
- Delete students when needed
- Centralized student database

### 3. Course Enrollment System
- Enroll students in specific courses
- Multi-select interface for batch enrollment
- View enrolled vs available students per course
- Remove students from courses
- Students can enroll in multiple courses

### 4. Course-Specific Attendance Tracking
- Select course to take attendance for
- Mark students present/absent for any date
- Visual indicators for attendance status
- Date selection for viewing/editing past attendance
- Real-time statistics (Present, Absent, Total)
- Save attendance records per course per day
- Only enrolled students appear in attendance list

### 5. Comprehensive Reports (Per Course)
- **Daily Reports**: View attendance for specific dates with present/absent breakdown
- **Weekly Reports**: 7-day attendance summary with student-wise statistics
- **Monthly Reports**: Complete month overview with performance ratings
- Summary statistics with attendance rate percentages
- Color-coded performance indicators:
  - 🟢 Excellent (≥90%)
  - 🟢 Good (75-89%)
  - 🟠 Fair (60-74%)
  - 🔴 Poor (<60%)
- Expandable student cards showing detailed attendance breakdown
- Visual progress bars for monthly performance

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Android Emulator or Physical Device

### Installation

1. **Install Flutter** (if not already installed):
   ```bash
   # Visit https://flutter.dev/docs/get-started/install
   ```

2. **Navigate to project directory**:
   ```bash
   cd student_attendance_app
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## 📱 First-Time Usage

### Step 1: Teacher Registration
1. Launch the app for the first time
2. You'll see the **Registration Screen**
3. Fill in your details:
   - Full Name (e.g., "Ms. Sarah Johnson")
   - Email (e.g., "sarah@school.com")
   - Username (min 4 characters, e.g., "sjohnson")
   - Password (min 6 characters)
   - Confirm Password
4. Tap **Register**
5. You'll be automatically logged in and taken to the main app

### Step 2: Add Courses
1. Go to "Courses" tab
2. Tap the + button
3. Enter course details (e.g., "Math 101", code "MTH101")
4. Tap "Add"

### Step 3: Add Students
1. Go to "Students" tab
2. Enter student name and unique ID
3. Tap "Add Student"
4. Repeat for all students

### Step 4: Enroll Students in Courses
1. Go to "Courses" tab
2. Tap on a course
3. Tap "Enroll" button
4. Select students (can select multiple)
5. Tap "Enroll X" to confirm

### Step 5: Take Attendance
1. Go to "Attendance" tab
2. Select a course from dropdown
3. Check/uncheck students for present/absent
4. Tap "Save Attendance"

### Step 6: View Reports
1. Go to "Reports" tab
2. Select a course
3. Choose report type (Daily/Weekly/Monthly)
4. Select date/week/month to view

## 🔄 Daily Workflow

### Morning - Before Class
1. Open app (login if needed)
2. Go to "Attendance" tab
3. Select the course you're teaching

### During/After Class
1. Mark students as present/absent
2. Tap "Save Attendance"

### End of Week
1. Go to "Reports" tab
2. Select course
3. View "Weekly" report
4. Identify students with low attendance

### End of Month
1. Go to "Reports" tab
2. View "Monthly" report
3. Review performance ratings
4. Take action for students with poor attendance

## 🔒 Authentication Workflow

```
App Launch
    ↓
Has Admin Account?
    ├─ NO  → Registration Screen
    │         ↓
    │      Complete Registration
    │         ↓
    │      Auto-login to App
    │
    └─ YES → Is Logged In?
              ├─ NO  → Login Screen
              │          ↓
              │       Enter Credentials
              │          ↓
              │       Validate
              │          ↓
              └─ YES → Main App (HomePage)
                         ↓
                      Use Features
                         ↓
                      Logout (optional)
```

## 💾 Data Storage

All data is stored locally on the device using SharedPreferences:

**Authentication Data:**
- `has_admin` - Whether admin account exists
- `is_logged_in` - Current login status
- `admin` - Admin account (username, password hash, full name, email)
- `current_user` - Display name of logged-in teacher

**App Data:**
- `courses` - All course information
- `students` - All student records
- `enrollment_{courseId}` - Student enrollments per course
- `attendance_{courseId}_{date}` - Daily attendance per course

Data persists across app restarts and logout.

## 📂 Project Structure

```
student_attendance_app/
├── lib/
│   ├── main.dart          # Main app entry + HomePage
│   └── auth.dart          # Authentication screens
├── pubspec.yaml           # Dependencies
└── README.md             # This file
```

## 🔧 Dependencies

- **flutter**: Flutter SDK
- **shared_preferences**: ^2.2.2 - Local data persistence
- **crypto**: ^3.0.3 - Password hashing (SHA-256)

## 📊 Use Case Example

**Teacher: Mr. Davis teaches 3 courses**

**Setup (One Time):**
1. Registers as admin with username "mdavis"
2. Adds courses: "Biology 101", "Chemistry 101", "Physics 101"
3. Adds 45 students to the system
4. Enrolls students in their respective courses

**Daily Routine:**
1. Monday 9 AM: Opens app, logs in (stays logged in all day)
2. Takes attendance for Biology 101
3. Tuesday 10 AM: Takes attendance for Chemistry 101
4. Wednesday 2 PM: Takes attendance for Physics 101

**Weekly Review:**
1. Friday: Views weekly reports for all courses
2. Identifies students with <75% attendance
3. Sends notifications to parents

**Monthly:**
1. Generates monthly reports
2. Reviews performance ratings
3. Submits attendance summary to administration

**Security:**
1. Logs out at end of day on shared device
2. Logs back in next morning with credentials
3. All student data remains secure

## 🛡️ Security Notes

**Current Implementation** (suitable for):
✅ Single teacher per device
✅ Local data storage  
✅ Basic security requirements
✅ Offline-first applications  
✅ Personal/classroom use

**For Production/Multi-User** (would need):
- Backend authentication server
- More secure hashing (bcrypt/argon2)
- Password reset via email
- Session timeouts
- Cloud data sync
- Multi-tenancy support

## ❓ Troubleshooting

**Q: I forgot my password. How do I reset it?**  
A: Currently no reset feature. You'll need to clear app data (loses all records) and re-register.

**Q: Can I have multiple teachers using the app?**  
A: Current version supports one teacher per device. Multiple teachers need separate devices.

**Q: Where is my data stored?**  
A: Locally on your device using SharedPreferences. Not synced to cloud.

**Q: What happens to data when I logout?**  
A: Data remains saved. Logout only clears your session. Login again to access.

**Q: App shows login screen after I registered**  
A: This is normal after app restart. Use the credentials you registered with.

**Q: Can students see their own attendance?**  
A: No, this is a teacher-only app. Students cannot login or view data.

## 🔄 Building for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🎯 Future Enhancements

- [ ] Password reset functionality
- [ ] Email verification on registration
- [ ] Biometric authentication (fingerprint/face)
- [ ] Multiple teacher accounts with role management
- [ ] Export reports to PDF/CSV
- [ ] Cloud backup and sync
- [ ] Push notifications for low attendance
- [ ] Student portal for viewing own attendance
- [ ] Parent access with notifications
- [ ] Attendance analytics and insights
- [ ] Integration with school management systems

## 📄 License

This project is open source and available for educational purposes.

## 👨‍🏫 For Teachers

This app is designed specifically for teachers who need:
- Simple, offline attendance tracking
- Course-based organization
- Detailed reporting
- Secure, private data storage
- No internet dependency
- Quick daily attendance marking

Perfect for:
- Individual teachers managing multiple classes
- Small schools
- Tutorial centers
- Training institutes
- Homeschool groups

## 📞 Support

For issues, questions, or feature requests, please refer to the documentation files:
- `AUTHENTICATION_GUIDE.md` - Detailed authentication documentation
- `COURSE_MANAGEMENT_GUIDE.md` - Course management features
- `FEATURES_OVERVIEW.md` - Complete feature list

## ✨ Key Highlights

🔐 **Secure**: Password hashing and protected access  
📚 **Organized**: Course-based attendance tracking  
📊 **Insightful**: Daily, weekly, monthly reports  
💾 **Reliable**: Local storage, works offline  
🎨 **Modern**: Material Design 3 UI  
✅ **Smart**: Duplicate prevention, validation  
📱 **Responsive**: Works on phones and tablets
