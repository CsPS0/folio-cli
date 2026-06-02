class Homework {
  final String subject;
  final String text;
  final DateTime? assignedDate;
  final DateTime? deadline;

  const Homework({
    required this.subject,
    required this.text,
    this.assignedDate,
    this.deadline,
  });

  factory Homework.fromJson(Map<String, dynamic> json) {
    String parsedSubject = 'Ismeretlen tantárgy';
    if (json['Tantargy'] is Map) {
      parsedSubject = json['Tantargy']['Nev'] ?? parsedSubject;
    } else if (json['Tantargy'] is String) {
      parsedSubject = json['Tantargy'];
    }

    String parsedText = json['Szoveg'] ?? '';
    parsedText = parsedText.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');

    return Homework(
      subject: parsedSubject,
      text: parsedText,
      assignedDate: json['RogzitesIdopontja'] != null ? DateTime.tryParse(json['RogzitesIdopontja'])?.toLocal() : null,
      deadline: (json['HataridoDatuma'] ?? json['HataridoIdopontja']) != null 
          ? DateTime.tryParse((json['HataridoDatuma'] ?? json['HataridoIdopontja']).toString())?.toLocal() 
          : null,
    );
  }
}
