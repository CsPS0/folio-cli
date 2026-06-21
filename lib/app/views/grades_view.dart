part of '../cli_app.dart';

extension FolioCliAppGradesView on FolioCliApp {
  Future<void> _showGrades() async {
      while (true) {
        if (!await _ensureClientReady()) return;
        _clearScreen();
        _showMainMenuBanner();
        
        final action = Select(
          prompt: 'Jegyek',
          options: ['Legutóbbi 10 jegy', 'Összes jegy', 'Jegy-trendek (Heatmap)', 'Szellem Jegyek (Ghost Grades)', 'Vissza'],
        ).interact();
  
        if (action == 4) return;
        _clearScreen();

        if (action == 3) {
          print('\n--- 👻 Szellem Jegyek (Ghost Grades) 👻 ---');
          print('Adatok lekérése...');
          final grades = await _client!.getGrades();
          if (grades == null || grades.isEmpty) {
            print('Nincsenek elérhető jegyek a számításhoz.');
            _pause();
            continue;
          }

          final validGrades = grades.where((g) => g.numericValue != null && g.numericValue! >= 1 && g.numericValue! <= 5 && !g.isSummaryGrade).toList();
          if (validGrades.isEmpty) {
            print('Nincsenek érdemi (1-5) jegyek a számításhoz.');
            _pause();
            continue;
          }

          final subjects = validGrades.map((g) => g.subject).toSet().toList()..sort();
          subjects.add('Vissza');

          final subjChoice = Select(
            prompt: 'Válassz tantárgyat:',
            options: subjects,
          ).interact();

          if (subjChoice == subjects.length - 1) continue;

          final targetSubject = subjects[subjChoice];
          final subjectGrades = validGrades.where((g) => g.subject == targetSubject).toList();

          if (subjectGrades.isEmpty) {
            print('Ebből a tantárgyból még nincs jegyed.');
            _pause();
            continue;
          }

          double currentWeightedSum = 0.0;
          double currentWeightSum = 0.0;
          for (var g in subjectGrades) {
            double w = g.weight;
            if (w == 0) w = 100.0;
            currentWeightedSum += g.numericValue! * w;
            currentWeightSum += w;
          }
          final currentAvg = currentWeightedSum / currentWeightSum;

          print('\nTantárgy: \x1B[1;36m$targetSubject\x1B[0m');
          print('Jelenlegi jegyeid száma: ${subjectGrades.length}');
          print('Jelenlegi átlagod: \x1B[1;33m${currentAvg.toStringAsFixed(2)}\x1B[0m');

          final inputGradesStr = Utf8Input(
            prompt: '\nÍrd be a szellem jegyeket szóközökkel elválasztva (pl. "5 5 4"):', 
          ).interact().trim();

          if (inputGradesStr.isEmpty) {
            print('Nem adtál meg jegyeket.');
            _pause();
            continue;
          }

          final parts = inputGradesStr.split(RegExp(r'\s+'));
          final List<double> newGrades = [];
          for (var part in parts) {
            final val = double.tryParse(part);
            if (val != null && val >= 1 && val <= 5) {
              newGrades.add(val);
            }
          }

          if (newGrades.isEmpty) {
            print('Érvénytelen jegyek! Csak 1 és 5 közötti számokat adhatsz meg.');
            _pause();
            continue;
          }

          final inputWeightStr = Utf8Input(
            prompt: 'Írd be a jegyek súlyát %-ban (pl. 100, 200, 50) [alap: 100]:',
          ).interact().trim();
          double newWeight = 100.0;
          if (inputWeightStr.isNotEmpty) {
            newWeight = double.tryParse(inputWeightStr) ?? 100.0;
          }

          double hypotheticalSum = currentWeightedSum;
          double hypotheticalWeightSum = currentWeightSum;
          for (var g in newGrades) {
            hypotheticalSum += g * newWeight;
            hypotheticalWeightSum += newWeight;
          }
          final newAvg = hypotheticalSum / hypotheticalWeightSum;
          final diff = newAvg - currentAvg;
          final diffSign = diff >= 0 ? '+' : '';
          final diffColor = diff >= 0 ? '\x1B[92m' : '\x1B[31m';

          print('\n----------------------------------------');
          print('Új szellem jegyek: ${newGrades.map((g) => g.toInt()).join(", ")} (súly: ${newWeight.toInt()}%)');
          print('Jelenlegi átlag: \x1B[1;36m${currentAvg.toStringAsFixed(2)}\x1B[0m');
          print('Új várható átlag: \x1B[1;36m${newAvg.toStringAsFixed(2)}\x1B[0m');
          print('Változás: $diffColor$diffSign${diff.toStringAsFixed(2)}\x1B[0m');
          print('----------------------------------------');

          _pause();
          continue;
        }

        print('\n--- Jegyek lekérdezése ---');
        final grades = await _client!.getGrades();
        if (grades != null) {
          if (grades.isEmpty) {
            print('Nincsenek elérhető jegyek.');
          } else {
            if (action == 2) {
              final dailyAverages = <DateTime, double>{};
              final dailySums = <DateTime, double>{};
              final dailyCounts = <DateTime, int>{};
              
              for (var g in grades) {
                if (g.date != null && g.numericValue != null && g.numericValue! >= 1 && g.numericValue! <= 5) {
                  final day = DateTime(g.date!.year, g.date!.month, g.date!.day);
                  dailySums[day] = (dailySums[day] ?? 0.0) + g.numericValue!;
                  dailyCounts[day] = (dailyCounts[day] ?? 0) + 1;
                }
              }
              
              for (var day in dailySums.keys) {
                dailyAverages[day] = dailySums[day]! / dailyCounts[day]!;
              }

              print('\n--- Jegy-trendek (Heti Heatmap) ---');
              print('A napi átlagodat vizualizáljuk az elmúlt hetekben.\n');
              print(ChartGenerator.generateHeatmap(dailyAverages));
              _pause();
              continue;
            }

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
                  case 5: coloredVal = '\x1B[94m$val\x1B[0m'; break;
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
        _pause();
      }
    }

  Future<void> _showExams() async {
      while (true) {
        _clearScreen();
        _showMainMenuBanner();
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
        _pause();
      }
    }

  Future<void> _globalSearch() async {
    if (!await _ensureClientReady()) return;
    
    _clearScreen();
    _showMainMenuBanner();
    print('\n--- Globális Kereső ---');
    final query = Utf8Input(prompt: 'Keresendő kifejezés (pl. tárgy, tanár, téma, hiányzás)').interact().trim();
    if (query.isEmpty) return;
    
    _clearScreen();
    _showMainMenuBanner();
    print('Keresés a Kréta adatbázisban a(z) "$query" kifejezésre...');
    
    final now = DateTime.now();
    final startTimetable = now.subtract(Duration(days: 14));
    final endTimetable = now.add(Duration(days: 14));
    
    final results = await Future.wait([
      _client!.getGrades(),
      _client!.getHomework(),
      _client!.getExams(),
      _client!.getMessages(),
      _client!.getAbsences(),
      _client!.getTimetable(startTimetable, endTimetable),
    ]);
    
    final grades = results[0] as List<Grade>? ?? [];
    final hw = results[1] as List<Homework>? ?? [];
    final exams = results[2] as List<Exam>? ?? [];
    final messages = results[3] as List<Message>? ?? [];
    final absences = results[4] as List<Absence>? ?? [];
    final timetable = results[5] as List<TimetableEntry>? ?? [];
    
    final queryClean = _removeAccents(query);
    final resultsList = <Map<String, dynamic>>[];
    
    for (var g in grades) {
      if (_matches(g.subject, queryClean) || _matches(g.theme, queryClean) || _matches(g.teacherName, queryClean) || _matches(g.textValue, queryClean)) {
        final dateStr = g.date?.toString().split(' ').first ?? '';
        resultsList.add({
          'label': '[Jegy] ${AppState.instance.applyAlias(g.subject)}: ${g.numericValue ?? g.textValue} ($dateStr)',
          'type': 'grade',
          'data': g,
        });
      }
    }
    
    for (var h in hw) {
      if (_matches(h.subject, queryClean) || _matches(h.text, queryClean)) {
        final dateStr = h.deadline?.toString().split(' ').first ?? '';
        final shortText = h.text.length > 40 ? '${h.text.substring(0, 37)}...' : h.text;
        resultsList.add({
          'label': '[Házi] ${AppState.instance.applyAlias(h.subject)}: $shortText ($dateStr)',
          'type': 'homework',
          'data': h,
        });
      }
    }
    
    for (var e in exams) {
      if (_matches(e.subject, queryClean) || _matches(e.theme, queryClean) || _matches(e.mode, queryClean)) {
        final dateStr = e.date?.toString().split(' ').first ?? '';
        resultsList.add({
          'label': '[Dolgozat] ${AppState.instance.applyAlias(e.subject)}: ${e.theme ?? ""} ($dateStr)',
          'type': 'exam',
          'data': e,
        });
      }
    }
    
    for (var m in messages) {
      if (_matches(m.subject, queryClean) || _matches(m.senderName, queryClean) || _matches(m.text, queryClean)) {
        final dateStr = m.sentDate?.toString().split(' ').first ?? '';
        resultsList.add({
          'label': '[Üzenet] ${m.senderName}: ${m.subject} ($dateStr)',
          'type': 'message',
          'data': m,
        });
      }
    }
    
    for (var a in absences) {
      if (_matches(a.subject, queryClean) || _matches(a.status, queryClean) || _matches(a.type, queryClean)) {
        final dateStr = a.date?.toString().split(' ').first ?? '';
        resultsList.add({
          'label': '[Mulasztás] ${AppState.instance.applyAlias(a.subject)}: ${a.type ?? a.status} ($dateStr)',
          'type': 'absence',
          'data': a,
        });
      }
    }
    
    for (var t in timetable) {
      if (_matches(t.subject, queryClean) || _matches(t.teacher, queryClean) || _matches(t.room, queryClean) || _matches(t.theme, queryClean)) {
        final dateStr = t.date?.toString().split(' ').first ?? '';
        resultsList.add({
          'label': '[Óra] ${AppState.instance.applyAlias(t.subject)}: ${t.lessonNumber}. óra ($dateStr, Terem: ${t.room ?? "-"})',
          'type': 'timetable',
          'data': t,
        });
      }
    }
    
    if (resultsList.isEmpty) {
      _clearScreen();
      _showMainMenuBanner();
      print('\n--- Keresési Eredmények ---');
      print('Nincs találat a(z) "$query" kifejezésre.\n');
      _pause();
      return;
    }
    
    final optionLabels = resultsList.map((r) => r['label'] as String).toList();
    
    while (true) {
      _clearScreen();
      _showMainMenuBanner();
      print('\n--- Keresési Eredmények: "$query" ---');
      print('Találatok száma: ${resultsList.length} db. Válassz egyet a részletekért:\n');
      
      final choice = PaginatedMenu(
        prompt: 'Találatok',
        allOptions: optionLabels,
        pageSize: 15,
      ).interact();
      
      if (choice == -1) {
        break;
      }
      
      final item = resultsList[choice];
      final type = item['type'] as String;
      final data = item['data'];
      
      if (type == 'grade') {
        _showGradeDetails(data as Grade);
      } else if (type == 'homework') {
        _showHomeworkDetails(data as Homework);
      } else if (type == 'exam') {
        _showExamDetails(data as Exam);
      } else if (type == 'message') {
        await _showMessageDetails(data as Message);
      } else if (type == 'absence') {
        _showAbsenceDetails(data as Absence);
      } else if (type == 'timetable') {
        _showTimetableDetails(data as TimetableEntry);
      }
      
      _pause('Nyomj Enter-t a visszatéréshez a találatokhoz...');
    }
  }

  String _removeAccents(String input) {
    const withAccents = 'áéíóöőúüűÁÉÍÓÖŐÚÜŰ';
    const withoutAccents = 'aeiooouuuAEIOOOUUU';
    String result = input;
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result.toLowerCase();
  }

  bool _matches(String? text, String queryClean) {
    if (text == null) return false;
    return _removeAccents(text).contains(queryClean);
  }

  void _showGradeDetails(Grade g) {
    _clearScreen();
    _showMainMenuBanner();
    print('\n\x1B[1;36m=== Jegy Részletei ===\x1B[0m\n');
    print('Tantárgy:      ${AppState.instance.applyAlias(g.subject)}');
    print('Érték:         \x1B[1m${g.numericValue ?? g.textValue}\x1B[0m');
    print('Súly:          ${g.weight}%');
    print('Típus:         ${g.type}');
    print('Dátum:         ${g.date?.toString().split(' ').first ?? "-"}');
    print('Tanár:         ${g.teacherName}');
    print('Téma:          ${g.theme ?? "-"}');
  }

  void _showHomeworkDetails(Homework h) {
    _clearScreen();
    _showMainMenuBanner();
    print('\n\x1B[1;36m=== Házi Feladat Részletei ===\x1B[0m\n');
    print('Tantárgy:      ${AppState.instance.applyAlias(h.subject)}');
    print('Feladás kelte: ${h.assignedDate?.toString().split(' ').first ?? "-"}');
    print('Határidő:      \x1B[1;33m${h.deadline?.toString().split(' ').first ?? "-"}\x1B[0m');
    print('\nLeírás:');
    print('\x1B[1m${h.text}\x1B[0m');
  }

  void _showExamDetails(Exam e) {
    _clearScreen();
    _showMainMenuBanner();
    print('\n\x1B[1;36m=== Számonkérés Részletei ===\x1B[0m\n');
    print('Tantárgy:      ${AppState.instance.applyAlias(e.subject)}');
    print('Mód / Típus:   ${e.mode}');
    print('Dátum:         ${e.date?.toString().split(' ').first ?? "-"}');
    print('\nTéma / Leírás:');
    print('\x1B[1m${e.theme ?? "-"}\x1B[0m');
  }

  Future<void> _showMessageDetails(Message m) async {
    _clearScreen();
    _showMainMenuBanner();
    print('\n\x1B[1;36m=== Üzenet Részletei ===\x1B[0m\n');
    print('Feladó:        \x1B[1m${m.senderName}\x1B[0m');
    print('Dátum:         ${m.sentDate?.toString().substring(0, 16) ?? "-"}');
    print('Tárgy:         \x1B[1;33m${m.subject}\x1B[0m');
    print('----------------------------------------');
    
    String fullText = m.text;
    if (m.id != 0 && (fullText.isEmpty || fullText == m.subject)) {
      print('Üzenet letöltése...');
      try {
        final fetched = await _client!.getMessageContent(m.id);
        if (fetched != null && fetched.isNotEmpty) {
          fullText = fetched;
        }
      } catch (e) {
        FolioLogger.debug('Failed to fetch message body: $e');
      }
      _clearScreen();
      _showMainMenuBanner();
      print('\n\x1B[1;36m=== Üzenet Részletei ===\x1B[0m\n');
      print('Feladó:        \x1B[1m${m.senderName}\x1B[0m');
      print('Dátum:         ${m.sentDate?.toString().substring(0, 16) ?? "-"}');
      print('Tárgy:         \x1B[1;33m${m.subject}\x1B[0m');
      print('----------------------------------------');
    }
    
    final cleanText = fullText.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    print('Szöveg:\n$cleanText');
  }

  void _showAbsenceDetails(Absence a) {
    _clearScreen();
    _showMainMenuBanner();
    print('\n\x1B[1;36m=== Mulasztás Részletei ===\x1B[0m\n');
    print('Tantárgy:      ${AppState.instance.applyAlias(a.subject)}');
    print('Dátum:         ${a.date?.toString().split(' ').first ?? "-"}');
    print('Típus:         ${a.type ?? "-"}');
    print('Státusz:       \x1B[1m${a.status}\x1B[0m');
    if (a.delayMinutes != null && a.delayMinutes! > 0) {
      print('Késés ideje:   ${a.delayMinutes} perc');
    }
  }

  void _showTimetableDetails(TimetableEntry t) {
    _clearScreen();
    _showMainMenuBanner();
    print('\n\x1B[1;36m=== Órarendi Óra Részletei ===\x1B[0m\n');
    print('Tantárgy:      ${AppState.instance.applyAlias(t.subject)}');
    print('Dátum:         ${t.date?.toString().split(' ').first ?? "-"}');
    print('Óraszám:       ${t.lessonNumber}. óra');
    print('Időpont:       ${t.startTime?.toString().substring(11, 16) ?? ""} - ${t.endTime?.toString().substring(11, 16) ?? ""}');
    print('Terem:         ${t.room ?? "-"}');
    print('Tanár:         ${t.teacher}');
    if (t.substituteTeacher != null && t.substituteTeacher!.isNotEmpty) {
      print('Helyettesítő:  \x1B[36m${t.substituteTeacher}\x1B[0m');
    }
    print('Téma:          ${t.theme ?? "-"}');
  }

}
