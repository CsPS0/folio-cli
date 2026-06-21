class TimetableEntry {
  final String subject;
  final String? theme;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? date;
  final int lessonNumber;
  final String? uid;
  final String? teacher;
  final String? substituteTeacher;
  final String? room;
  final String? status;
  final String? typeName;
  final String? presenceStatus;
  final String? presenceName;

  const TimetableEntry({
    required this.subject,
    this.theme,
    this.startTime,
    this.endTime,
    this.date,
    this.lessonNumber = 99,
    this.uid,
    this.teacher,
    this.substituteTeacher,
    this.room,
    this.status,
    this.typeName,
    this.presenceStatus,
    this.presenceName,
  });

  bool get isCancelled {
    final s = status?.toLowerCase() ?? '';
    final t = typeName?.toLowerCase() ?? '';
    return s.contains('elmaradt') || s.contains('elmarad') || t.contains('elmaradt') || t.contains('elmarad');
  }

  bool get wasAbsent {
    final p = presenceStatus?.toLowerCase() ?? '';
    return p.contains('hianyzas') || p.contains('hiányzás');
  }

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    int parsedLessonNumber = 99;
    final oraszamRaw = json['Oraszam'];
    if (oraszamRaw != null) {
      final numStr = oraszamRaw.toString().replaceAll(RegExp(r'[^0-9]'), '');
      if (numStr.isNotEmpty) {
        parsedLessonNumber = int.parse(numStr);
      }
    }

    return TimetableEntry(
      subject: json['Tantargy']?['Nev'] ?? 'Tanóra',
      theme: json['Tema'],
      startTime: json['KezdetIdopont'] != null ? DateTime.tryParse(json['KezdetIdopont'])?.toLocal() : null,
      endTime: json['VegIdopont'] != null ? DateTime.tryParse(json['VegIdopont'])?.toLocal() : null,
      date: json['Datum'] != null ? DateTime.tryParse(json['Datum'])?.toLocal() : null,
      lessonNumber: parsedLessonNumber,
      uid: json['Uid'],
      teacher: json['TanarNeve'],
      substituteTeacher: json['HelyettesTanarNeve'],
      room: json['TeremNeve'],
      status: json['Allapot']?['Nev'],
      typeName: json['Tipus']?['Nev'],
      presenceStatus: json['TanuloJelenlet']?['Nev'],
      presenceName: json['TanuloJelenlet']?['Leiras'],
    );
  }
}
