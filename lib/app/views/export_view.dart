part of '../cli_app.dart';

extension FolioCliAppExportView on FolioCliApp {
  Future<void> _exportToCsv() async {
      _clearScreen();
      print('\n--- Adatok exportálása (CSV) ---');
      print('Jegyek és mulasztások lekérése...');
      
      final grades = await _client!.getGrades();
      final absences = await _client!.getAbsences();
      
      if (grades != null && grades.isNotEmpty) {
        final csvFile = File('Folio_Jegyek.csv');
        String csvContent = 'Tantárgy;Érték;Dátum;Téma\n';
        for (var g in grades) {
          final t = g['Tantargy']?['Nev'] ?? '';
          final v = g['Ertek'] ?? '';
          final d = g['KeszitesDatuma']?.toString().split('T').first ?? '';
          final th = g['Tema'] ?? '';
          csvContent += '"$t";"$v";"$d";"$th"\n';
        }
        csvFile.writeAsBytesSync(const [239, 187, 191]); // UTF-8 BOM
        csvFile.writeAsStringSync(csvContent, mode: FileMode.append);
        print('Jegyek elmentve: Folio_Jegyek.csv');
      }
      
      if (absences != null && absences.isNotEmpty) {
        final csvFile = File('Folio_Mulasztasok.csv');
        String csvContent = 'Tantárgy;Dátum;Igazolt;Típus\n';
        for (var a in absences) {
          final t = a['Tantargy']?['Nev'] ?? '';
          final d = a['Datum']?.toString().split('T').first ?? '';
          final i = a['IgazolasAllapota'] == 'Igazolt' ? 'Igen' : 'Nem';
          final ty = a['Tipus']?['Nev'] ?? '';
          csvContent += '"$t";"$d";"$i";"$ty"\n';
        }
        csvFile.writeAsBytesSync(const [239, 187, 191]); // UTF-8 BOM
        csvFile.writeAsStringSync(csvContent, mode: FileMode.append);
        print('Mulasztások elmentve: Folio_Mulasztasok.csv');
      }
      
      print('');
      Input(prompt: 'Nyomj Enter-t a visszatéréshez...').interact();
    }

}
