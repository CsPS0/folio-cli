import 'dart:io';

class IcsExporter {
  static String generate(List<dynamic> timetable, List<dynamic> exams) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//Folio//Folio CLI//HU');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    buffer.writeln('X-WR-CALNAME:Folio Órarend és Vizsgák');

    final now = DateTime.now().toUtc();
    final dtstamp = _formatDate(now);

    for (var lesson in timetable) {
      final startStr = lesson['KezdetIdopont'];
      final endStr = lesson['VegIdopont'];
      if (startStr == null || endStr == null) continue;

      final start = DateTime.tryParse(startStr)?.toUtc();
      final end = DateTime.tryParse(endStr)?.toUtc();
      if (start == null || end == null) continue;

      final subject = lesson['Tantargy']?['Nev'] ?? 'Tanóra';
      final theme = lesson['Tema'] ?? '';
      final uid = 'lesson-${lesson['Uid'] ?? start.millisecondsSinceEpoch}@folio';

      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:$uid');
      buffer.writeln('DTSTAMP:$dtstamp');
      buffer.writeln('DTSTART:${_formatDate(start)}');
      buffer.writeln('DTEND:${_formatDate(end)}');
      buffer.writeln('SUMMARY:$subject');
      buffer.writeln('DESCRIPTION:$theme');
      buffer.writeln('END:VEVENT');
    }

    for (var exam in exams) {
      final dateStr = exam['Datum'];
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr)?.toUtc();
      if (date == null) continue;

      final subject = exam['Tantargy']?['Nev'] ?? 'Vizsga';
      final type = exam['Modja']?['Nev'] ?? 'Számonkérés';
      final theme = exam['Tema'] ?? '';
      final uid = 'exam-${exam['Uid'] ?? date.millisecondsSinceEpoch}@folio';

      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:$uid');
      buffer.writeln('DTSTAMP:$dtstamp');
      buffer.writeln('DTSTART;VALUE=DATE:${_formatDateOnly(date)}');
      buffer.writeln('SUMMARY:[$type] $subject');
      buffer.writeln('DESCRIPTION:$theme');
      buffer.writeln('END:VEVENT');
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}T${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}${dt.second.toString().padLeft(2, '0')}Z';
  }

  static String _formatDateOnly(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
  }
}
