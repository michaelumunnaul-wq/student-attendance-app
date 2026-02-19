import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/student.dart';
import '../utils/db_helper.dart';
import '../utils/auth_helper.dart';
import '../utils/export_helper.dart';
import '../widgets/stat_card.dart';
import '../widgets/export_dialog.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<Course> _courses = [];
  Course? _selected;
  int _tab = 0; // 0=daily 1=weekly 2=monthly

  @override
  void initState() {
    super.initState();
    DbHelper.getCourses().then((c) => setState(() {
          _courses = c;
          if (c.isNotEmpty) _selected = c.first;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _courses.isEmpty
          ? const Center(
              child: Text('No courses yet.\nAdd a course first.',
                  textAlign: TextAlign.center))
          : Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: DropdownButtonFormField<Course>(
                  initialValue: _selected,
                  decoration: const InputDecoration(
                      labelText: 'Select Course',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.book)),
                  items: _courses
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('${c.code} — ${c.name}'),
                          ))
                      .toList(),
                  onChanged: (c) => setState(() => _selected = c),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                        value: 0,
                        label: Text('Daily'),
                        icon: Icon(Icons.today, size: 16)),
                    ButtonSegment(
                        value: 1,
                        label: Text('Weekly'),
                        icon: Icon(Icons.view_week, size: 16)),
                    ButtonSegment(
                        value: 2,
                        label: Text('Monthly'),
                        icon: Icon(Icons.calendar_month, size: 16)),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
                ),
              ),
              if (_selected != null)
                Expanded(
                    child: IndexedStack(
                  index: _tab,
                  children: [
                    DailyReport(course: _selected!),
                    WeeklyReport(course: _selected!),
                    MonthlyReport(course: _selected!),
                  ],
                )),
            ]),
    );
  }
}

// ════════════════════════════════════════════════════════
// DAILY REPORT
// ════════════════════════════════════════════════════════
class DailyReport extends StatefulWidget {
  final Course course;
  const DailyReport({super.key, required this.course});
  @override
  State<DailyReport> createState() => _DailyReportState();
}

class _DailyReportState extends State<DailyReport> {
  List<Student> _students = [];
  Map<String, bool> _attendance = {};
  DateTime _date = DateTime.now();
  bool _hasRecord = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(DailyReport old) {
    super.didUpdateWidget(old);
    if (old.course.id != widget.course.id) _load();
  }

  Future<void> _load() async {
    final students = await DbHelper.getEnrolledStudents(widget.course.id);
    final record = await DbHelper.getAttendance(widget.course.id, _date);
    setState(() {
      _students = students;
      _hasRecord = record != null;
      _attendance = record?.attendance ?? {};
    });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime(2020),
        lastDate: DateTime.now());
    if (d != null) {
      setState(() => _date = d);
      _load();
    }
  }

  List<Student> get _present =>
      _students.where((s) => _attendance[s.id] == true).toList();
  List<Student> get _absent =>
      _students.where((s) => _attendance[s.id] != true).toList();

  // ── EXPORT helpers ──────────────────────────────────
  Future<void> _exportPDF() async {
    _showLoading('Generating PDF…');
    try {
      final teacher = await AuthHelper.getCurrentUser();
      final file = await ExportHelper.dailyPDF(
        courseName: widget.course.name,
        courseCode: widget.course.code,
        date: DbHelper.dateKey(_date),
        present: _present,
        absent: _absent,
        total: _students.length,
        teacherName: teacher,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('PDF ready'),
        action: SnackBarAction(
            label: 'Share',
            onPressed: () => ExportHelper.shareFile(file,
                subject: 'Daily Attendance — ${DbHelper.dateKey(_date)}',
                body: 'Attendance report for ${widget.course.name}')),
      ));
    } catch (e) {
      Navigator.pop(context);
      _showError('$e');
    }
  }

  Future<void> _exportCSV() async {
    _showLoading('Generating CSV…');
    try {
      final rows = _students
          .map((s) =>
              [s.name, s.id, _attendance[s.id] == true ? 'Present' : 'Absent'])
          .toList();
      final file = await ExportHelper.buildCSV(
        headers: ['Student Name', 'Student ID', 'Status'],
        rows: rows,
        fileName: 'daily_${widget.course.code}_${DbHelper.dateKey(_date)}',
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('CSV ready'),
        action: SnackBarAction(
            label: 'Share',
            onPressed: () => ExportHelper.shareFile(file,
                subject: 'Attendance CSV', body: '')),
      ));
    } catch (e) {
      Navigator.pop(context);
      _showError('$e');
    }
  }

  Future<void> _shareText() async {
    final rate =
        _students.isEmpty ? 0.0 : (_present.length / _students.length * 100);
    await ExportHelper.shareText(
      '📊 Daily Attendance Report\n\n'
      'Course: ${widget.course.name} (${widget.course.code})\n'
      'Date: ${DbHelper.dateKey(_date)}\n\n'
      '✅ Present: ${_present.length}\n'
      '❌ Absent:  ${_absent.length}\n'
      '📈 Rate:    ${rate.toStringAsFixed(1)}%\n'
      '👥 Total:   ${_students.length}',
      subject: 'Attendance — ${DbHelper.dateKey(_date)}',
    );
  }

  void _showLoading(String msg) => showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
              content: Row(children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(msg),
          ])));

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $msg'), backgroundColor: Colors.red));

  @override
  Widget build(BuildContext context) {
    final rate =
        _students.isEmpty ? 0.0 : (_present.length / _students.length * 100);
    return Column(children: [
      // ── Summary card ──────────────────────────────────
      Card(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(DbHelper.dateKey(_date),
                  style: Theme.of(context).textTheme.titleMedium),
              Row(children: [
                IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickDate,
                    tooltip: 'Change date'),
                IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: !_hasRecord
                        ? null
                        : () => ExportBottomSheet.show(context,
                            onPDF: _exportPDF,
                            onCSV: _exportCSV,
                            onShareText: _shareText),
                    tooltip: 'Export'),
              ]),
            ]),
            const SizedBox(height: 10),
            if (_hasRecord)
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                StatCard(
                    label: 'Present',
                    value: '${_present.length}',
                    color: Colors.green,
                    icon: Icons.check_circle),
                StatCard(
                    label: 'Absent',
                    value: '${_absent.length}',
                    color: Colors.red,
                    icon: Icons.cancel),
                StatCard(
                    label: 'Rate',
                    value: '${rate.toStringAsFixed(1)}%',
                    color: Colors.blue,
                    icon: Icons.percent),
              ])
            else
              Text('No record for this date.',
                  style: TextStyle(color: Colors.grey[600])),
          ]),
        ),
      ),

      // ── Present / Absent tabs ─────────────────────────
      if (_hasRecord)
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(children: [
              TabBar(tabs: [
                Tab(text: 'Present (${_present.length})'),
                Tab(text: 'Absent (${_absent.length})'),
              ]),
              Expanded(
                child: TabBarView(children: [
                  _studentList(_present, Colors.green),
                  _studentList(_absent, Colors.red),
                ]),
              ),
            ]),
          ),
        ),
    ]);
  }

  Widget _studentList(List<Student> list, Color color) {
    if (list.isEmpty) return const Center(child: Text('No students here.'));
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) {
        final s = list[i];
        return ListTile(
          leading: CircleAvatar(
              backgroundColor: color.withOpacity(.15),
              child: Text(s.name[0].toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold))),
          title: Text(s.name),
          subtitle: Text('ID: ${s.id}'),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════
// WEEKLY REPORT - NOW SHOWS TOTAL PRESENT/ABSENT PER STUDENT
// ════════════════════════════════════════════════════════
class WeeklyReport extends StatefulWidget {
  final Course course;
  const WeeklyReport({super.key, required this.course});
  @override
  State<WeeklyReport> createState() => _WeeklyReportState();
}

class _WeeklyReportState extends State<WeeklyReport> {
  DateTime _weekStart = _monday(DateTime.now());
  List<Student> _students = [];
  Map<String, Map<String, int>> _stats = {};
  int _daysRecorded = 0;

  static DateTime _monday(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(WeeklyReport old) {
    super.didUpdateWidget(old);
    if (old.course.id != widget.course.id) _load();
  }

  Future<void> _load() async {
    final students = await DbHelper.getEnrolledStudents(widget.course.id);
    final end = _weekStart.add(const Duration(days: 6));
    final records =
        await DbHelper.getAttendanceRange(widget.course.id, _weekStart, end);

    final stats = <String, Map<String, int>>{
      for (var s in students) s.id: {'present': 0, 'absent': 0, 'total': 0}
    };

    for (final r in records) {
      r.attendance.forEach((id, present) {
        if (stats.containsKey(id)) {
          stats[id]!['total'] = stats[id]!['total']! + 1;
          if (present) {
            stats[id]!['present'] = stats[id]!['present']! + 1;
          } else {
            stats[id]!['absent'] = stats[id]!['absent']! + 1;
          }
        }
      });
    }

    setState(() {
      _students = students;
      _stats = stats;
      _daysRecorded = records.length;
    });
  }

  Future<void> _pickWeek() async {
    final d = await showDatePicker(
        context: context,
        initialDate: _weekStart,
        firstDate: DateTime(2020),
        lastDate: DateTime.now());
    if (d != null) {
      setState(() => _weekStart = _monday(d));
      _load();
    }
  }

  String get _range =>
      '${DbHelper.dateKey(_weekStart)} → ${DbHelper.dateKey(_weekStart.add(const Duration(days: 6)))}';

  int get _totalPresent =>
      _stats.values.fold(0, (s, m) => s + (m['present'] ?? 0));
  int get _totalAbsent =>
      _stats.values.fold(0, (s, m) => s + (m['absent'] ?? 0));

  // ── EXPORT ───────────────────────────────────────────
  Future<void> _exportPDF() async {
    _showLoading('Generating PDF…');
    try {
      final teacher = await AuthHelper.getCurrentUser();
      final studentStats = _students.map((s) {
        final m = _stats[s.id] ?? {};
        final p = m['present'] ?? 0;
        final t = m['total'] ?? 0;
        return {
          'name': s.name,
          'id': s.id,
          'present': p,
          'absent': m['absent'] ?? 0,
          'rate': t > 0 ? (p / t * 100).toStringAsFixed(1) : '0.0'
        };
      }).toList();
      final file = await ExportHelper.weeklyPDF(
        courseName: widget.course.name,
        courseCode: widget.course.code,
        weekRange: _range,
        totalDays: _daysRecorded,
        totalPresent: _totalPresent,
        totalAbsent: _totalAbsent,
        studentStats: studentStats,
        teacherName: teacher,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Weekly PDF ready'),
        action: SnackBarAction(
            label: 'Share',
            onPressed: () => ExportHelper.shareFile(file,
                subject: 'Weekly Attendance Report',
                body: 'Weekly attendance for ${widget.course.name}')),
      ));
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _exportCSV() async {
    _showLoading('Generating CSV…');
    try {
      final rows = _students.map((s) {
        final m = _stats[s.id] ?? {};
        final p = m['present'] ?? 0;
        final t = m['total'] ?? 0;
        return [
          s.name,
          s.id,
          p,
          m['absent'] ?? 0,
          t > 0 ? '${(p / t * 100).toStringAsFixed(1)}%' : '0.0%'
        ];
      }).toList();
      final file = await ExportHelper.buildCSV(
        headers: ['Name', 'ID', 'Present', 'Absent', 'Rate'],
        rows: rows,
        fileName:
            'weekly_${widget.course.code}_${DbHelper.dateKey(_weekStart)}',
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('CSV ready'),
        action: SnackBarAction(
            label: 'Share',
            onPressed: () =>
                ExportHelper.shareFile(file, subject: 'Weekly CSV', body: '')),
      ));
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _shareText() async {
    await ExportHelper.shareText(
      '📊 Weekly Attendance Report\n\n'
      'Course: ${widget.course.name} (${widget.course.code})\n'
      'Week: $_range\n\n'
      '📅 Days Recorded: $_daysRecorded\n'
      '✅ Total Present: $_totalPresent\n'
      '❌ Total Absent:  $_totalAbsent',
      subject: 'Weekly Attendance',
    );
  }

  void _showLoading(String msg) => showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
              content: Row(children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(msg),
          ])));

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Card(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                  child: Text(_range,
                      style: Theme.of(context).textTheme.titleSmall)),
              Row(children: [
                IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickWeek),
                IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: _daysRecorded == 0
                        ? null
                        : () => ExportBottomSheet.show(context,
                            onPDF: _exportPDF,
                            onCSV: _exportCSV,
                            onShareText: _shareText)),
              ]),
            ]),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              StatCard(
                  label: 'Days', value: '$_daysRecorded', color: Colors.blue),
              StatCard(
                  label: 'Total Present',
                  value: '$_totalPresent',
                  color: Colors.green),
              StatCard(
                  label: 'Total Absent',
                  value: '$_totalAbsent',
                  color: Colors.red),
            ]),
          ]),
        ),
      ),

      // Header showing we're displaying individual student records
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(children: [
          Icon(Icons.person, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text('Student Attendance Records',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  )),
        ]),
      ),

      Expanded(
          child: _students.isEmpty
              ? const Center(child: Text('No students enrolled.'))
              : ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (_, i) {
                    final s = _students[i];
                    final m = _stats[s.id] ?? {};
                    final p = m['present'] ?? 0;
                    final a = m['absent'] ?? 0;
                    final t = m['total'] ?? 0;
                    final rate = t > 0 ? p / t * 100 : 0.0;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 3),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              rate >= 75 ? Colors.green : Colors.orange,
                          child: Text(s.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(s.name),
                        subtitle: Text(
                            'ID: ${s.id} • Classes Present: $p • Classes Absent: $a',
                            style: const TextStyle(fontSize: 13)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  StatCard(
                                      label: 'Classes Present',
                                      value: '$p',
                                      color: Colors.green),
                                  StatCard(
                                      label: 'Classes Absent',
                                      value: '$a',
                                      color: Colors.red),
                                  StatCard(
                                      label: 'Attendance Rate',
                                      value: '${rate.toStringAsFixed(1)}%',
                                      color: Colors.blue),
                                ]),
                          ),
                        ],
                      ),
                    );
                  })),
    ]);
  }
}

// ════════════════════════════════════════════════════════
// MONTHLY REPORT - NOW SHOWS TOTAL PRESENT/ABSENT PER STUDENT
// ════════════════════════════════════════════════════════
class MonthlyReport extends StatefulWidget {
  final Course course;
  const MonthlyReport({super.key, required this.course});
  @override
  State<MonthlyReport> createState() => _MonthlyReportState();
}

class _MonthlyReportState extends State<MonthlyReport> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  List<Student> _students = [];
  Map<String, Map<String, int>> _stats = {};
  int _daysRecorded = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(MonthlyReport old) {
    super.didUpdateWidget(old);
    if (old.course.id != widget.course.id) _load();
  }

  Future<void> _load() async {
    final students = await DbHelper.getEnrolledStudents(widget.course.id);
    final lastDay = DateTime(_month.year, _month.month + 1, 0);
    final end = lastDay.isAfter(DateTime.now()) ? DateTime.now() : lastDay;
    final records =
        await DbHelper.getAttendanceRange(widget.course.id, _month, end);

    final stats = <String, Map<String, int>>{
      for (var s in students) s.id: {'present': 0, 'absent': 0, 'total': 0}
    };
    for (final r in records) {
      r.attendance.forEach((id, present) {
        if (stats.containsKey(id)) {
          stats[id]!['total'] = stats[id]!['total']! + 1;
          if (present) {
            stats[id]!['present'] = stats[id]!['present']! + 1;
          } else {
            stats[id]!['absent'] = stats[id]!['absent']! + 1;
          }
        }
      });
    }
    setState(() {
      _students = students;
      _stats = stats;
      _daysRecorded = records.length;
    });
  }

  Future<void> _pickMonth() async {
    final d = await showDatePicker(
        context: context,
        initialDate: _month,
        firstDate: DateTime(2020),
        lastDate: DateTime.now());
    if (d != null) {
      setState(() => _month = DateTime(d.year, d.month));
      _load();
    }
  }

  String get _monthLabel {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[_month.month - 1]} ${_month.year}';
  }

  int get _totalPresent =>
      _stats.values.fold(0, (s, m) => s + (m['present'] ?? 0));
  int get _totalAbsent =>
      _stats.values.fold(0, (s, m) => s + (m['absent'] ?? 0));
  double get _avgRate => _daysRecorded > 0 && _students.isNotEmpty
      ? _totalPresent / (_daysRecorded * _students.length) * 100
      : 0.0;

  String _status(double rate) {
    if (rate >= 90) return 'Excellent';
    if (rate >= 75) return 'Good';
    if (rate >= 60) return 'Fair';
    return 'Poor';
  }

  Color _statusColor(double rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 75) return Colors.lightGreen;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }

  // ── EXPORT ───────────────────────────────────────────
  Future<void> _exportPDF() async {
    _showLoading('Generating PDF…');
    try {
      final teacher = await AuthHelper.getCurrentUser();
      final studentStats = _students.map((s) {
        final m = _stats[s.id] ?? {};
        final p = m['present'] ?? 0;
        final t = m['total'] ?? 0;
        final rate = t > 0 ? p / t * 100 : 0.0;
        return {
          'name': s.name,
          'id': s.id,
          'present': p,
          'absent': m['absent'] ?? 0,
          'rate': rate.toStringAsFixed(1),
          'status': _status(rate)
        };
      }).toList();
      final file = await ExportHelper.monthlyPDF(
        courseName: widget.course.name,
        courseCode: widget.course.code,
        monthYear: _monthLabel,
        totalDays: _daysRecorded,
        totalPresent: _totalPresent,
        totalAbsent: _totalAbsent,
        avgRate: _avgRate,
        studentStats: studentStats,
        teacherName: teacher,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Monthly PDF ready'),
        action: SnackBarAction(
            label: 'Share',
            onPressed: () => ExportHelper.shareFile(file,
                subject: 'Monthly Attendance — $_monthLabel',
                body: 'Monthly report for ${widget.course.name}')),
      ));
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _exportCSV() async {
    _showLoading('Generating CSV…');
    try {
      final rows = _students.map((s) {
        final m = _stats[s.id] ?? {};
        final p = m['present'] ?? 0;
        final t = m['total'] ?? 0;
        final rate = t > 0 ? p / t * 100 : 0.0;
        return [
          s.name,
          s.id,
          p,
          m['absent'] ?? 0,
          '${rate.toStringAsFixed(1)}%',
          _status(rate)
        ];
      }).toList();
      final file = await ExportHelper.buildCSV(
        headers: [
          'Name',
          'ID',
          'Classes Present',
          'Classes Absent',
          'Rate',
          'Status'
        ],
        rows: rows,
        fileName:
            'monthly_${widget.course.code}_${_month.year}_${_month.month}',
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('CSV ready'),
        action: SnackBarAction(
            label: 'Share',
            onPressed: () =>
                ExportHelper.shareFile(file, subject: 'Monthly CSV', body: '')),
      ));
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _shareText() async {
    await ExportHelper.shareText(
      '📊 Monthly Attendance Report\n\n'
      'Course: ${widget.course.name} (${widget.course.code})\n'
      'Month: $_monthLabel\n\n'
      '📅 Days Recorded: $_daysRecorded\n'
      '✅ Total Present: $_totalPresent\n'
      '❌ Total Absent:  $_totalAbsent\n'
      '📈 Avg Rate:      ${_avgRate.toStringAsFixed(1)}%',
      subject: 'Monthly Attendance — $_monthLabel',
    );
  }

  void _showLoading(String msg) => showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
              content: Row(children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(msg),
          ])));

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Card(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        color: Colors.purple.shade50,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(_monthLabel, style: Theme.of(context).textTheme.titleMedium),
              Row(children: [
                IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickMonth),
                IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: _daysRecorded == 0
                        ? null
                        : () => ExportBottomSheet.show(context,
                            onPDF: _exportPDF,
                            onCSV: _exportCSV,
                            onShareText: _shareText)),
              ]),
            ]),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              StatCard(
                  label: 'Days', value: '$_daysRecorded', color: Colors.blue),
              StatCard(
                  label: 'Total Present',
                  value: '$_totalPresent',
                  color: Colors.green),
              StatCard(
                  label: 'Total Absent',
                  value: '$_totalAbsent',
                  color: Colors.red),
              StatCard(
                  label: 'Avg Rate',
                  value: '${_avgRate.toStringAsFixed(1)}%',
                  color: Colors.purple),
            ]),
          ]),
        ),
      ),

      // Header showing individual student records
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(children: [
          Icon(Icons.person, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text('Student Attendance Records',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  )),
        ]),
      ),

      Expanded(
          child: _students.isEmpty
              ? const Center(child: Text('No students enrolled.'))
              : ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (_, i) {
                    final s = _students[i];
                    final m = _stats[s.id] ?? {};
                    final p = m['present'] ?? 0;
                    final a = m['absent'] ?? 0;
                    final t = m['total'] ?? 0;
                    final rate = t > 0 ? p / t * 100 : 0.0;
                    final color = _statusColor(rate);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 3),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: color,
                          child: Text(s.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(s.name),
                        subtitle: Text(
                            'ID: ${s.id} • ${_status(rate)} • Classes Present: $p • Classes Absent: $a',
                            style: const TextStyle(fontSize: 12)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Column(children: [
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    StatCard(
                                        label: 'Classes\nPresent',
                                        value: '$p',
                                        color: Colors.green,
                                        icon: Icons.check_circle),
                                    StatCard(
                                        label: 'Classes\nAbsent',
                                        value: '$a',
                                        color: Colors.red,
                                        icon: Icons.cancel),
                                    StatCard(
                                        label: 'Total\nClasses',
                                        value: '$t',
                                        color: Colors.blue,
                                        icon: Icons.calendar_today),
                                  ]),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: t > 0 ? p / t : 0,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation(color),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                  'Attendance Rate: ${rate.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: color,
                                  )),
                            ]),
                          ),
                        ],
                      ),
                    );
                  })),
    ]);
  }
}
