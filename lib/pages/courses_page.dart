import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/student.dart';
import '../utils/db_helper.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});
  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final courses = await DbHelper.getCourses();
    setState(() => _courses = courses);
  }

  void _showAddDialog() {
    showDialog(
        context: context,
        builder: (_) => _AddCourseDialog(
              existingCodes: _courses.map((c) => c.code).toList(),
              onAdd: (course) async {
                _courses.add(course);
                await DbHelper.saveCourses(_courses);
                _load();
              },
            ));
  }

  Future<void> _delete(String courseId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Course'),
        content: const Text(
            'This will remove all enrollments and attendance for this course.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await DbHelper.deleteCourse(courseId);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Course deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            const Icon(Icons.book, color: Colors.blue),
            const SizedBox(width: 8),
            Text('${_courses.length} Course(s)',
                style: Theme.of(context).textTheme.titleMedium),
          ]),
        ),
        Expanded(
          child: _courses.isEmpty
              ? const Center(
                  child: Text('No courses yet.\nTap + to add one.',
                      textAlign: TextAlign.center))
              : ListView.builder(
                  itemCount: _courses.length,
                  itemBuilder: (_, i) {
                    final c = _courses[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                              c.code.substring(0, c.code.length.clamp(0, 3)),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                        ),
                        title: Text(c.name),
                        subtitle: Text(
                            '${c.code}${c.description.isNotEmpty ? ' • ${c.description}' : ''}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _delete(c.id),
                        ),
                        onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        CourseDetailPage(course: c)))
                            .then((_) => _load()),
                      ),
                    );
                  },
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Course'),
      ),
    );
  }
}

// ─── Add Course Dialog ────────────────────────────────
class _AddCourseDialog extends StatefulWidget {
  final List<String> existingCodes;
  final void Function(Course) onAdd;
  const _AddCourseDialog({required this.existingCodes, required this.onAdd});
  @override
  State<_AddCourseDialog> createState() => _AddCourseDialogState();
}

class _AddCourseDialogState extends State<_AddCourseDialog> {
  final _key = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Course'),
      content: Form(
        key: _key,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
                labelText: 'Course Name', border: OutlineInputBorder()),
            validator: (v) => v!.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _codeCtrl,
            decoration: const InputDecoration(
                labelText: 'Course Code (unique)',
                border: OutlineInputBorder()),
            validator: (v) {
              if (v!.trim().isEmpty) return 'Required';
              if (widget.existingCodes.contains(v.trim())) {
                return 'Code already exists';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder()),
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_key.currentState!.validate()) {
              widget.onAdd(Course(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameCtrl.text.trim(),
                code: _codeCtrl.text.trim(),
                description: _descCtrl.text.trim(),
              ));
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }
}

// ─── Course Detail / Enrollment ───────────────────────
class CourseDetailPage extends StatefulWidget {
  final Course course;
  const CourseDetailPage({super.key, required this.course});
  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  List<Student> _enrolled = [];
  List<Student> _all = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await DbHelper.getStudents();
    final enrolled = await DbHelper.getEnrolledStudents(widget.course.id);
    setState(() {
      _all = all;
      _enrolled = enrolled;
    });
  }

  Future<void> _showEnrollDialog() async {
    final enrolledIds = _enrolled.map((s) => s.id).toSet();
    final available = _all.where((s) => !enrolledIds.contains(s.id)).toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All students are already enrolled')));
      return;
    }
    final selected = <String>{};
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
                title: const Text('Enroll Students'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                      shrinkWrap: true,
                      children: available
                          .map((s) => CheckboxListTile(
                                title: Text(s.name),
                                subtitle: Text('ID: ${s.id}'),
                                value: selected.contains(s.id),
                                onChanged: (v) => setS(() => v!
                                    ? selected.add(s.id)
                                    : selected.remove(s.id)),
                              ))
                          .toList()),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () async {
                            final ids = [
                              ..._enrolled.map((s) => s.id),
                              ...selected
                            ];
                            await DbHelper.saveEnrollment(
                                widget.course.id, ids);
                            Navigator.pop(ctx);
                            _load();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(
                                      '${selected.length} student(s) enrolled'),
                                  backgroundColor: Colors.green));
                            }
                          },
                    child: Text('Enroll (${selected.length})'),
                  ),
                ],
              )),
    );
  }

  Future<void> _remove(Student student) async {
    final ids =
        _enrolled.map((s) => s.id).where((id) => id != student.id).toList();
    await DbHelper.saveEnrollment(widget.course.id, ids);
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${student.name} removed from course')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(children: [
        Card(
          margin: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.course.name,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text('Code: ${widget.course.code}'),
              if (widget.course.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(widget.course.description,
                    style: TextStyle(color: Colors.grey[600])),
              ],
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _stat('Enrolled', '${_enrolled.length}'),
                _stat('Available', '${_all.length - _enrolled.length}'),
              ]),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Enrolled Students',
                  style: Theme.of(context).textTheme.titleMedium),
              ElevatedButton.icon(
                onPressed: _showEnrollDialog,
                icon: const Icon(Icons.add),
                label: const Text('Enroll'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _enrolled.isEmpty
              ? const Center(child: Text('No students enrolled in this course'))
              : ListView.builder(
                  itemCount: _enrolled.length,
                  itemBuilder: (_, i) {
                    final s = _enrolled[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading:
                            CircleAvatar(child: Text(s.name[0].toUpperCase())),
                        title: Text(s.name),
                        subtitle: Text('ID: ${s.id}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red),
                          onPressed: () => _remove(s),
                        ),
                      ),
                    );
                  }),
        ),
      ]),
    );
  }

  Widget _stat(String label, String value) => Column(children: [
        Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label),
      ]);
}
