class Course {
  final String id;
  final String name;
  final String code;
  final String description;

  Course({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'description': description,
      };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id'],
        name: json['name'],
        code: json['code'],
        description: json['description'] ?? '',
      );

  @override
  bool operator ==(Object other) => other is Course && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
