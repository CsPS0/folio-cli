import '../models/models.dart';

class IcsExporter {
  static String generate(List<TimetableEntry> timetable, List<Exam> exams) {
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
      final start = lesson.startTime?.toUtc();
      final end = lesson.endTime?.toUtc();
      if (start == null || end == null) continue;

      final subject = lesson.subject;
      final theme = lesson.theme ?? '';
      final uid = 'lesson-${lesson.uid ?? start.millisecondsSinceEpoch}@folio';

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
      final date = exam.date?.toUtc();
      if (date == null) continue;

      final subject = exam.subject;
      final type = exam.mode;
      final theme = exam.theme ?? '';
      final uid = 'exam-${exam.uid ?? date.millisecondsSinceEpoch}@folio';

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
