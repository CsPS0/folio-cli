part of '../cli_app.dart';

extension FolioCliAppGradesView on FolioCliApp {
  Future<void> _showGrades() async {
      while (true) {
        if (!await _ensureClientReady()) return;
        
        final action = Select(
          prompt: 'Jegyek',
          options: ['Legutóbbi 10 jegy', 'Összes jegy', 'Vissza'],
        ).interact();
  
        if (action == 2) return;
        _clearScreen();
        print('\n--- Jegyek lekérdezése ---');
        final grades = await _client!.getGrades();
        if (grades != null) {
          if (grades.isEmpty) {
            print('Nincsenek elérhető jegyek.');
          } else {
            grades.sort((a, b) {
              final dateA = a.date ?? DateTime(2000);
              final dateB = b.date ?? DateTime(2000);
              return dateB.compareTo(dateA);
            });
  
            final limit = action == 0 ? 10 : grades.length;
            for (var grade in grades.take(limit)) {
              final subject = grade.subject;
              final val = grade.numericValue ?? grade.textValue ?? '';
              
              String coloredVal = val.toString();
              if (grade.numericValue != null && grade.numericValue! > 0 && grade.numericValue! <= 5) {
                switch (grade.numericValue) {
                  case 1: coloredVal = '\x1B[31m$val\x1B[0m'; break;
                  case 2: coloredVal = '\x1B[38;5;208m$val\x1B[0m'; break;
                  case 3: coloredVal = '\x1B[33m$val\x1B[0m'; break;
                  case 4: coloredVal = '\x1B[92m$val\x1B[0m'; break;
                  case 5: coloredVal = '\x1B[36m$val\x1B[0m'; break;
                  default: break;
                }
              } else if (grade.numericValue != null && grade.numericValue! > 5) {
                coloredVal = '$val%';
              } else if (coloredVal.toLowerCase() == 'nem írt') {
                coloredVal = '\x1B[3;31m$val\x1B[0m';
              }

              final dateStr = grade.date?.toString().split(' ').first.split('T').first ?? '';
              print('[$dateStr] $subject: $coloredVal');
            }
          }
        } else {
          print('Nem sikerült lekérdezni a jegyeket.');
        }
        print('');
      }
    }

  Future<void> _showExams() async {
      while (true) {
        final action = Select(
          prompt: 'Számonkérések',
          options: ['Legutóbbi 10 számonkérés', 'Összes számonkérés', 'Vissza'],
        ).interact();
  
        if (action == 2) return;
        _clearScreen();
        print('\n--- Számonkérések ---');
        final exams = await _client!.getExams();
        if (exams != null) {
          if (exams.isEmpty) {
            print('Nincsenek bejelentett számonkérések.');
          } else {
            exams.sort((a, b) {
              final dateA = a.date ?? DateTime(2000);
              final dateB = b.date ?? DateTime(2000);
              return dateB.compareTo(dateA);
            });
  
            final limit = action == 0 ? 10 : exams.length;
            for (var exam in exams.take(limit)) {
              final dateStr = exam.date?.toString().split(' ').first.split('T').first ?? '';
              final subject = exam.subject;
              final type = exam.mode;
              final theme = exam.theme ?? '';
              print('[$dateStr] $subject - $type ${theme.isNotEmpty ? "($theme)" : ""}');
            }
            if (action == 0 && exams.length > 10) {
              print('  ... és még ${exams.length - 10} régebbi számonkérés.');
            }
          }
        } else {
          print('Nem sikerült lekérdezni a számonkéréseket.');
        }
        print('');
      }
    }

  Future<void> _globalSearch() async {
      if (!await _ensureClientReady()) return;
      
      _clearScreen();
      print('\n--- Globális Kereső ---');
      final query = Input(prompt: 'Keresendő kifejezés').interact().toLowerCase();
      if (query.isEmpty) return;
      
      print('Adatok lekérése a kereséshez...');
      final grades = await _client!.getGrades() ?? [];
      final hw = await _client!.getHomework() ?? [];
      final exams = await _client!.getExams() ?? [];
      
      _clearScreen();
      print('\n--- Keresési Eredmények: "$query" ---');
      
      bool foundAny = false;
      
      for (var g in grades) {
        final t = g.subject.toLowerCase();
        final d = g.date?.toString() ?? '';
        final th = g.theme?.toLowerCase() ?? '';
        if (t.contains(query) || th.contains(query)) {
          foundAny = true;
          
          final val = g.numericValue ?? g.textValue ?? '';
          String coloredVal = val.toString();
          if (g.numericValue != null && g.numericValue! > 0 && g.numericValue! <= 5) {
            switch (g.numericValue) {
              case 1: coloredVal = '\x1B[31m$val\x1B[0m'; break;
              case 2: coloredVal = '\x1B[38;5;208m$val\x1B[0m'; break;
              case 3: coloredVal = '\x1B[33m$val\x1B[0m'; break;
              case 4: coloredVal = '\x1B[92m$val\x1B[0m'; break;
              case 5: coloredVal = '\x1B[36m$val\x1B[0m'; break;
              default: break;
            }
          } else if (g.numericValue != null && g.numericValue! > 5) {
            coloredVal = '$val%';
          } else if (coloredVal.toLowerCase() == 'nem írt') {
            coloredVal = '\x1B[3;31m$val\x1B[0m';
          }
          
          print('[Jegy] ${g.subject}: $coloredVal (${d.split(' ').first}) - ${g.theme ?? ''}');
        }
      }
      
      for (var h in hw) {
        final t = h.subject.toLowerCase();
        final th = h.text.toLowerCase();
        if (t.contains(query) || th.contains(query)) {
          foundAny = true;
          print('[Házi] ${h.subject}: ${h.text}');
        }
      }
      
      for (var e in exams) {
        final t = e.subject.toLowerCase();
        final th = e.theme?.toLowerCase() ?? '';
        if (t.contains(query) || th.contains(query)) {
          foundAny = true;
          print('[Dolgozat] ${e.subject}: ${e.theme ?? ''} (${e.date?.toString().split(' ').first ?? ''})');
        }
      }
      
      if (!foundAny) {
        print('Nincs találat.');
      }
      
      print('');
      Input(prompt: 'Nyomj Enter-t a visszatéréshez...').interact();
    }

}
