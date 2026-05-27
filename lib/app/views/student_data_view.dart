part of '../cli_app.dart';

extension FolioCliAppStudentView on FolioCliApp {
  Future<void> _showStudentData() async {
      while (true) {
        final action = Select(
          prompt: 'Tanulói adatlap',
          options: ['Adatok megtekintése', 'Vissza'],
        ).interact();
  
        if (action == 1) return;
        _clearScreen();
        print('\n--- Tanulói adatlap lekérdezése ---');
        final data = await _client!.getStudentData();
        if (data != null) {
          final name = data['Nev'] ?? 'Ismeretlen';
          final institution = data['IntezmenyNev'] ?? 'Ismeretlen intézmény';
          print('Név: $name');
          print('Intézmény: $institution');
          studentUid = data['Uid']?.toString();
        } else {
          print('Nem sikerült lekérdezni az adatokat.');
        }
        print('');
      }
    }

  Future<void> _showTargetAverageCalculator() async {
      _clearScreen();
      print('\n--- Célátlag Kalkulátor ---');
      final grades = await _client!.getGrades();
      if (grades == null || grades.isEmpty) {
        print('Nincsenek elérhető jegyek a számoláshoz.');
        Input(prompt: 'Nyomj Enter-t a visszatéréshez...').interact();
        return;
      }
  
      final Map<String, List<Map<String, double>>> subjectGrades = {};
      for (var grade in grades) {
        final tipus = grade['Tipus']?['Nev']?.toString().toLowerCase() ?? '';
        if (tipus.contains('vegi') || tipus.contains('felevevi') || tipus.contains('negyedevi')) continue;
        
        final subject = grade['Tantargy']?['Nev'];
        if (subject == null) continue;
        
        final numVal = grade['SzamErtek'];
        if (numVal == null || numVal == 0 || numVal > 5) continue;
        
        final weight = (grade['SulySzazalekErteke'] ?? 100).toDouble();
        
        subjectGrades.putIfAbsent(subject, () => []);
        subjectGrades[subject]!.add({'value': numVal is int ? numVal.toDouble() : double.parse(numVal.toString()), 'weight': weight});
      }
  
      if (subjectGrades.isEmpty) {
        print('Nincsenek számítható tantárgyak.');
        Input(prompt: 'Nyomj Enter-t a visszatéréshez...').interact();
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
  
      final targetStr = Input(
        prompt: 'Mi a megcélzott átlag? (pl. 4.5)',
        defaultValue: '4.5',
      ).interact();
  
      final target = double.tryParse(targetStr.replaceAll(',', '.')) ?? 0.0;
      if (target <= currentAvg) {
        print('Ezt az átlagot már elérted! Gratulálok!');
      } else if (target > 5.0) {
        print('5.0 feletti átlagot lehetetlen elérni.');
      } else {
        final requiredFives = (target * weightSum - sum) / (500 - target * 100);
        final intFives = requiredFives.ceil();
        print('\nCél: ${target.toStringAsFixed(2)}');
        print('Ehhez pontosan $intFives darab 100%-os ÖTÖSRE van szükséged.');
        
        if (target <= 4.0) {
          final requiredFours = (target * weightSum - sum) / (400 - target * 100);
          if (requiredFours > 0) {
            final intFours = requiredFours.ceil();
            print('Vagy $intFours darab 100%-os NÉGYESRE.');
          }
        }
      }
      
      print('');
      Input(prompt: 'Nyomj Enter-t a visszatéréshez...').interact();
    }

}
