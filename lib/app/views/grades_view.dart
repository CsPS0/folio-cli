part of '../cli_app.dart';

extension FolioCliAppGradesView on FolioCliApp {
  Future<void> _showGrades() async {
      while (true) {
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
              final dateA = DateTime.tryParse(a['KeszitesDatuma'] ?? '') ?? DateTime(2000);
              final dateB = DateTime.tryParse(b['KeszitesDatuma'] ?? '') ?? DateTime(2000);
              return dateB.compareTo(dateA);
            });
  
            final limit = action == 0 ? 10 : grades.length;
            for (var grade in grades.take(limit)) {
              final subject = grade['Tantargy']?['Nev'] ?? 'Ismeretlen tárgy';
              final val = grade['SzamErtek'] ?? grade['SzovegesErtek'];
              final dateStr = grade['KeszitesDatuma']?.toString().split('T').first ?? '';
              final type = grade['Tipus']?['Nev'] ?? 'Értékelés';
              print('[$dateStr] $subject: $val ($type)');
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
          options: ['Számonkérések megtekintése', 'Vissza'],
        ).interact();
  
        if (action == 1) return;
        _clearScreen();
        print('\n--- Számonkérések ---');
        final exams = await _client!.getExams();
        if (exams != null) {
          if (exams.isEmpty) {
            print('Nincsenek bejelentett számonkérések.');
          } else {
            exams.sort((a, b) {
              final dateA = DateTime.tryParse(a['Datum'] ?? '') ?? DateTime(2000);
              final dateB = DateTime.tryParse(b['Datum'] ?? '') ?? DateTime(2000);
              return dateB.compareTo(dateA);
            });
  
            for (var exam in exams.take(10)) {
              final dateStr = exam['Datum']?.toString().split('T').first ?? '';
              final subject = exam['Tantargy']?['Nev'] ?? 'Ismeretlen tárgy';
              final type = exam['Modja']?['Nev'] ?? 'Számonkérés';
              final theme = exam['Tema'] ?? '';
              print('[$dateStr] $subject - $type ${theme.isNotEmpty ? "($theme)" : ""}');
            }
            if (exams.length > 10) {
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
        final t = g['Tantargy']?['Nev']?.toString().toLowerCase() ?? '';
        final d = g['KeszitesDatuma']?.toString() ?? '';
        final th = g['Tema']?.toString().toLowerCase() ?? '';
        if (t.contains(query) || th.contains(query)) {
          foundAny = true;
          print('[Jegy] ${g['Tantargy']?['Nev']}: ${g['Ertek']} (${d.split('T').first}) - ${g['Tema'] ?? ''}');
        }
      }
      
      for (var h in hw) {
        final t = h['Tantargy']?['Nev']?.toString().toLowerCase() ?? '';
        final th = h['Szoveg']?.toString().toLowerCase() ?? '';
        if (t.contains(query) || th.contains(query)) {
          foundAny = true;
          print('[Házi] ${h['Tantargy']?['Nev']}: ${h['Szoveg']?.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('\n', ' ')}');
        }
      }
      
      for (var e in exams) {
        final t = e['Tantargy']?['Nev']?.toString().toLowerCase() ?? '';
        final th = e['Temaja']?.toString().toLowerCase() ?? '';
        if (t.contains(query) || th.contains(query)) {
          foundAny = true;
          print('[Dolgozat] ${e['Tantargy']?['Nev']}: $th (${e['Datum']?.toString().split('T').first})');
        }
      }
      
      if (!foundAny) {
        print('Nincs találat.');
      }
      
      print('');
      Input(prompt: 'Nyomj Enter-t a visszatéréshez...').interact();
    }

}
