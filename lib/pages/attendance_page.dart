import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';
import '../utils/db_helper.dart';
import '../widgets/stat_card.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});
  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  List<Course> _courses = [];
  Course? _selectedCourse;
  List<Student> _students = [];
  Map<String, bool> _attendance = {};
  DateTime _date = DateTime.now();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final courses = await DbHelper.getCourses();
    setState(() {
      _courses = courses;
      if (courses.isNotEmpty) {
        _selectedCourse ??= courses.first;
        _loadStudents();
      }
    });
  }

  Future<void> _loadStudents() async {
    if (_selectedCourse == null) return;
    final students = await DbHelper.getEnrolledStudents(_selectedCourse!.id);
    final record = await DbHelper.getAttendance(_selectedCourse!.id, _date);

    setState(() {
      _students = students;
      _saved = record != null;
      if (record != null) {
        _attendance = Map.from(record.attendance);
      } else {
        _attendance = {for (var s in students) s.id: false};
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _saved = false;
      });
      _loadStudents();
    }
  }

  Future<void> _save() async {
    if (_selectedCourse == null) return;
    await DbHelper.saveAttendance(AttendanceRecord(
      courseId: _selectedCourse!.id,
      date: DbHelper.dateKey(_date),
      attendance: _attendance,
    ));
    setState(() => _saved = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Attendance saved!'), backgroundColor: Colors.green));
    }
  }

  void _markAll(bool present) {
    setState(() {
      for (final s in _students) {
        _attendance[s.id] = present;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _attendance.values.where((v) => v).length;
    final absentCount = _attendance.values.where((v) => !v).length;

    return Scaffold(
      body: _courses.isEmpty
          ? const Center(
              child: Text('No courses yet.\nGo to Courses tab to add one.',
                  textAlign: TextAlign.center))
          : Column(children: [
              // ─── Course selector ───────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<Course>(
                  initialValue: _selectedCourse,
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
                  onChanged: (c) {
                    setState(() => _selectedCourse = c);
                    _loadStudents();
                  },
                ),
              ),

              // ─── Date + stats card ─────────────────────────
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(DbHelper.dateKey(_date),
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              if (_saved)
                                Text('Saved ✓',
                                    style: TextStyle(
                                        color: Colors.green[700],
                                        fontSize: 12)),
                            ]),
                        OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: const Text('Change'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        StatCard(
                            label: 'Present',
                            value: '$presentCount',
                            color: Colors.green),
                        StatCard(
                            label: 'Absent',
                            value: '$absentCount',
                            color: Colors.red),
                        StatCard(
                            label: 'Total',
                            value: '${_students.length}',
                            color: Colors.blue),
                      ],
                    ),
                  ]),
                ),
              ),

              // ─── Mark all buttons ──────────────────────────
              if (_students.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    const Text('Mark all:  ',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    OutlinedButton(
                      onPressed: () => _markAll(true),
                      child: const Text('Present'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _markAll(false),
                      child: const Text('Absent'),
                    ),
                  ]),
                ),

              // ─── Student list ──────────────────────────────
              Expanded(
                child: _students.isEmpty
                    ? const Center(
                        child: Text('No students enrolled in this course.'))
                    : ListView.builder(
                        itemCount: _students.length,
                        itemBuilder: (_, i) {
                          final s = _students[i];
                          final present = _attendance[s.id] ?? false;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 3),
                            child: CheckboxListTile(
                              secondary: CircleAvatar(
                                backgroundColor:
                                    present ? Colors.green : Colors.grey[300],
                                child: Text(s.name[0].toUpperCase(),
                                    style: TextStyle(
                                        color: present
                                            ? Colors.white
                                            : Colors.grey[600])),
                              ),
                              title: Text(s.name),
                              subtitle: Text('ID: ${s.id}'),
                              value: present,
                              activeColor: Colors.green,
                              onChanged: (v) => setState(
                                  () => _attendance[s.id] = v ?? false),
                            ),
                          );
                        }),
              ),

              // ─── Save button ───────────────────────────────
              if (_students.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Attendance'),
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                ),
            ]),
    );
  }
}
