part of '../cli_app.dart';

extension FolioCliAppTimetableView on FolioCliApp {
  Future<void> _showTimetable() async {
      while (true) {
        final action = Select(
          prompt: 'Órarend',
          options: ['Ezen a héten', 'Következő héten', 'Vissza'],
        ).interact();
  
        if (action == 2) return;
        _clearScreen();
        print('\n--- Órarend ---');
        final now = DateTime.now();
        final offsetDays = action == 1 ? 7 : 0;
        final targetDate = now.add(Duration(days: offsetDays));
        final startOfWeek = targetDate.subtract(Duration(days: targetDate.weekday - 1));
        final endOfWeek = startOfWeek.add(Duration(days: 4));
  
        final timetable = await _client!.getTimetable(startOfWeek, endOfWeek);
        if (timetable != null) {
          if (timetable.isEmpty) {
            print('Nincsenek órák rögzítve erre a hétre.');
          } else {
            int minOra = 99;
            int maxOra = -1;
            int maxWeekday = 5;
  
            Map<int, Map<int, List<Map<String, dynamic>>>> matrix = {};
  
            for (var lesson in timetable) {
              final dateStr = lesson['Datum']?.toString().split('T').first ?? '';
              final dateObj = DateTime.tryParse(dateStr);
              if (dateObj == null) continue;
  
              final weekday = dateObj.weekday;
              if (weekday > maxWeekday) maxWeekday = weekday;
              if (weekday > 7) continue;
  
              final ora = _parseLessonNumber(lesson['Oraszam']);
              if (ora == 99) continue;
  
              if (ora < minOra) minOra = ora;
              if (ora > maxOra) maxOra = ora;
  
              matrix.putIfAbsent(ora, () => {});
              matrix[ora]!.putIfAbsent(weekday, () => []);
              // Cast the dynamic map to Map<String, dynamic>
              matrix[ora]![weekday]!.add(Map<String, dynamic>.from(lesson));
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
                  final lesson = lessons.first;
                  String sub = lesson['Tantargy']?['Nev'] ?? '';
                  String thm = lesson['Tema'] ?? '';
                  
                  List<String> cellLines = [];
                  if (sub.isNotEmpty) {
                    cellLines.addAll(_wrapText(sub, colWidth - 2));
                  }
                  if (thm.isNotEmpty) {
                    cellLines.addAll(_wrapText('($thm)', colWidth - 2));
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
                  rowStr += ' ' + lineText.padRight(colWidth - 1) + '│';
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
        print('');
      }
    }

  Future<void> _exportCalendar() async {
      print('\n--- Naptár Exportálása ---');
      print('Adatok lekérése (E heti és jövő heti órarend, valamint vizsgák)...');
      
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfNextWeek = startOfWeek.add(Duration(days: 13));
      
      final timetable = await _client!.getTimetable(startOfWeek, endOfNextWeek) ?? [];
      final exams = await _client!.getExams() ?? [];
      
      if (timetable.isEmpty && exams.isEmpty) {
        print('Nincs exportálható adat (órarend és vizsgák üresek).\n');
        return;
      }
      final icsContent = IcsExporter.generate(timetable, exams);
      
      final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
      final desktop = Directory('$home\\Desktop');
      final outDir = desktop.existsSync() ? desktop.path : home;
      
      final file = File('$outDir\\folio_naptar.ics');
      await file.writeAsString(icsContent);
      
      print('Sikeres exportálás! A naptár elmentve ide: ${file.path}\n');
    }

}
