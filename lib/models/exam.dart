class Exam {
  final String subject;
  final DateTime? date;
  final String mode;
  final String? theme;
  final String? uid;

  const Exam({
    required this.subject,
    this.date,
    required this.mode,
    this.theme,
    this.uid,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      subject: json['Tantargy']?['Nev'] ?? 'Ismeretlen tantárgy',
      date: json['Datum'] != null ? DateTime.tryParse(json['Datum'])?.toLocal() : null,
      mode: json['Modja']?['Nev'] ?? 'Számonkérés',
      theme: json['Tema'],
      uid: json['Uid'],
    );
  }
}
