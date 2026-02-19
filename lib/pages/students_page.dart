import 'package:flutter/material.dart';
import '../models/student.dart';
import '../utils/db_helper.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});
  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  List<Student> _students = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final students = await DbHelper.getStudents();
    setState(() => _students = students);
  }

  Future<void> _add() async {
    if (!_formKey.currentState!.validate()) return;
    final id = _idCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    // Duplicate ID check
    if (_students.any((s) => s.id == id)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('❌ A student with this ID already exists!'),
          backgroundColor: Colors.red));
      return;
    }

    _students.add(Student(id: id, name: name));
    await DbHelper.saveStudents(_students);
    _nameCtrl.clear();
    _idCtrl.clear();
    FocusScope.of(context).unfocus();
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Student added successfully'),
          backgroundColor: Colors.green));
    }
  }

  Future<void> _delete(Student student) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text('Remove "${student.name}" from the system?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      _students.removeWhere((s) => s.id == student.id);
      await DbHelper.saveStudents(_students);
      _load();
    }
  }

  List<Student> get _filtered => _search.isEmpty
      ? _students
      : _students
          .where((s) =>
              s.name.toLowerCase().contains(_search.toLowerCase()) ||
              s.id.toLowerCase().contains(_search.toLowerCase()))
          .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        // ─── Add Student Form ────────────────────────────
        Container(
          color: Colors.grey[50],
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(children: [
              Text('Add New Student',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Student Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                    isDense: true),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _idCtrl,
                decoration: const InputDecoration(
                    labelText: 'Student ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                    isDense: true),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Student'),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ]),
          ),
        ),
        const Divider(height: 1),

        // ─── Search bar ────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Search by name or ID…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _search = ''))
                  : null,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
          ),
        ),

        // ─── Student count ─────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            const Icon(Icons.people, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text('${_filtered.length} of ${_students.length} student(s)',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 4),

        // ─── List ──────────────────────────────────────
        Expanded(
          child: _students.isEmpty
              ? const Center(child: Text('No students added yet'))
              : _filtered.isEmpty
                  ? const Center(child: Text('No matching students'))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final s = _filtered[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(s.name[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold)),
                            ),
                            title: Text(s.name),
                            subtitle: Text('ID: ${s.id}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => _delete(s),
                            ),
                          ),
                        );
                      }),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    super.dispose();
  }
}
