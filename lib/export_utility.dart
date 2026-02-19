import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:csv/csv.dart';

// Export utility class for generating reports
class ExportUtility {
  // Generate CSV report
  static Future<File> generateCSVReport({
    required String title,
    required List<String> headers,
    required List<List<dynamic>> rows,
    required String fileName,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName.csv';

    final csv = const ListToCsvConverter().convert([headers, ...rows]);
    final file = File(path);
    await file.writeAsString(csv);

    return file;
  }

  // Generate PDF report for daily attendance
  static Future<File> generateDailyAttendancePDF({
    required String courseName,
    required String courseCode,
    required String date,
    required List<Map<String, String>> presentStudents,
    required List<Map<String, String>> absentStudents,
    required int totalStudents,
    required String teacherName,
  }) async {
    final pdf = pw.Document();
    final presentCount = presentStudents.length;
    final absentCount = absentStudents.length;
    final attendanceRate = totalStudents > 0
        ? (presentCount / totalStudents * 100).toStringAsFixed(1)
        : '0.0';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Daily Attendance Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),

            // Course Information
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Course: $courseName',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Code: $courseCode'),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Date: $date',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Teacher: $teacherName'),
                    ],
                  ),
                ],
              ),
            ),

            // Statistics Summary
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: const pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total Students', totalStudents.toString()),
                  _buildStatItem(
                      'Present', presentCount.toString(), PdfColors.green),
                  _buildStatItem(
                      'Absent', absentCount.toString(), PdfColors.red),
                  _buildStatItem('Rate', '$attendanceRate%', PdfColors.blue),
                ],
              ),
            ),

            // Present Students
            pw.SizedBox(height: 24),
            pw.Text(
              'Present Students ($presentCount)',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green900,
              ),
            ),
            pw.SizedBox(height: 8),
            if (presentStudents.isEmpty)
              pw.Text('No students present',
                  style: const pw.TextStyle(color: PdfColors.grey))
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.green100),
                    children: [
                      _buildTableHeader('No.'),
                      _buildTableHeader('Student Name'),
                      _buildTableHeader('Student ID'),
                    ],
                  ),
                  ...presentStudents.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final student = entry.value;
                    return pw.TableRow(
                      children: [
                        _buildTableCell(index.toString()),
                        _buildTableCell(student['name'] ?? ''),
                        _buildTableCell(student['id'] ?? ''),
                      ],
                    );
                  }),
                ],
              ),

            // Absent Students
            pw.SizedBox(height: 24),
            pw.Text(
              'Absent Students ($absentCount)',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.red900,
              ),
            ),
            pw.SizedBox(height: 8),
            if (absentStudents.isEmpty)
              pw.Text('All students present',
                  style: const pw.TextStyle(color: PdfColors.grey))
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.red100),
                    children: [
                      _buildTableHeader('No.'),
                      _buildTableHeader('Student Name'),
                      _buildTableHeader('Student ID'),
                    ],
                  ),
                  ...absentStudents.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final student = entry.value;
                    return pw.TableRow(
                      children: [
                        _buildTableCell(index.toString()),
                        _buildTableCell(student['name'] ?? ''),
                        _buildTableCell(student['id'] ?? ''),
                      ],
                    );
                  }),
                ],
              ),

            // Footer
            pw.SizedBox(height: 32),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'Generated on ${DateTime.now().toString().split('.')[0]}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/attendance_${courseCode}_$date.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // Generate PDF report for weekly attendance
  static Future<File> generateWeeklyAttendancePDF({
    required String courseName,
    required String courseCode,
    required String weekRange,
    required List<Map<String, dynamic>> studentStats,
    required int totalDays,
    required int totalPresent,
    required int totalAbsent,
    required String teacherName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Weekly Attendance Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),

            // Course Information
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Course: $courseName',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Code: $courseCode'),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Period: $weekRange',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Teacher: $teacherName'),
                    ],
                  ),
                ],
              ),
            ),

            // Statistics Summary
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: const pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Days Recorded', totalDays.toString()),
                  _buildStatItem('Total Present', totalPresent.toString(),
                      PdfColors.green),
                  _buildStatItem(
                      'Total Absent', totalAbsent.toString(), PdfColors.red),
                ],
              ),
            ),

            // Student Statistics Table
            pw.SizedBox(height: 24),
            pw.Text(
              'Student Attendance Statistics',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    _buildTableHeader('No.'),
                    _buildTableHeader('Student Name'),
                    _buildTableHeader('ID'),
                    _buildTableHeader('Present'),
                    _buildTableHeader('Absent'),
                    _buildTableHeader('Rate'),
                  ],
                ),
                ...studentStats.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final student = entry.value;
                  return pw.TableRow(
                    children: [
                      _buildTableCell(index.toString()),
                      _buildTableCell(student['name'] ?? ''),
                      _buildTableCell(student['id'] ?? ''),
                      _buildTableCell(student['present'].toString()),
                      _buildTableCell(student['absent'].toString()),
                      _buildTableCell('${student['rate']}%'),
                    ],
                  );
                }),
              ],
            ),

            // Footer
            pw.SizedBox(height: 32),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'Generated on ${DateTime.now().toString().split('.')[0]}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
        '${directory.path}/weekly_attendance_${courseCode}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // Generate PDF report for monthly attendance
  static Future<File> generateMonthlyAttendancePDF({
    required String courseName,
    required String courseCode,
    required String monthYear,
    required List<Map<String, dynamic>> studentStats,
    required int totalDays,
    required int totalPresent,
    required int totalAbsent,
    required double avgAttendanceRate,
    required String teacherName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Monthly Attendance Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),

            // Course Information
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Course: $courseName',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Code: $courseCode'),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Period: $monthYear',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Teacher: $teacherName'),
                    ],
                  ),
                ],
              ),
            ),

            // Statistics Summary
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: const pw.BoxDecoration(
                color: PdfColors.purple50,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Days Recorded', totalDays.toString()),
                  _buildStatItem('Total Present', totalPresent.toString(),
                      PdfColors.green),
                  _buildStatItem(
                      'Total Absent', totalAbsent.toString(), PdfColors.red),
                  _buildStatItem(
                      'Avg Rate',
                      '${avgAttendanceRate.toStringAsFixed(1)}%',
                      PdfColors.purple),
                ],
              ),
            ),

            // Student Performance Table
            pw.SizedBox(height: 24),
            pw.Text(
              'Student Performance Summary',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: PdfColors.purple100),
                  children: [
                    _buildTableHeader('No.'),
                    _buildTableHeader('Student Name'),
                    _buildTableHeader('ID'),
                    _buildTableHeader('Present'),
                    _buildTableHeader('Absent'),
                    _buildTableHeader('Rate'),
                    _buildTableHeader('Status'),
                  ],
                ),
                ...studentStats.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final student = entry.value;
                  return pw.TableRow(
                    children: [
                      _buildTableCell(index.toString()),
                      _buildTableCell(student['name'] ?? ''),
                      _buildTableCell(student['id'] ?? ''),
                      _buildTableCell(student['present'].toString()),
                      _buildTableCell(student['absent'].toString()),
                      _buildTableCell('${student['rate']}%'),
                      _buildTableCell(student['status'] ?? 'N/A'),
                    ],
                  );
                }),
              ],
            ),

            // Footer
            pw.SizedBox(height: 32),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'Generated on ${DateTime.now().toString().split('.')[0]}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
        '${directory.path}/monthly_attendance_${courseCode}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // Helper: Build stat item for PDF
  static pw.Widget _buildStatItem(String label, String value,
      [PdfColor? color]) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  // Helper: Build table header
  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Helper: Build table cell
  static pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Share file via social media or other apps
  static Future<void> shareFile({
    required File file,
    required String text,
    required String subject,
  }) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: text,
      subject: subject,
    );
  }

  // Share text only (for quick stats)
  static Future<void> shareText({
    required String text,
    required String subject,
  }) async {
    await Share.share(
      text,
      subject: subject,
    );
  }
}

// Export dialog for user to choose export format
class ExportDialog extends StatelessWidget {
  final VoidCallback onExportPDF;
  final VoidCallback onExportCSV;
  final VoidCallback onShare;

  const ExportDialog({
    super.key,
    required this.onExportPDF,
    required this.onExportCSV,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Report'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text('Download as PDF'),
            subtitle: const Text('Professional formatted report'),
            onTap: () {
              Navigator.pop(context);
              onExportPDF();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.table_chart, color: Colors.green),
            title: const Text('Download as CSV'),
            subtitle: const Text('Spreadsheet format'),
            onTap: () {
              Navigator.pop(context);
              onExportCSV();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.share, color: Colors.blue),
            title: const Text('Share to Social Media'),
            subtitle: const Text('WhatsApp, Email, etc.'),
            onTap: () {
              Navigator.pop(context);
              onShare();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
