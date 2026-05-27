part of '../cli_app.dart';

extension FolioCliAppHomeworkView on FolioCliApp {
  Future<void> _showHomework() async {
      while (true) {
        final action = Select(
          prompt: 'Házi feladatok',
          options: ['Házi feladatok megtekintése', 'Vissza'],
        ).interact();
  
        if (action == 1) return;
        _clearScreen();
        print('\n--- Házi feladatok ---');
        final hw = await _client!.getHomework();
        if (hw != null) {
          if (hw.isEmpty) {
            print('Nincs megjeleníthető házi feladat.');
          } else {
            for (var item in hw) {
              final date = item['RogzitesIdopontja']?.toString().split('T').first ?? '';
              final subject = item['Tantargy'] is Map ? (item['Tantargy']['Nev'] ?? 'Ismeretlen tárgy') : (item['Tantargy'] ?? 'Ismeretlen tárgy');
              final text = item['Szoveg']?.toString().replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('\n', ' ') ?? '';
              
              print('[$date] $subject');
              print('  Feladat: $text');
              print('  Határidő: ${(item['HataridoDatuma'] ?? item['HataridoIdopontja'])?.toString().split('T').first ?? '?'}');
              print('---');
            }
          }
        } else {
          print('Nem sikerült lekérdezni a házi feladatokat.');
        }
        print('');
      }
    }

  Future<void> _showMessages() async {
      while (true) {
        final action = Select(
          prompt: 'Üzenetek',
          options: ['Beérkezett üzenetek megtekintése', 'Vissza'],
        ).interact();
  
        if (action == 1) return;
        _clearScreen();
        print('\n--- Üzenetek ---');
        final messages = await _client!.getMessages();
        if (messages != null) {
          if (messages.isEmpty) {
            print('Nincs beérkezett üzenet.');
          } else {
            messages.sort((a, b) {
              final dateA = DateTime.tryParse(a['uzenet']?['kuldesDatum'] ?? '') ?? DateTime(2000);
              final dateB = DateTime.tryParse(b['uzenet']?['kuldesDatum'] ?? '') ?? DateTime(2000);
              return dateB.compareTo(dateA);
            });
  
            for (var msg in messages.take(15)) {
              final dateStr = msg['uzenet']?['kuldesDatum']?.toString().replaceAll('T', ' ').substring(0, 16) ?? '';
              final felado = msg['uzenet']?['feladoNev'] ?? 'Ismeretlen feladó';
              final targy = msg['uzenet']?['targy'] ?? 'Nincs tárgy';
              final isRead = msg['isElolvasva'] == true;
              
              String marker = isRead ? " " : "*";
              print('[$marker] $dateStr - $felado');
              print('    Tárgy: $targy');
            }
            if (messages.length > 15) {
              print('  ... és még ${messages.length - 15} régebbi üzenet.');
            }
          }
        } else {
          print('Nem sikerült lekérdezni az üzeneteket.');
        }
        print('');
      }
    }

}
