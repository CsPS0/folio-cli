class TimetableEntry {
  final String subject;
  final String? theme;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? date;
  final int lessonNumber;
  final String? uid;

  const TimetableEntry({
    required this.subject,
    this.theme,
    this.startTime,
    this.endTime,
    this.date,
    this.lessonNumber = 99,
    this.uid,
  });

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
    );
  }
}
