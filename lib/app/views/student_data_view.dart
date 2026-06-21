part of '../cli_app.dart';

extension FolioCliAppStudentView on FolioCliApp {
  Future<void> _showStudentData() async {
      while (true) {
        if (!await _ensureClientReady()) return;
        _clearScreen();
        _showMainMenuBanner();

        final action = Select(
          prompt: 'Tanulói adatlap',
          options: ['Adatok megtekintése', 'Vissza'],
        ).interact();
  
        if (action == 1) return;
        _clearScreen();
        print('\n--- Tanulói adatlap lekérdezése ---');
        final data = await _client!.getStudentData();
        if (data != null) {
          print('Név: \x1B[1;36m${data.name}\x1B[0m');
          print('Intézmény: ${data.institutionName}');
          if (data.birthName != null) print('Születési név: ${data.birthName}');
          if (data.birthPlace != null) print('Születési hely: ${data.birthPlace}');
          if (data.birthDate != null) {
            final dateStr = data.birthDate!.split('T').first;
            print('Születési idő: $dateStr');
          }
          if (data.mothersName != null) print('Anyja neve: ${data.mothersName}');
          if (data.email != null) print('Email cím: ${data.email}');
          if (data.phone != null) print('Telefonszám: ${data.phone}');
          if (data.nextDowntime != null) {
            print('\x1B[33mKarbantartás: A következő tervezett leállás: ${data.nextDowntime!.toLocal()}\x1B[0m');
          }
          
          if (data.addresses.isNotEmpty) {
            print('\nCímek:');
            for (var addr in data.addresses) {
              print(' - $addr');
            }
          }
          
          if (data.guardians.isNotEmpty) {
            print('\nGondviselők:');
            for (var g in data.guardians) {
              final gName = g['Nev'] ?? 'Ismeretlen';
              final gEmail = g['EmailCim'] ?? 'Nincs email';
              final gPhone = g['Telefonszam'] ?? 'Nincs telefonszám';
              print(' - $gName ($gEmail, $gPhone)');
            }
          }

          studentUid = data.uid;
        } else {
          print('Nem sikerült lekérdezni az adatokat.');
        }
        _pause();
      }
    }

  Future<void> _showTargetAverageCalculator() async {
      if (!await _ensureClientReady()) return;
      
      _clearScreen();
      print('\n--- Célátlag Kalkulátor ---');
      final grades = await _client!.getGrades();
      if (grades == null || grades.isEmpty) {
        print('Nincsenek elérhető jegyek a számoláshoz.');
        Utf8Input(prompt: 'Nyomj Enter-t a visszatéréshez...').interact();
        return;
      }
  
      final Map<String, List<Map<String, double>>> subjectGrades = {};
      for (var grade in grades) {
        if (grade.isSummaryGrade) continue;
        
        final subject = grade.subject;
        
        final numVal = grade.numericValue;
        if (numVal == null || numVal == 0 || numVal > 5) continue;
        
        final weight = grade.weight;
        
        subjectGrades.putIfAbsent(subject, () => []);
        subjectGrades[subject]!.add({'value': numVal.toDouble(), 'weight': weight});
      }
  
      if (subjectGrades.isEmpty) {
        print('Nincsenek számítható tantárgyak.');
        Utf8Input(prompt: 'Nyomj Enter-t a visszatéréshez...').interact();
        return;
      }
  
      final subjects = subjectGrades.keys.toList()..sort();
      final subjectIdx = Select(
        prompt: 'Melyik tantárgy célátlagát szeretnéd kiszámolni?',
        options: [...subjects, 'Vissza'],
      ).interact();
  
      if (subjectIdx == subjects.length) return;
  
      final subject = subjects[subjectIdx];
      final items = subjectGrades[subject]!;
      
      double sum = 0;
      double weightSum = 0;
      for (var item in items) {
        sum += item['value']! * item['weight']!;
        weightSum += item['weight']!;
      }
      
      final currentAvg = weightSum > 0 ? (sum / weightSum) : 0.0;
      print('\nKiválasztott tantárgy: $subject');
      print('Jelenlegi átlagod: ${currentAvg.toStringAsFixed(2)}');
  
      final targetStr = Utf8Input(
        prompt: 'Mi a megcélzott átlag? (pl. 4.5)',
        defaultValue: '4.5',
      ).interact();
  
      final target = double.tryParse(targetStr.replaceAll(',', '.')) ?? 0.0;
      if (target <= currentAvg) {
        print('Ezt az átlagot már elérted! Gratulálok!');
      } else if (target >= 5.0) {
        print('\nCél: ${target.toStringAsFixed(2)}');
        print('Ezt a célátlagot matematikailag már lehetetlen elérni, mert van 5-ösnél rosszabb jegyed (csak megközelíteni lehet végtelen sok ötössel).');
      } else {
        final requiredFives = (target * weightSum - sum) / (500 - target * 100);
        final intFives = requiredFives.ceil();
        print('\nCél: ${target.toStringAsFixed(2)}');
        print('Ehhez pontosan $intFives darab 100%-os ÖTÖSRE van szükséged.');
        
        if (target < 4.0) {
          final requiredFours = (target * weightSum - sum) / (400 - target * 100);
          if (requiredFours > 0) {
            final intFours = requiredFours.ceil();
            print('Vagy $intFours darab 100%-os NÉGYESRE.');
          }
        }
      }
      
      print('');
      Utf8Input(prompt: 'Nyomj Enter-t a visszatéréshez...').interact();
    }

}
