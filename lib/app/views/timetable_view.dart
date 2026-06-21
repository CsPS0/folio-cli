part of '../cli_app.dart';

extension FolioCliAppTimetableView on FolioCliApp {
  Future<void> _showTimetable() async {
      while (true) {
        if (!await _ensureClientReady()) return;
        _clearScreen();
        _showMainMenuBanner();
        
        final action = Select(
          prompt: 'Órarend',
          options: ['Napi nézet (okos)', 'Ezen a héten', 'Következő héten', 'Vissza'],
        ).interact();
  
        if (action == 3) return;
        _clearScreen();
        print('\n--- Órarend ---');
        final now = DateTime.now();

        if (action == 0) {
          final midnight = DateTime(now.year, now.month, now.day);
          final startOfWeek = midnight.subtract(Duration(days: now.weekday - 1));
          final endOfNextWeek = startOfWeek.add(Duration(days: 13, hours: 23, minutes: 59, seconds: 59));
          
          final results = await Future.wait([
            _client!.getTimetable(startOfWeek, endOfNextWeek),
            _client!.getExams(),
          ]);
          final timetable = results[0] as List<TimetableEntry>?;
          final exams = results[1] as List<Exam>?;

          if (timetable == null) {
            print('Nem sikerült lekérdezni az órarendet.');
            continue;
          }
          
          DateTime targetDate = midnight;
          
          List<dynamic> todayLessons = timetable.where((e) => e.date?.year == targetDate.year && e.date?.month == targetDate.month && e.date?.day == targetDate.day).toList();
          
          bool lessonsOver = false;
          if (todayLessons.isNotEmpty) {
            final lastLesson = todayLessons.reduce((a, b) => (a.endTime != null && b.endTime != null && a.endTime!.isAfter(b.endTime!)) ? a : b);
            if (lastLesson.endTime != null && lastLesson.endTime!.isBefore(now)) {
              lessonsOver = true;
            }
          } else if (targetDate.weekday >= 6) {
            lessonsOver = true;
          }
  
          if (lessonsOver) {
            print('(A mai órák véget értek, a következő tanítási nap mutatása...)');
            do {
              targetDate = targetDate.add(Duration(days: 1));
            } while (targetDate.weekday >= 6);
          }
  
          final targetLessons = timetable.where((e) => e.date?.year == targetDate.year && e.date?.month == targetDate.month && e.date?.day == targetDate.day).toList();
          targetLessons.sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
          
          print('\nNapi órarend: ${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}');
          if (targetLessons.isEmpty) {
            print('Nincsenek órák rögzítve erre a napra.');
          } else {
            for (var lesson in targetLessons) {
              String sub = AppState.instance.applyAlias(lesson.subject);
              String theme = lesson.theme ?? '';
              String start = lesson.startTime != null ? '${lesson.startTime!.hour.toString().padLeft(2, '0')}:${lesson.startTime!.minute.toString().padLeft(2, '0')}' : '';
              String end = lesson.endTime != null ? '${lesson.endTime!.hour.toString().padLeft(2, '0')}:${lesson.endTime!.minute.toString().padLeft(2, '0')}' : '';
              
              String subjectColored = sub;
              if (lesson.isCancelled) {
                subjectColored = '\x1B[31m$sub [ELMARADT]\x1B[0m';
              } else if (lesson.substituteTeacher != null && lesson.substituteTeacher!.isNotEmpty) {
                subjectColored = '\x1B[36;4m$sub\x1B[0m \x1B[36m(Helyettes tanár: ${lesson.substituteTeacher})\x1B[0m';
              } else {
                subjectColored = '\x1B[1m$sub\x1B[0m';
              }
              
              String details = '';
              if (lesson.room != null && lesson.room!.isNotEmpty) {
                details += ' [Terem: ${lesson.room}]';
              }
              if (lesson.teacher != null && lesson.teacher!.isNotEmpty && (lesson.substituteTeacher == null || lesson.substituteTeacher!.isEmpty)) {
                details += ' [Tanár: ${lesson.teacher}]';
              }
              
              String extraInfo = '';
              if (lesson.presenceStatus != null) {
                final color = lesson.wasAbsent ? '\x1B[31m' : '\x1B[33m';
                extraInfo += ' $color[Hiányzás: ${lesson.presenceName ?? lesson.presenceStatus}]\x1B[0m';
              }
              
              final matchingExams = exams?.where((e) =>
                  e.subject.toLowerCase() == lesson.subject.toLowerCase() &&
                  e.date != null &&
                  lesson.date != null &&
                  e.date!.year == lesson.date!.year &&
                  e.date!.month == lesson.date!.month &&
                  e.date!.day == lesson.date!.day
              ).toList();
              if (matchingExams != null && matchingExams.isNotEmpty) {
                for (var exam in matchingExams) {
                  extraInfo += ' \x1B[35m[Dolgozat: ${exam.mode}${exam.theme != null && exam.theme!.isNotEmpty ? " (${exam.theme})" : ""}]\x1B[0m';
                }
              }

              print('${lesson.lessonNumber.toString().padLeft(2, ' ')}. óra ($start - $end) : $subjectColored$details$extraInfo');
              if (theme.isNotEmpty && !lesson.isCancelled) {
                print('    Téma: $theme');
              }
            }
          }
          print('');
          continue;
        }

        final offsetDays = action == 2 ? 7 : 0;
        final midnight = DateTime(now.year, now.month, now.day);
        final targetDate = midnight.add(Duration(days: offsetDays));
        final startOfWeek = targetDate.subtract(Duration(days: targetDate.weekday - 1));
        final endOfWeek = startOfWeek.add(Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  
        final futures = await Future.wait([
          _client!.getTimetable(startOfWeek, endOfWeek),
          _client!.getExams(),
        ]);
        final timetable = futures[0] as List<TimetableEntry>?;
        final exams = futures[1] as List<Exam>?;

        if (timetable != null) {
          if (timetable.isEmpty) {
            print('Nincsenek órák rögzítve erre a hétre.');
          } else {
            int minOra = 99;
            int maxOra = -1;
            int maxWeekday = 5;
  
            Map<int, Map<int, List<TimetableEntry>>> matrix = {};
  
            for (var entry in timetable) {
              final date = entry.date;
              if (date == null) continue;
 
              final weekday = date.weekday;
              if (weekday > maxWeekday) maxWeekday = weekday;
              if (weekday > 7) continue;
 
              final ora = entry.lessonNumber;
              if (ora > 20) continue;
 
              if (ora < minOra) minOra = ora;
              if (ora > maxOra) maxOra = ora;
 
              matrix.putIfAbsent(ora, () => {});
              matrix[ora]!.putIfAbsent(weekday, () => []);
              matrix[ora]![weekday]!.add(entry);
            }
  
            if (minOra > maxOra) {
              print('Nincs megjeleníthető óra (ismeretlen óraszámok).');
              continue;
            }
  
            final days = ['Hétfő', 'Kedd', 'Szerda', 'Csütörtök', 'Péntek', 'Szombat', 'Vasárnap'];
            int termWidth = stdout.hasTerminal ? stdout.terminalColumns : 120;
            int colWidth = (termWidth - 7 - maxWeekday) ~/ maxWeekday;
            if (colWidth > 28) colWidth = 28;
            if (colWidth < 12) colWidth = 12;
  
            String headerTop = '┌─────';
            String headerMid = '│ Óra ';
            String headerBot = '├─────';
  
            for (int w = 1; w <= maxWeekday; w++) {
              headerTop += '┬' + '─' * colWidth;
              headerMid += '│ ' + days[w - 1].padRight(colWidth - 1);
              headerBot += '┼' + '─' * colWidth;
            }
            headerTop += '┐';
            headerMid += '│';
            headerBot += '┤';
  
            print(headerTop);
            print(headerMid);
            print(headerBot);
  
            for (int ora = minOra; ora <= maxOra; ora++) {
              List<List<String>> dayLines = List.generate(maxWeekday + 1, (_) => []);
              int maxLines = 1;
  
              for (int w = 1; w <= maxWeekday; w++) {
                final lessons = matrix[ora]?[w] ?? [];
                if (lessons.isNotEmpty) {
                  final entry = lessons.first;
                  String sub = AppState.instance.applyAlias(entry.subject);
                  String thm = entry.theme ?? '';
                  
                  final isCancelled = entry.isCancelled;
                  final wasAbsent = entry.wasAbsent;
                  final substitute = entry.substituteTeacher != null && entry.substituteTeacher!.isNotEmpty;
                  final isExam = exams != null && exams.any((e) =>
                      e.subject.toLowerCase() == entry.subject.toLowerCase() &&
                      e.date != null &&
                      entry.date != null &&
                      e.date!.year == entry.date!.year &&
                      e.date!.month == entry.date!.month &&
                      e.date!.day == entry.date!.day);

                  List<String> cellLines = [];
                  final subWrapped = _wrapText(sub, colWidth - 2);
                  for (var line in subWrapped) {
                    if (isCancelled) {
                      cellLines.add('\x1B[31m$line\x1B[0m');
                    } else if (substitute) {
                      cellLines.add('\x1B[36;4m$line\x1B[0m');
                    } else {
                      cellLines.add(line);
                    }
                  }

                  if (isCancelled) {
                    cellLines.add('\x1B[31m[ELMARAD]\x1B[0m');
                  }
                  if (wasAbsent) {
                    cellLines.add('\x1B[33m[HIÁNY]\x1B[0m');
                  }
                  if (isExam) {
                    cellLines.add('\x1B[35m[DOLG]\x1B[0m');
                  }
                  
                  if (thm.isNotEmpty && !isCancelled) {
                    final thmWrapped = _wrapText('($thm)', colWidth - 2);
                    cellLines.addAll(thmWrapped);
                  }
                  
                  if (cellLines.isEmpty) cellLines = [''];
                  dayLines[w] = cellLines;
                  if (cellLines.length > maxLines) maxLines = cellLines.length;
                } else {
                  dayLines[w] = [''];
                }
              }
  
              for (int lineIdx = 0; lineIdx < maxLines; lineIdx++) {
                String rowStr = (lineIdx == 0) ? '│ ${ora.toString().padLeft(2)}. │' : '│     │';
                
                for (int w = 1; w <= maxWeekday; w++) {
                  String lineText = '';
                  if (lineIdx < dayLines[w].length) {
                    lineText = dayLines[w][lineIdx];
                  }
                  rowStr += ' ' + _padRightWithAnsi(lineText, colWidth - 1) + '│';
                }
                print(rowStr);
              }
              
              if (ora < maxOra) {
                String sep = '├─────';
                for (int w = 1; w <= maxWeekday; w++) {
                  sep += '┼' + '─' * colWidth;
                }
                sep += '┤';
                print(sep);
              }
            }
  
            String footer = '└─────';
            for (int w = 1; w <= maxWeekday; w++) {
              footer += '┴' + '─' * colWidth;
            }
            footer += '┘';
            print(footer);
          }
        } else {
          print('Nem sikerült lekérdezni az órarendet.');
        }
        _pause();
      }
    }

  String _padRightWithAnsi(String text, int width) {
    final len = text.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '').length;
    if (len >= width) return text;
    return text + ' ' * (width - len);
  }

  Future<void> _exportCalendar() async {
      if (!await _ensureClientReady()) return;
      
      print('\n--- Naptár Exportálása ---');
      print('Adatok lekérése (E heti és jövő heti órarend, valamint vizsgák)...');
      
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfNextWeek = startOfWeek.add(Duration(days: 13));
      
      final timetable = await _client!.getTimetable(startOfWeek, endOfNextWeek) ?? [];
      final exams = await _client!.getExams() ?? [];
      
      if (timetable.isEmpty && exams.isEmpty) {
        print('Nincs exportálható adat (órarend és vizsgák üresek).\n');
        _pause();
        return;
      }
      final icsContent = IcsExporter.generate(timetable, exams);
      
      final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
      final desktopPath = Platform.isWindows ? '$home\\Desktop' : '$home/Desktop';
      final desktop = Directory(desktopPath);
      final outDir = desktop.existsSync() ? desktop.path : home;
      
      final sep = Platform.isWindows ? '\\' : '/';
      final file = File('$outDir${sep}folio_naptar.ics');
      await file.writeAsString(icsContent);
      
      print('Sikeres exportálás! A naptár elmentve ide: ${file.path}\n');
      _pause();
    }

}
