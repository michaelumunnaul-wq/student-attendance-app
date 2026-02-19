# Export and Share Integration Guide

## Overview

The export utility allows teachers to:
- **Download reports as PDF** - Professional formatted documents
- **Download reports as CSV** - Excel/spreadsheet compatible
- **Share to social media** - WhatsApp, Email, Facebook, Twitter, etc.

## Package Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  pdf: ^3.10.7           # PDF generation
  path_provider: ^2.1.1  # File path management
  share_plus: ^7.2.1     # Social media sharing
  csv: ^5.1.1            # CSV export
```

## How to Integrate Export Buttons

### 1. Import the Export Utility

At the top of your report pages:

```dart
import 'export_utility.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

### 2. Add Export Button to Daily Report

Add this to your `DailyReportView` build method:

```dart
@override
Widget build(BuildContext context) {
  // ... existing code ...

  return Scaffold(
    appBar: AppBar(
      title: const Text('Daily Report'),
      actions: [
        // Add Export Button
        IconButton(
          icon: const Icon(Icons.download),
          tooltip: 'Export Report',
          onPressed: () => _showExportDialog(context),
        ),
      ],
    ),
    body: Column(
      // ... existing report content ...
    ),
  );
}

// Add export dialog method
Future<void> _showExportDialog(BuildContext context) async {
  showDialog(
    context: context,
    builder: (context) => ExportDialog(
      onExportPDF: () => _exportDailyPDF(),
      onExportCSV: () => _exportDailyCSV(),
      onShare: () => _shareDailyReport(),
    ),
  );
}

// Export to PDF
Future<void> _exportDailyPDF() async {
  try {
    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF...')),
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final teacherName = prefs.getString('current_user') ?? 'Teacher';

    // Prepare student data
    final presentStudents = _students
        .where((s) => _record?.attendance[s.id] == true)
        .map((s) => {'name': s.name, 'id': s.id})
        .toList();

    final absentStudents = _students
        .where((s) => _record?.attendance[s.id] == false)
        .map((s) => {'name': s.name, 'id': s.id})
        .toList();

    // Generate PDF
    final file = await ExportUtility.generateDailyAttendancePDF(
      courseName: widget.course.name,
      courseCode: widget.course.code,
      date: _getDateKey(_selectedDate),
      presentStudents: presentStudents,
      absentStudents: absentStudents,
      totalStudents: _students.length,
      teacherName: teacherName,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved: ${file.path}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Share',
            textColor: Colors.white,
            onPressed: () {
              ExportUtility.shareFile(
                file: file,
                text: 'Daily Attendance Report for ${widget.course.name}',
                subject: 'Attendance Report - ${_getDateKey(_selectedDate)}',
              );
            },
          ),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Export to CSV
Future<void> _exportDailyCSV() async {
  try {
    final attendance = _record?.attendance ?? {};
    
    final headers = ['Student Name', 'Student ID', 'Status'];
    final rows = _students.map((student) {
      final status = attendance[student.id] == true ? 'Present' : 'Absent';
      return [student.name, student.id, status];
    }).toList();

    final file = await ExportUtility.generateCSVReport(
      title: 'Daily Attendance',
      headers: headers,
      rows: rows,
      fileName: 'attendance_${widget.course.code}_${_getDateKey(_selectedDate)}',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV saved: ${file.path}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Share',
            textColor: Colors.white,
            onPressed: () {
              ExportUtility.shareFile(
                file: file,
                text: 'Daily Attendance CSV for ${widget.course.name}',
                subject: 'Attendance CSV - ${_getDateKey(_selectedDate)}',
              );
            },
          ),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Share report (text summary + option to share file)
Future<void> _shareDailyReport() async {
  final attendance = _record?.attendance ?? {};
  final presentCount = attendance.values.where((v) => v).length;
  final absentCount = attendance.values.where((v) => !v).length;
  final rate = _students.isEmpty ? 0 : (presentCount / _students.length * 100);

  final text = '''
📊 Daily Attendance Report

Course: ${widget.course.name} (${widget.course.code})
Date: ${_getDateKey(_selectedDate)}

✅ Present: $presentCount
❌ Absent: $absentCount
📈 Attendance Rate: ${rate.toStringAsFixed(1)}%

Total Students: ${_students.length}
''';

  await ExportUtility.shareText(
    text: text,
    subject: 'Attendance Report - ${_getDateKey(_selectedDate)}',
  );
}
```

### 3. Add Export Button to Weekly Report

Similar integration for `WeeklyReportView`:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Weekly Report'),
      actions: [
        IconButton(
          icon: const Icon(Icons.download),
          tooltip: 'Export Report',
          onPressed: () => _showExportDialog(context),
        ),
      ],
    ),
    body: // ... existing content
  );
}

Future<void> _exportWeeklyPDF() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final teacherName = prefs.getString('current_user') ?? 'Teacher';

    int totalPresent = 0;
    int totalAbsent = 0;
    _weeklyStats.values.forEach((stats) {
      totalPresent += stats['present'] ?? 0;
      totalAbsent += stats['absent'] ?? 0;
    });

    final studentStats = _students.map((student) {
      final stats = _weeklyStats[student.id] ?? {'present': 0, 'absent': 0, 'total': 0};
      final present = stats['present'] ?? 0;
      final total = stats['total'] ?? 0;
      final rate = total > 0 ? (present / total * 100).toStringAsFixed(1) : '0.0';

      return {
        'name': student.name,
        'id': student.id,
        'present': present,
        'absent': stats['absent'] ?? 0,
        'rate': rate,
      };
    }).toList();

    final file = await ExportUtility.generateWeeklyAttendancePDF(
      courseName: widget.course.name,
      courseCode: widget.course.code,
      weekRange: _getWeekRange(),
      studentStats: studentStats,
      totalDays: _totalDays,
      totalPresent: totalPresent,
      totalAbsent: totalAbsent,
      teacherName: teacherName,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved: ${file.path}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Share',
            textColor: Colors.white,
            onPressed: () {
              ExportUtility.shareFile(
                file: file,
                text: 'Weekly Attendance Report for ${widget.course.name}',
                subject: 'Weekly Report - ${_getWeekRange()}',
              );
            },
          ),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
```

### 4. Add Export Button to Monthly Report

For `MonthlyReportView`:

```dart
Future<void> _exportMonthlyPDF() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final teacherName = prefs.getString('current_user') ?? 'Teacher';

    int totalPresent = 0;
    int totalAbsent = 0;
    _monthlyStats.values.forEach((stats) {
      totalPresent += stats['present'] ?? 0;
      totalAbsent += stats['absent'] ?? 0;
    });

    final avgAttendanceRate = _totalDays > 0 && _students.isNotEmpty
        ? (totalPresent / (_totalDays * _students.length) * 100)
        : 0.0;

    final studentStats = _students.map((student) {
      final stats = _monthlyStats[student.id] ?? {'present': 0, 'absent': 0, 'total': 0};
      final present = stats['present'] ?? 0;
      final total = stats['total'] ?? 0;
      final rate = total > 0 ? (present / total * 100).toStringAsFixed(1) : '0.0';
      
      String status = 'No Data';
      if (total > 0) {
        final rateNum = double.parse(rate);
        if (rateNum >= 90) status = 'Excellent';
        else if (rateNum >= 75) status = 'Good';
        else if (rateNum >= 60) status = 'Fair';
        else status = 'Poor';
      }

      return {
        'name': student.name,
        'id': student.id,
        'present': present,
        'absent': stats['absent'] ?? 0,
        'rate': rate,
        'status': status,
      };
    }).toList();

    final file = await ExportUtility.generateMonthlyAttendancePDF(
      courseName: widget.course.name,
      courseCode: widget.course.code,
      monthYear: _getMonthYear(),
      studentStats: studentStats,
      totalDays: _totalDays,
      totalPresent: totalPresent,
      totalAbsent: totalAbsent,
      avgAttendanceRate: avgAttendanceRate,
      teacherName: teacherName,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved: ${file.path}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Share',
            textColor: Colors.white,
            onPressed: () {
              ExportUtility.shareFile(
                file: file,
                text: 'Monthly Attendance Report for ${widget.course.name}',
                subject: 'Monthly Report - ${_getMonthYear()}',
              );
            },
          ),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
```

## Sharing Options

When teachers tap "Share", they can choose from:

📱 **Social Media:**
- WhatsApp
- Facebook
- Twitter/X
- Instagram (story)
- LinkedIn

📧 **Messaging:**
- Email
- SMS
- Telegram
- Messenger

💾 **Storage:**
- Save to Files
- Google Drive
- Dropbox
- OneDrive

📋 **Other:**
- Copy to clipboard
- Print
- AirDrop (iOS)
- Nearby Share (Android)

## File Locations

Generated files are saved to:
- **Android**: `/data/data/com.yourapp/app_flutter/`
- **iOS**: App Documents directory

Users can access files through:
1. The app's share dialog
2. Their device's file manager
3. Recently downloaded files

## Export Formats

### PDF Reports Include:
✅ Professional header with school logo area
✅ Course and teacher information
✅ Date/period covered
✅ Summary statistics with visual styling
✅ Detailed student tables
✅ Color-coded sections (green for present, red for absent)
✅ Attendance rate calculations
✅ Performance status (Excellent/Good/Fair/Poor)
✅ Timestamp of generation

### CSV Files Include:
✅ Headers row
✅ All student data in columns
✅ Compatible with Excel, Google Sheets
✅ Easy to import into other systems
✅ Can be edited after export

### Text Shares Include:
✅ Quick summary statistics
✅ Emoji indicators for better readability
✅ Course and date information
✅ Perfect for quick updates to parents/admin

## Platform-Specific Permissions

### Android (AndroidManifest.xml)

Add these permissions:

```xml
<manifest>
    <!-- File storage -->
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    
    <!-- For Android 13+ -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
    
    <application>
        <!-- File provider for sharing -->
        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${applicationId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths"/>
        </provider>
    </application>
</manifest>
```

Create `android/app/src/main/res/xml/file_paths.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-files-path name="external_files" path="."/>
    <files-path name="files" path="."/>
    <cache-path name="cache" path="."/>
</paths>
```

### iOS (Info.plist)

Add these keys:

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need access to save attendance reports</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to share attendance reports</string>
```

## Best Practices

1. **Always show loading indicators** when generating reports
2. **Handle errors gracefully** with user-friendly messages
3. **Confirm before overwriting** existing files
4. **Provide share option** immediately after successful export
5. **Use meaningful file names** with course code and date
6. **Test on both Android and iOS** devices
7. **Consider file size** for large reports (compress if needed)

## Example User Flow

```
Teacher in Reports Page
    ↓
Taps Download Icon
    ↓
Export Dialog Appears
    ├─ Download as PDF
    │     ↓
    │  Generating... (shows loading)
    │     ↓
    │  Success! PDF saved
    │     ↓
    │  Tap "Share" button
    │     ↓
    │  Choose WhatsApp
    │     ↓
    │  Select parent group
    │     ↓
    │  Send!
    │
    ├─ Download as CSV
    │     ↓
    │  CSV saved to device
    │     ↓
    │  Open in Excel/Sheets
    │
    └─ Share to Social Media
          ↓
       Quick text summary
          ↓
       Share to Twitter/Email
```

## Troubleshooting

**Issue**: "Permission denied"
**Solution**: Request storage permissions in AndroidManifest.xml

**Issue**: "File not found after export"
**Solution**: Use path_provider to get correct directory

**Issue**: "Share dialog doesn't appear"
**Solution**: Ensure share_plus is properly installed (`flutter pub get`)

**Issue**: "PDF is blank"
**Solution**: Check that data is properly passed to PDF generation function

**Issue**: "Can't share to WhatsApp"
**Solution**: Ensure WhatsApp is installed on the device

## Testing Checklist

- [ ] PDF generates successfully
- [ ] CSV generates successfully  
- [ ] Share dialog opens
- [ ] Can share to WhatsApp
- [ ] Can share via Email
- [ ] Can save to Files app
- [ ] File names are correct
- [ ] Data is accurate in exports
- [ ] Works on Android
- [ ] Works on iOS
- [ ] Loading indicators show
- [ ] Error messages display properly
