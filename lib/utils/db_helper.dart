import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';

class DbHelper {
  // ─── COURSES ─────────────────────────────────────────
  static Future<List<Course>> getCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('courses') ?? '[]';
    return (json.decode(raw) as List).map((e) => Course.fromJson(e)).toList();
  }

  static Future<void> saveCourses(List<Course> courses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'courses', json.encode(courses.map((c) => c.toJson()).toList()));
  }

  static Future<void> deleteCourse(String courseId) async {
    final courses = await getCourses();
    courses.removeWhere((c) => c.id == courseId);
    await saveCourses(courses);
    // clean up linked data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('enrollment_$courseId');
    // attendance keys are cleaned lazily
  }

  // ─── STUDENTS ─────────────────────────────────────────
  static Future<List<Student>> getStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('students') ?? '[]';
    return (json.decode(raw) as List).map((e) => Student.fromJson(e)).toList();
  }

  static Future<void> saveStudents(List<Student> students) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'students', json.encode(students.map((s) => s.toJson()).toList()));
  }

  // ─── ENROLLMENT ───────────────────────────────────────
  static Future<List<String>> getEnrolledIds(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('enrollment_$courseId');
    if (raw == null) return [];
    return CourseEnrollment.fromJson(json.decode(raw)).studentIds;
  }

  static Future<void> saveEnrollment(
      String courseId, List<String> studentIds) async {
    final prefs = await SharedPreferences.getInstance();
    final enrollment =
        CourseEnrollment(courseId: courseId, studentIds: studentIds);
    await prefs.setString(
        'enrollment_$courseId', json.encode(enrollment.toJson()));
  }

  static Future<List<Student>> getEnrolledStudents(String courseId) async {
    final all = await getStudents();
    final ids = await getEnrolledIds(courseId);
    return all.where((s) => ids.contains(s.id)).toList();
  }

  // ─── ATTENDANCE ───────────────────────────────────────
  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static Future<AttendanceRecord?> getAttendance(
      String courseId, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('attendance_${courseId}_${dateKey(date)}');
    if (raw == null) return null;
    return AttendanceRecord.fromJson(json.decode(raw));
  }

  static Future<void> saveAttendance(AttendanceRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'attendance_${record.courseId}_${record.date}', json.encode(record.toJson()));
  }

  /// Returns all AttendanceRecords for a course between [from] and [to] (inclusive).
  static Future<List<AttendanceRecord>> getAttendanceRange(
      String courseId, DateTime from, DateTime to) async {
    final prefs = await SharedPreferences.getInstance();
    final records = <AttendanceRecord>[];
    for (var d = from;
        !d.isAfter(to);
        d = d.add(const Duration(days: 1))) {
      final raw = prefs.getString('attendance_${courseId}_${dateKey(d)}');
      if (raw != null) records.add(AttendanceRecord.fromJson(json.decode(raw)));
    }
    return records;
  }
}
