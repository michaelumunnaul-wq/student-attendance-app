class CourseEnrollment {
  final String courseId;
  final List<String> studentIds;

  CourseEnrollment({required this.courseId, required this.studentIds});

  Map<String, dynamic> toJson() => {
        'courseId': courseId,
        'studentIds': studentIds,
      };

  factory CourseEnrollment.fromJson(Map<String, dynamic> json) =>
      CourseEnrollment(
        courseId: json['courseId'],
        studentIds: List<String>.from(json['studentIds']),
      );
}

class AttendanceRecord {
  final String courseId;
  final String date;
  final Map<String, bool> attendance;

  AttendanceRecord({
    required this.courseId,
    required this.date,
    required this.attendance,
  });

  Map<String, dynamic> toJson() => {
        'courseId': courseId,
        'date': date,
        'attendance': attendance,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        courseId: json['courseId'],
        date: json['date'],
        attendance: Map<String, bool>.from(json['attendance']),
      );
}
