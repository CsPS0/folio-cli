class Student {
  final String name;
  final String institutionName;
  final String? uid;

  const Student({
    required this.name,
    required this.institutionName,
    this.uid,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      name: json['Nev'] ?? 'Ismeretlen',
      institutionName: json['IntezmenyNev'] ?? 'Ismeretlen intézmény',
      uid: json['Uid']?.toString(),
    );
  }
}
