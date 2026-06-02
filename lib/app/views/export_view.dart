part of '../cli_app.dart';

extension FolioCliAppExportView on FolioCliApp {
  Future<void> _exportToCsv() async {
      if (!await _ensureClientReady()) return;
      _clearScreen();
      print('\n--- Adatok exportálása (CSV) ---');
      print('Jegyek és mulasztások lekérése...');
      
      final grades = await _client!.getGrades();
      final absences = await _client!.getAbsences();
      
      try {
        final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
        final desktopPath = Platform.isWindows ? '$home\\Desktop' : '$home/Desktop';
        final desktop = Directory(desktopPath);
        final outDir = desktop.existsSync() ? desktop.path : home;
        final sep = Platform.isWindows ? '\\' : '/';

        if (grades != null && grades.isNotEmpty) {
          final csvFile = File('$outDir${sep}Folio_Jegyek.csv');
          String csvContent = 'Tantárgy;Érték;Dátum;Téma\n';
          for (var g in grades) {
            final t = g.subject;
            final v = g.numericValue ?? g.textValue ?? '';
            final d = g.date?.toString().split(' ').first.split('T').first ?? '';
            final th = g.theme ?? '';
            csvContent += '"$t";"$v";"$d";"$th"\n';
          }
          csvFile.writeAsBytesSync(const [239, 187, 191]); // UTF-8 BOM
          csvFile.writeAsStringSync(csvContent, mode: FileMode.append);
          print('Jegyek elmentve: ${csvFile.path}');
        }
        
        if (absences != null && absences.isNotEmpty) {
          final csvFile = File('$outDir${sep}Folio_Mulasztasok.csv');
          String csvContent = 'Tantárgy;Dátum;Igazolt;Típus\n';
          for (var a in absences) {
            final t = a.subject;
            final d = a.date?.toString().split(' ').first.split('T').first ?? '';
            final i = a.status == 'Igazolt' ? 'Igen' : 'Nem';
            final ty = a.type ?? '';
            csvContent += '"$t";"$d";"$i";"$ty"\n';
          }
          csvFile.writeAsBytesSync(const [239, 187, 191]); // UTF-8 BOM
          csvFile.writeAsStringSync(csvContent, mode: FileMode.append);
          print('Mulasztások elmentve: ${csvFile.path}');
        }
      } catch (e) {
        print('Hiba a fájlok mentése során: $e');
      }
      
      print('');
      Input(prompt: 'Nyomj Enter-t a visszatéréshez...').interact();
    }

}
