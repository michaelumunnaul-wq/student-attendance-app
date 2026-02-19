class Student {
  final String id;
  final String name;

  Student({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory Student.fromJson(Map<String, dynamic> json) =>
      Student(id: json['id'], name: json['name']);

  @override
  bool operator ==(Object other) => other is Student && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
