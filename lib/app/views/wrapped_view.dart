part of '../cli_app.dart';

extension FolioCliAppWrappedView on FolioCliApp {
  Future<void> _showFolioWrapped() async {
    if (!await _ensureClientReady()) return;

    _clearScreen();
    print('${FolioTheme.primaryBold}Adatok kinyerése a Folio Wrapped-hez...${FolioTheme.reset}');

    final gradesFuture = _client!.getGrades();
    final averagesFuture = _client!.getAverages();
    final absencesFuture = _client!.getAbsences();
    final homeworkFuture = _client!.getHomework();
    final examsFuture = _client!.getExams();
    final messagesFuture = _client!.getMessages();

    final results = await Future.wait([gradesFuture, averagesFuture, absencesFuture, homeworkFuture, examsFuture, messagesFuture]);
    final List<Grade> grades = results[0] as List<Grade>? ?? [];
    final List<dynamic> averages = results[1] ?? [];
    final List<Absence> absences = results[2] as List<Absence>? ?? [];
    final List<Homework> homeworks = results[3] as List<Homework>? ?? [];
    final List<Exam> exams = results[4] as List<Exam>? ?? [];
    final List<Message> messages = results[5] as List<Message>? ?? [];

    if (grades.isEmpty) {
      print('Sajnos nincsenek adataid az összefoglalóhoz.');
      _pause();
      return;
    }

    // Calc Stats
    int totalGrades = grades.length;
    int total5s = grades.where((g) => g.numericValue == 5).length;
    int total1s = grades.where((g) => g.numericValue == 1).length;

    // Best/Worst Month
    final Map<int, int> gradesByMonth = {};
    final Map<int, int> fivesByMonth = {};
    for (var grade in grades) {
      if (grade.date != null) {
        final m = grade.date!.month;
        gradesByMonth[m] = (gradesByMonth[m] ?? 0) + 1;
        if (grade.numericValue == 5) {
          fivesByMonth[m] = (fivesByMonth[m] ?? 0) + 1;
        }
      }
    }

    int bestMonth = -1;
    int bestMonthFives = -1;
    for (var m in fivesByMonth.entries) {
      if (m.value > bestMonthFives) {
        bestMonthFives = m.value;
        bestMonth = m.key;
      }
    }

    // Most active day (most grades)
    final Map<String, int> gradesByDay = {};
    for (var grade in grades) {
      if (grade.date != null) {
        final d = grade.date!.toString().split(' ')[0];
        gradesByDay[d] = (gradesByDay[d] ?? 0) + 1;
      }
    }
    String mostActiveDay = "";
    int mostActiveCount = -1;
    for (var d in gradesByDay.entries) {
      if (d.value > mostActiveCount) {
        mostActiveCount = d.value;
        mostActiveDay = d.key;
      }
    }

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

    // Absences
    int totalHours = absences.where((a) => a.type?.toLowerCase() != 'késés').length;
    final Map<String, int> missedBySubject = {};
    for (var a in absences) {
      if (a.type?.toLowerCase() != 'késés' && a.subject.isNotEmpty) {
        missedBySubject[a.subject] = (missedBySubject[a.subject] ?? 0) + 1;
      }
    }
    String topMissed = "";
    int topMissedCount = 0;
    if (missedBySubject.isNotEmpty) {
      final sortedMissed = missedBySubject.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topMissed = sortedMissed.first.key;
      topMissedCount = sortedMissed.first.value;
    }

    // New Stats: Total Average
    double totalSum = 0;
    int totalSubj = 0;
    for (var a in averages) {
      final valueStr = a['Ertek']?.toString() ?? '0';
      final val = double.tryParse(valueStr.replaceAll(',', '.')) ?? 0.0;
      if (val > 0) {
        totalSum += val;
        totalSubj++;
      }
    }
    double overallAvg = totalSubj > 0 ? totalSum / totalSubj : 0.0;

    // Grades Distribution
    final List<int> gradesDist = [0, 0, 0, 0, 0];
    for (var g in grades) {
      if (g.numericValue != null && g.numericValue! >= 1 && g.numericValue! <= 5) {
        gradesDist[g.numericValue!.toInt() - 1]++;
      }
    }

    // Month with most exams
    final Map<int, int> examsByMonth = {};
    for (var exam in exams) {
      if (exam.date != null) {
        examsByMonth[exam.date!.month] = (examsByMonth[exam.date!.month] ?? 0) + 1;
      }
    }
    int worstExamMonth = -1;
    int maxExams = 0;
    for (var m in examsByMonth.entries) {
      if (m.value > maxExams) {
        maxExams = m.value;
        worstExamMonth = m.key;
      }
    }

    // 1. Tanári rangsor (Most grades)
    final Map<String, int> gradesByTeacher = {};
    for (var g in grades) {
      if (g.teacherName != null && g.teacherName!.isNotEmpty) {
        gradesByTeacher[g.teacherName!] = (gradesByTeacher[g.teacherName!] ?? 0) + 1;
      }
    }
    String topTeacher = '';
    int topTeacherCount = 0;
    if (gradesByTeacher.isNotEmpty) {
      final sortedTeachers = gradesByTeacher.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topTeacher = sortedTeachers.first.key;
      topTeacherCount = sortedTeachers.first.value;
    }

    // 2. Legszorgalmasabb nap (Most 5s)
    final Map<int, int> fivesByWeekday = {};
    for (var g in grades) {
      if (g.numericValue == 5 && g.date != null) {
        final w = g.date!.weekday;
        fivesByWeekday[w] = (fivesByWeekday[w] ?? 0) + 1;
      }
    }
    int bestWeekday = -1;
    int maxFivesOnWeekday = 0;
    for (var entry in fivesByWeekday.entries) {
      if (entry.value > maxFivesOnWeekday) {
        maxFivesOnWeekday = entry.value;
        bestWeekday = entry.key;
      }
    }
    final weekdays = ["Hétfő", "Kedd", "Szerda", "Csütörtök", "Péntek", "Szombat", "Vasárnap"];

    // 3. Késések összesítése
    final delays = absences.where((a) => a.type?.toLowerCase() == 'késés' || a.status.toLowerCase() == 'késés').toList();
    int totalDelayMinutes = 0;
    for (var d in delays) {
      totalDelayMinutes += d.delayMinutes ?? 0;
    }
    int totalDelaysCount = delays.length;

    // 4. Üzenet-király (Most messages sender)
    final Map<String, int> messagesBySender = {};
    for (var m in messages) {
      if (m.senderName.isNotEmpty) {
        messagesBySender[m.senderName] = (messagesBySender[m.senderName] ?? 0) + 1;
      }
    }
    String topSender = '';
    int topSenderCount = 0;
    if (messagesBySender.isNotEmpty) {
      final sortedSenders = messagesBySender.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topSender = sortedSenders.first.key;
      topSenderCount = sortedSenders.first.value;
    }

    final monthNames = ["Január", "Február", "Március", "Április", "Május", "Június", "Július", "Augusztus", "Szeptember", "Október", "November", "December"];

    _clearScreen();

    // Helper for slides
    Future<void> showSlide(String title, List<String> content, {String color = '\x1B[32m'}) async {
      _clearScreen();
      print('$color════════════════════════════════════════════════════════════════════\x1B[0m');
      print('$color  $title\x1B[0m');
      print('$color════════════════════════════════════════════════════════════════════\x1B[0m\n');
      for (var line in content) {
        print(line);
        await Future.delayed(Duration(milliseconds: 1000));
      }
      print('\n\x1B[90m(Nyomj Enter-t a folytatáshoz...)\x1B[0m');
      stdin.readLineSync();
    }

    // Intro
    _clearScreen();
    print('\x1B[1;36m========================================');
    print('         🎉 FOLIO WRAPPED 🎉');
    print('========================================\x1B[0m\n');
    print('Készen állsz, hogy megnézd a tanéved összefoglalóját?');
    print('Dőlj hátra, és nézzük meg, mit alkottál idén!');
    print('\n\x1B[90m(Nyomj Enter-t a kezdéshez...)\x1B[0m');
    stdin.readLineSync();

    // Slide 1: General
    await showSlide('A Nagy Kép', [
      'Idén összesen \x1B[1;33m$totalGrades\x1B[0m darab jegyet szereztél.',
      'Ebből \x1B[1;32m$total5s darab ötös\x1B[0m volt!',
      total1s > 0 ? '...és becsúszott \x1B[1;31m$total1s darab egyes\x1B[0m is. (De ezen már ne görcsölj!)' : 'És egyetlen egyest sem kaptál! Ez elképesztő! 👏',
      '',
      'Az egész éves teljesítményed (összes tantárgy alapján):',
      '⭐ ${FolioTheme.primaryBold}Év végi átlagod: ${overallAvg.toStringAsFixed(2)}${FolioTheme.reset} ⭐'
    ], color: FolioTheme.primary);

    // Generate bar chart for grades
    String drawBar(int count, int maxCount, String color) {
      if (maxCount == 0) return '';
      final width = (count / maxCount * 20).round();
      return '$color${'█' * width}\x1B[0m ($count)';
    }
    final maxGradeCount = gradesDist.reduce((a, b) => a > b ? a : b);

    // Slide 1.5: Grade Distribution
    await showSlide('A Jegyek Eloszlása', [
      'Így néz ki a teljes éves bizonyítványod statisztikája:\n',
      'Ötösök:   ${drawBar(gradesDist[4], maxGradeCount, '\x1B[32m')}',
      'Négyesek: ${drawBar(gradesDist[3], maxGradeCount, FolioTheme.primary)}',
      'Hármasok: ${drawBar(gradesDist[2], maxGradeCount, '\x1B[33m')}',
      'Kettesek: ${drawBar(gradesDist[1], maxGradeCount, '\x1B[38;5;208m')}',
      'Egyesek:  ${drawBar(gradesDist[0], maxGradeCount, '\x1B[31m')}',
    ], color: '\x1B[32m');

    // Slide 2: Highs and Lows
    String bestMonthStr = bestMonth != -1 ? monthNames[bestMonth - 1] : "Szeptember";
    String worstExamMonthStr = worstExamMonth != -1 ? monthNames[worstExamMonth - 1] : "Május";
    await showSlide('Hullámvölgyek és Csúcsok', [
      'A leginkább pörgős napod \x1B[1;33m$mostActiveDay\x1B[0m volt.',
      'Ezen az egy napon \x1B[1;35m$mostActiveCount\x1B[0m jegyet véstek be az ellenőrződbe!',
      '',
      'A legsikeresebb hónapod egyértelműen \x1B[1;32m$bestMonthStr\x1B[0m volt,',
      'amikor $bestMonthFives darab ötössel zártad a hónapot.',
      '',
      'A "Rettegés Hónapja" pedig \x1B[1;31m$worstExamMonthStr\x1B[0m volt,',
      'amikor összesen $maxExams számonkérést írtál meg!'
    ], color: '\x1B[35m');

    // Slide 2.5: Legszorgalmasabb Nap & Tanári Rangsor
    String bestWeekdayStr = bestWeekday != -1 ? weekdays[bestWeekday - 1] : "Szerda";
    await showSlide('A Legszorgalmasabb Napod & Kedvenc Tanárod', [
      'A hét napjai közül leginkább a(z) \x1B[1;32m$bestWeekdayStr\x1B[0m volt a te napod,',
      'amikor összesen \x1B[1;33m$maxFivesOnWeekday darab ötöst\x1B[0m zsebeltél be a tanévben! 🏆',
      '',
      topTeacherCount > 0 ? 'A legtöbb jegyet \x1B[1;36m$topTeacher\x1B[0m tanárodtól kaptad,' : 'Nem sikerült beazonosítani, ki osztotta a legtöbb jegyet,',
      topTeacherCount > 0 ? 'aki összesen \x1B[1;35m$topTeacherCount alkalommal\x1B[0m értékelt téged.' : 'de biztosan mindenki sokat dolgozott veled!'
    ], color: '\x1B[36m');

    // Slide 3: Subjects
    await showSlide('Tantárgyi Csaták', [
      'Úgy tűnik, a kedvenc tárgyad a \x1B[1;32m${AppState.instance.applyAlias(bestSubj)}\x1B[0m volt.',
      'Itt zártad a legjobb átlagot: \x1B[1;36m${bestAvg.toStringAsFixed(2)}\x1B[0m.',
      '',
      'A legnehezebbnek pedig a \x1B[1;31m${AppState.instance.applyAlias(worstSubj)}\x1B[0m bizonyult.',
      'De ne aggódj, túlélted ezt is, egy \x1B[1m${worstAvg.toStringAsFixed(2)}\x1B[0m-es átlaggal!'
    ], color: '\x1B[33m');

    // Slide 4: Absences & Communication
    String delayStr = totalDelaysCount > 0 
      ? 'Becsúszott mellé \x1B[1;33m$totalDelaysCount darab késés\x1B[0m is, összesen \x1B[1;35m$totalDelayMinutes percet\x1B[0m vesztegetve el.'
      : 'És egyetlen egyszer sem késtél el! Mindig pontos voltál! ⏰';
      
    String topSenderStr = topSenderCount > 0
      ? 'A legtöbb üzenetet \x1B[1;36m$topSender\x1B[0m küldte neked ($topSenderCount alkalommal).'
      : 'Senki sem spamelte a postaládádat.';

    await showSlide('Túlélési Stratégiák', [
      'Az évet összesen \x1B[1;31m$totalHours\x1B[0m hiányzott órával zártad.',
      topMissedCount > 0 ? 'A legtöbbet a \x1B[1;36m${AppState.instance.applyAlias(topMissed)}\x1B[0m órákat kerülted el ($topMissedCount alkalommal).' : 'Egyetlen egy órát sem hiányoztál? Ez valami robot üzemmód!',
      delayStr,
      '',
      'A tanév során megírtál \x1B[1;35m${exams.length}\x1B[0m számonkérést,',
      'és megcsináltál \x1B[1;34m${homeworks.length}\x1B[0m házi feladatot is.',
      '',
      messages.isNotEmpty ? 'Ezen kívül kaptál \x1B[1;33m${messages.length}\x1B[0m üzenetet a Krétában.' : 'Csendes év volt, egyetlen üzenetet sem kaptál a Krétában!',
      topSenderStr
    ], color: '\x1B[31m');

    // Outro
    _clearScreen();
    print('\x1B[1;32m========================================');
    print('      KÉSZ, VÉGE, VAKÁCIÓ! 🏖️');
    print('========================================\x1B[0m\n');
    print('Köszönjük, hogy a \x1B[1mFolio CLI\x1B[0m-t használtad az éven!');
    print('Jó pihenést a nyárra, találkozunk szeptemberben!\n');
    _pause('Vissza a főmenübe...');
  }
}
