import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/student.dart';

class ExportHelper {
  // ─── FILE PATHS ────────────────────────────────────────
  static Future<String> get _dir async {
    final d = await getApplicationDocumentsDirectory();
    return d.path;
  }

  // ─── CSV ───────────────────────────────────────────────
  static Future<File> buildCSV({
    required List<String> headers,
    required List<List<dynamic>> rows,
    required String fileName,
  }) async {
    // Manually build CSV string
    final allRows = [headers, ...rows];
    final csvData = allRows.map((row) => row.join(',')).join('\n');
    final file = File('${await _dir}/$fileName.csv');
    await file.writeAsString(csvData);
    return file;
  }

  // ─── PDF helpers ──────────────────────────────────────
  static pw.Widget _cell(String t, {bool bold = false, PdfColor? color}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(
          t,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color),
        ),
      );

  static pw.Widget _statBox(String label, String value, PdfColor color) =>
      pw.Column(children: [
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 22, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 2),
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
      ]);

  static pw.Widget _courseInfo(String courseName, String courseCode,
          String period, String teacher) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Course: $courseName',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Code: $courseCode'),
                  ]),
              pw.SizedBox(height: 6),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Period: $period',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Teacher: $teacher'),
                  ]),
            ]),
      );

  static pw.Widget _studentTable(
      List<Map<String, String>> students, PdfColor headerColor) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerColor),
          children: [
            _cell('#', bold: true),
            _cell('Student Name', bold: true),
            _cell('Student ID', bold: true),
          ],
        ),
        ...students.asMap().entries.map((e) => pw.TableRow(children: [
              _cell('${e.key + 1}'),
              _cell(e.value['name'] ?? ''),
              _cell(e.value['id'] ?? ''),
            ])),
      ],
    );
  }

  // ─── DAILY PDF ────────────────────────────────────────
  static Future<File> dailyPDF({
    required String courseName,
    required String courseCode,
    required String date,
    required List<Student> present,
    required List<Student> absent,
    required int total,
    required String teacherName,
  }) async {
    final pdf = pw.Document();
    final rate = total > 0 ? (present.length / total * 100) : 0.0;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        pw.Text('Daily Attendance Report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 12),
        _courseInfo(courseName, courseCode, date, teacherName),
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _statBox('Total', '$total', PdfColors.blueGrey700),
                _statBox('Present', '${present.length}', PdfColors.green700),
                _statBox('Absent', '${absent.length}', PdfColors.red700),
                _statBox(
                    'Rate', '${rate.toStringAsFixed(1)}%', PdfColors.blue700),
              ]),
        ),
        pw.SizedBox(height: 20),
        pw.Text('Present Students (${present.length})',
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green900)),
        pw.SizedBox(height: 6),
        present.isEmpty
            ? pw.Text('None', style: const pw.TextStyle(color: PdfColors.grey))
            : _studentTable(
                present.map((s) => {'name': s.name, 'id': s.id}).toList(),
                PdfColors.green100),
        pw.SizedBox(height: 20),
        pw.Text('Absent Students (${absent.length})',
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.red900)),
        pw.SizedBox(height: 6),
        absent.isEmpty
            ? pw.Text('All present 🎉',
                style: const pw.TextStyle(color: PdfColors.grey))
            : _studentTable(
                absent.map((s) => {'name': s.name, 'id': s.id}).toList(),
                PdfColors.red100),
        pw.SizedBox(height: 24),
        pw.Divider(),
        pw.Text('Generated: ${DateTime.now()}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
      ],
    ));

    final file = File('${await _dir}/daily_${courseCode}_$date.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ─── WEEKLY PDF ───────────────────────────────────────
  static Future<File> weeklyPDF({
    required String courseName,
    required String courseCode,
    required String weekRange,
    required int totalDays,
    required int totalPresent,
    required int totalAbsent,
    required List<Map<String, dynamic>> studentStats,
    required String teacherName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        pw.Text('Weekly Attendance Report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 12),
        _courseInfo(courseName, courseCode, weekRange, teacherName),
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: const pw.BoxDecoration(color: PdfColors.green50),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _statBox('Days', '$totalDays', PdfColors.blueGrey700),
                _statBox('Present', '$totalPresent', PdfColors.green700),
                _statBox('Absent', '$totalAbsent', PdfColors.red700),
              ]),
        ),
        pw.SizedBox(height: 20),
        pw.Text('Student Weekly Summary',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue100),
              children: ['#', 'Name', 'ID', 'Present', 'Absent', 'Rate']
                  .map((h) => _cell(h, bold: true))
                  .toList(),
            ),
            ...studentStats.asMap().entries.map((e) {
              final s = e.value;
              return pw.TableRow(children: [
                _cell('${e.key + 1}'),
                _cell(s['name']),
                _cell(s['id']),
                _cell('${s['present']}'),
                _cell('${s['absent']}'),
                _cell('${s['rate']}%'),
              ]);
            }),
          ],
        ),
        pw.SizedBox(height: 24),
        pw.Divider(),
        pw.Text('Generated: ${DateTime.now()}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
      ],
    ));

    final file = File(
        '${await _dir}/weekly_${courseCode}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ─── MONTHLY PDF ──────────────────────────────────────
  static Future<File> monthlyPDF({
    required String courseName,
    required String courseCode,
    required String monthYear,
    required int totalDays,
    required int totalPresent,
    required int totalAbsent,
    required double avgRate,
    required List<Map<String, dynamic>> studentStats,
    required String teacherName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        pw.Text('Monthly Attendance Report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 12),
        _courseInfo(courseName, courseCode, monthYear, teacherName),
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: const pw.BoxDecoration(color: PdfColors.purple50),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _statBox('Days', '$totalDays', PdfColors.blueGrey700),
                _statBox('Present', '$totalPresent', PdfColors.green700),
                _statBox('Absent', '$totalAbsent', PdfColors.red700),
                _statBox('Avg Rate', '${avgRate.toStringAsFixed(1)}%',
                    PdfColors.purple700),
              ]),
        ),
        pw.SizedBox(height: 20),
        pw.Text('Monthly Performance',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.purple100),
              children: [
                '#',
                'Name',
                'ID',
                'Present',
                'Absent',
                'Rate',
                'Status'
              ].map((h) => _cell(h, bold: true)).toList(),
            ),
            ...studentStats.asMap().entries.map((e) {
              final s = e.value;
              final rate = double.tryParse(s['rate'].toString()) ?? 0;
              final statusColor = rate >= 90
                  ? PdfColors.green700
                  : rate >= 75
                      ? PdfColors.lightGreen700
                      : rate >= 60
                          ? PdfColors.orange700
                          : PdfColors.red700;
              return pw.TableRow(children: [
                _cell('${e.key + 1}'),
                _cell(s['name']),
                _cell(s['id']),
                _cell('${s['present']}'),
                _cell('${s['absent']}'),
                _cell('${s['rate']}%'),
                _cell(s['status'], color: statusColor),
              ]);
            }),
          ],
        ),
        pw.SizedBox(height: 24),
        pw.Divider(),
        pw.Text('Generated: ${DateTime.now()}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
      ],
    ));

    final file = File(
        '${await _dir}/monthly_${courseCode}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ─── SHARE ────────────────────────────────────────────
  static Future<void> shareFile(File file,
      {required String subject, required String body}) async {
    await Share.shareXFiles([XFile(file.path)], subject: subject, text: body);
  }

  static Future<void> shareText(String text, {required String subject}) async {
    await Share.share(text, subject: subject);
  }
}
