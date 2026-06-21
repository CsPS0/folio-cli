part of '../cli_app.dart';

extension FolioCliAppDashboardView on FolioCliApp {
  Future<void> _showDashboard() async {
    if (!await _ensureClientReady()) return;

    stdout.write('\x1B[2J\x1B[H');
    stdout.write('\x1B[?25l');

    print('Adatok betöltése a Dashboard-hoz...');
    
    final now = DateTime.now();
    final gradesFuture = _client!.getGrades();
    final timetableFuture = _client!.getTimetable(
      DateTime(now.year, now.month, now.day), 
      DateTime(now.year, now.month, now.day).add(Duration(days: 1))
    );
    final averagesFuture = _client!.getAverages();
    final absencesFuture = _client!.getAbsences();
    final examsFuture = _client!.getExams();
    final homeworkFuture = _client!.getHomework();
    final studentFuture = _client!.getStudentData(silent: true);

    final results = await Future.wait([gradesFuture, timetableFuture, averagesFuture, absencesFuture, examsFuture, homeworkFuture, studentFuture]);
    final grades = results[0] as List<Grade>? ?? [];
    final timetable = results[1] as List<TimetableEntry>? ?? [];
    final averages = (results[2] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
    final absences = results[3] as List<Absence>? ?? [];
    final exams = results[4] as List<Exam>? ?? [];
    final homeworks = results[5] as List<Homework>? ?? [];
    final student = results[6] as Student?;

    final todayLessons = timetable.where((l) {
      if (l.date == null) return false;
      return l.date!.year == now.year && l.date!.month == now.month && l.date!.day == now.day;
    }).toList();
    todayLessons.sort((a, b) => (a.lessonNumber).compareTo(b.lessonNumber));

    grades.sort((a, b) {
      final dateA = a.date ?? DateTime(2000);
      final dateB = b.date ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    stdout.write('\x1B[2J\x1B[H');
    
    bool running = true;
    
    try {
      if (stdin.hasTerminal) {
        stdin.echoMode = false;
        stdin.lineMode = false;
      }
    } catch (e) {
      FolioLogger.debug('Failed to set terminal raw mode: $e');
    }

    final subscription = stdin.listen((List<int> bytes) {
      for (var byte in bytes) {
        if (byte == 113 || byte == 81 || byte == 27 || byte == 3) {
          running = false;
        }
      }
    });

    while (running) {
      stdout.write('\x1B[H');
      final width = stdout.hasTerminal ? stdout.terminalColumns : 80;
      final halfWidth = (width / 2).floor() - 2;

      // Header
      print('\x1B[1;36mFolio Élő Dashboard\x1B[0m - Frissítve: ${DateTime.now().toString().split('.')[0]}');
      print('Nyomj \x1B[33mq\x1B[0m-t a kilépéshez a főmenübe.\n');

      // Countdown Widget
      String countdownWidget = '';
      final nowTime = DateTime.now();
      
      if (todayLessons.isNotEmpty) {
        todayLessons.sort((a, b) => (a.startTime ?? DateTime(2000)).compareTo(b.startTime ?? DateTime(2000)));
        
        TimetableEntry? currentLesson;
        TimetableEntry? nextLesson;
        
        for (var lesson in todayLessons) {
          if (lesson.startTime != null && lesson.endTime != null) {
            if (nowTime.isAfter(lesson.startTime!) && nowTime.isBefore(lesson.endTime!)) {
              currentLesson = lesson;
              break;
            }
          }
        }
        
        if (currentLesson != null) {
          final diff = currentLesson.endTime!.difference(nowTime).inMinutes;
          final sub = AppState.instance.applyAlias(currentLesson.subject);
          countdownWidget = '⏳ \x1B[1;33m$sub órából hátra van: $diff perc\x1B[0m';
        } else {
          for (var lesson in todayLessons) {
            if (lesson.startTime != null && lesson.startTime!.isAfter(nowTime)) {
              nextLesson = lesson;
              break;
            }
          }
          if (nextLesson != null) {
            final diff = nextLesson.startTime!.difference(nowTime).inMinutes;
            final sub = AppState.instance.applyAlias(nextLesson.subject);
            countdownWidget = '⏱️ \x1B[1;36mKövetkező óra ($sub) kezdődik: $diff perc múlva\x1B[0m';
          } else {
            countdownWidget = '🎉 \x1B[1;32mA mai óráid véget értek! Szép estét!\x1B[0m';
          }
        }
      } else {
        countdownWidget = '🏖️ \x1B[1;32mMa nincsenek tanítási óráid!\x1B[0m';
      }
      print('$countdownWidget\n');

      // Maintenance Widget
      if (student?.nextDowntime != null) {
        print('\x1B[33m⚠️ Tervezett leállás: ${student!.nextDowntime!.toLocal()}\x1B[0m\n');
      }

      final leftLines = <String>[];
      final rightLines = <String>[];

      leftLines.add('\x1B[1;32m--- Mai Órarend ---\x1B[0m');
      if (todayLessons.isEmpty) {
        leftLines.add('Nincs több órád mára! 🎉');
      } else {
        for (var lesson in todayLessons) {
          final isPast = lesson.endTime != null && lesson.endTime!.isBefore(DateTime.now());
          final color = isPast ? '\x1B[90m' : '\x1B[0m';
          final title = AppState.instance.applyAlias(lesson.subject);
          final num = lesson.lessonNumber.toString();
          final start = lesson.startTime != null ? '${lesson.startTime!.hour.toString().padLeft(2, '0')}:${lesson.startTime!.minute.toString().padLeft(2, '0')}' : '';
          leftLines.add('$color$num. óra ($start): $title\x1B[0m');
        }
      }

      leftLines.add('');
      leftLines.add('\x1B[1;36m--- Közelgő Számonkérések ---\x1B[0m');
      final upcomingExams = exams.where((e) => e.date != null && e.date!.isAfter(DateTime.now().subtract(Duration(days: 1)))).toList();
      upcomingExams.sort((a, b) => a.date!.compareTo(b.date!));
      if (upcomingExams.isEmpty) {
        leftLines.add('Nincsenek bejelentett számonkérések.');
      } else {
        for (var exam in upcomingExams.take(3)) {
          final dateStr = exam.date!.toString().split(' ').first.split('T').first;
          final title = AppState.instance.applyAlias(exam.subject);
          leftLines.add('[$dateStr] $title');
        }
      }

      leftLines.add('');
      leftLines.add('\x1B[1;34m--- Aktuális Házi Feladatok ---\x1B[0m');
      final upcomingHw = homeworks.where((h) => h.deadline != null && h.deadline!.isAfter(DateTime.now().subtract(Duration(days: 1)))).toList();
      upcomingHw.sort((a, b) => a.deadline!.compareTo(b.deadline!));
      if (upcomingHw.isEmpty) {
        leftLines.add('Nincs aktuális házi feladat.');
      } else {
        for (var hw in upcomingHw.take(3)) {
          final dateStr = hw.deadline!.toString().split(' ').first.split('T').first;
          final title = AppState.instance.applyAlias(hw.subject);
          leftLines.add('[$dateStr] $title');
        }
      }

      rightLines.add('\x1B[1;33m--- Legutóbbi Jegyek ---\x1B[0m');
      if (grades.isEmpty) {
        rightLines.add('Nincsenek jegyek.');
      } else {
        for (var grade in grades.take(5)) {
          final subj = AppState.instance.applyAlias(grade.subject);
          final val = grade.numericValue?.toString() ?? grade.textValue ?? '?';
          
          String c = '\x1B[0m';
          if (grade.numericValue != null) {
            if (grade.numericValue! == 1) c = '\x1B[31m';
            else if (grade.numericValue! == 2) c = '\x1B[38;5;208m';
            else if (grade.numericValue! == 3) c = '\x1B[33m';
            else if (grade.numericValue! == 4) c = '\x1B[92m';
            else if (grade.numericValue! == 5) c = '\x1B[94m';
          }
          rightLines.add('$subj: $c$val\x1B[0m');
        }
      }

      rightLines.add('');
      rightLines.add('\x1B[1;35m--- Tantárgyi Átlagok ---\x1B[0m');
      if (averages.isEmpty) {
        rightLines.add('Nincsenek átlagok.');
      } else {
        double bestAvg = 0;
        String bestSubj = '';
        double worstAvg = 5.0;
        String worstSubj = '';
        for (var a in averages) {
          final valueStr = a['Ertek']?.toString() ?? '0';
          final val = double.tryParse(valueStr.replaceAll(',', '.')) ?? 0.0;
          final subj = a['Tantargy']?['Nev']?.toString() ?? '';
          if (val > 0) {
            if (val > bestAvg) { bestAvg = val; bestSubj = subj; }
            if (val < worstAvg) { worstAvg = val; worstSubj = subj; }
          }
        }
        if (bestAvg > 0) {
          rightLines.add('Legjobb: ${AppState.instance.applyAlias(bestSubj)} (${FolioTheme.primary}${bestAvg.toStringAsFixed(2)}${FolioTheme.reset})');
          rightLines.add('Legrosszabb: ${AppState.instance.applyAlias(worstSubj)} (\x1B[31m${worstAvg.toStringAsFixed(2)}\x1B[0m)');
        }
      }

      rightLines.add('');
      rightLines.add('\x1B[1;31m--- Mulasztások ---\x1B[0m');
      if (absences.isEmpty) {
        rightLines.add('Tiszta a lapod, nincs mulasztás!');
      } else {
        int totalHours = absences.where((a) => a.type?.toLowerCase() != 'késés').length;
        int unexcused = absences.where((a) => a.status.toLowerCase() == 'igazolatlan').length;
        
        String totalColor = '\x1B[0m';
        if (totalHours > 200) totalColor = '\x1B[1;31m';
        else if (totalHours > 100) totalColor = '\x1B[33m';
        
        rightLines.add('Összes hiányzás: $totalColor$totalHours óra\x1B[0m');
        if (unexcused > 0) {
          rightLines.add('Igazolatlan: \x1B[31m$unexcused óra\x1B[0m');
        }
        
        final Map<String, int> missedBySubject = {};
        for (var a in absences) {
          if (a.type?.toLowerCase() != 'késés' && a.subject.isNotEmpty) {
            missedBySubject[a.subject] = (missedBySubject[a.subject] ?? 0) + 1;
          }
        }
        if (missedBySubject.isNotEmpty) {
          final sortedMissed = missedBySubject.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          final topMissed = sortedMissed.first;
          rightLines.add('Legtöbbet hiányzott: ${AppState.instance.applyAlias(topMissed.key)} (${topMissed.value} óra)');
        }
      }

      final maxLines = leftLines.length > rightLines.length ? leftLines.length : rightLines.length;
      for (int i = 0; i < maxLines; i++) {
        final leftStr = i < leftLines.length ? leftLines[i] : '';
        final rightStr = i < rightLines.length ? rightLines[i] : '';
        
        final leftLen = leftStr.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '').length;
        
        final padding = halfWidth - leftLen;
        final padStr = padding > 0 ? ' ' * padding : ' ';
        
        print('$leftStr$padStr│ $rightStr');
      }

      for (int i = 0; i < 300 && running; i++) {
        await Future.delayed(Duration(milliseconds: 100));
      }
    }

    await subscription.cancel();

    try {
      if (stdin.hasTerminal) {
        stdin.echoMode = true;
        stdin.lineMode = true;
      }
    } catch (e) {
      FolioLogger.debug('Failed to restore terminal mode: $e');
    }
    stdout.write('\x1B[?25h');
    stdout.write('\x1B[2J\x1B[H');
  }
}
