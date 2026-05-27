part of '../cli_app.dart';

extension FolioCliAppAbsencesView on FolioCliApp {
  Future<void> _showAbsences() async {
      while (true) {
        final action = Select(
          prompt: 'Mulasztások',
          options: ['Legutóbbi mulasztások megtekintése', 'Vissza'],
        ).interact();
  
        if (action == 1) return;
        _clearScreen();
        print('\n--- Mulasztások ---');
        final absences = await _client!.getAbsences();
        if (absences != null) {
          if (absences.isEmpty) {
            print('Nincsenek mulasztások.');
          } else {
            absences.sort((a, b) {
              final dateA = DateTime.tryParse(a['Datum'] ?? '') ?? DateTime(2000);
              final dateB = DateTime.tryParse(b['Datum'] ?? '') ?? DateTime(2000);
              return dateB.compareTo(dateA); // Legújabb elöl
            });
  
            for (var absence in absences.take(10)) {
              final dateStr = absence['Datum']?.toString().split('T').first ?? '';
              final subject = absence['Tantargy']?['Nev'] ?? 'Ismeretlen tárgy';
              final status = absence['IgazolasAllapota'] ?? 'Ismeretlen';
              print('[$dateStr] $subject ($status)');
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
        final action = Select(
          prompt: 'Tantárgyi átlagok',
          options: ['Átlagok megtekintése', 'Vissza'],
        ).interact();
  
        if (action == 1) return;
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
