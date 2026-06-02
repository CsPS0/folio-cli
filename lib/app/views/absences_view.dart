part of '../cli_app.dart';

extension FolioCliAppAbsencesView on FolioCliApp {
  Future<void> _showAbsences() async {
      while (true) {
        if (!await _ensureClientReady()) return;
        
        final action = Select(
          prompt: 'Mulasztások',
          options: ['Legutóbbi 10 mulasztás', 'Összes mulasztás', 'Vissza'],
        ).interact();
  
        if (action == 2) return;
        _clearScreen();
        print('\n--- Mulasztások ---');
        final absences = await _client!.getAbsences();
        if (absences != null) {
          if (absences.isEmpty) {
            print('Nincsenek mulasztások.');
          } else {
            absences.sort((a, b) {
              final dateA = a.date ?? DateTime(2000);
              final dateB = b.date ?? DateTime(2000);
              return dateB.compareTo(dateA); // Legújabb elöl
            });
  
            final limit = action == 0 ? 10 : absences.length;
            for (var absence in absences.take(limit)) {
              final dateStr = absence.date?.toString().split(' ').first.split('T').first ?? '';
              final subject = absence.subject;
              final status = absence.status;
              
              String coloredStatus = status;
              final sLower = status.toLowerCase();
              final tLower = absence.type?.toLowerCase() ?? '';
              
              if (tLower == 'késés' || sLower == 'késés') {
                coloredStatus = '\x1B[38;5;208m$status\x1B[0m';
              } else if (sLower == 'igazolt') {
                coloredStatus = '\x1B[92m$status\x1B[0m';
              } else if (sLower == 'igazolando' || sLower == 'igazolandó') {
                coloredStatus = '\x1B[33m$status\x1B[0m';
              } else if (sLower == 'igazolatlan') {
                coloredStatus = '\x1B[31m$status\x1B[0m';
              }
              
              print('[$dateStr] $subject ($coloredStatus)');
            }
            if (action == 0 && absences.length > 10) {
              print('  ... és még ${absences.length - 10} régebbi mulasztás.');
            }
          }
        } else {
          print('Nem sikerült lekérdezni a mulasztásokat.');
        }
        print('');
      }
    }

  Future<void> _showAverages() async {
      while (true) {
        if (!await _ensureClientReady()) return;
        
        final action = Select(
          prompt: 'Tantárgyi átlagok',
          options: ['Átlagok megtekintése', 'Célátlag kalkulátor', 'Vissza'],
        ).interact();
  
        if (action == 2) return;
        if (action == 1) {
          await _showTargetAverageCalculator();
          continue;
        }
        
        _clearScreen();
        print('\n--- Tantárgyi átlagok ---');
        print('Adatok lekérése...');
        
        final averages = await _client!.getAverages();
        if (averages != null) {
          if (averages.isEmpty) {
            print('Nincsenek átlagok.');
          } else {
            final Map<String, double> chartData = {};
            for (var avg in averages) {
              final subject = avg['Tantargy']?['Nev'] ?? 'Ismeretlen tárgy';
              final valueStr = avg['Ertek']?.toString() ?? '0';
              final value = double.tryParse(valueStr.replaceAll(',', '.')) ?? 0.0;
              if (value > 0) {
                chartData[subject] = value;
              }
            }
            if (chartData.isNotEmpty) {
              print(ChartGenerator.generateBarChart(chartData));
            } else {
              for (var avg in averages) {
                final subject = avg['Tantargy']?['Nev'] ?? 'Ismeretlen tárgy';
                final value = avg['Ertek']?.toString() ?? '-';
                print('$subject: $value');
              }
            }
          }
        } else {
          print('Nem sikerült lekérdezni az átlagokat.');
        }
        print('');
      }
    }

}
