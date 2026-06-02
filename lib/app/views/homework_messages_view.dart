part of '../cli_app.dart';

extension FolioCliAppHomeworkView on FolioCliApp {
  Future<void> _showHomework() async {
      while (true) {
        if (!await _ensureClientReady()) return;
        
        final action = Select(
          prompt: 'Házi feladatok',
          options: ['Legutóbbi 10 házi feladat', 'Összes házi feladat', 'Vissza'],
        ).interact();
  
        if (action == 2) return;
        _clearScreen();
        print('\n--- Házi feladatok ---');
        final hw = await _client!.getHomework();
        if (hw != null) {
          if (hw.isEmpty) {
            print('Nincs megjeleníthető házi feladat.');
          } else {
            final limit = action == 0 ? 10 : hw.length;
            for (var item in hw.take(limit)) {
              final date = item.assignedDate?.toString().split(' ').first.split('T').first ?? '';
              final subject = item.subject;
              final text = item.text;
              
              print('[$date] $subject');
              print('  Feladat: $text');
              print('  Határidő: ${item.deadline?.toString().split(' ').first.split('T').first ?? '?'}');
              print('---');
            }
            if (action == 0 && hw.length > 10) {
              print('  ... és még ${hw.length - 10} régebbi házi feladat.');
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
        if (!await _ensureClientReady()) return;
        
        final action = Select(
          prompt: 'Üzenetek',
          options: ['Legutóbbi 15 üzenet', 'Összes üzenet', 'Vissza'],
        ).interact();
  
        if (action == 2) return;
        _clearScreen();
        print('\n--- Üzenetek ---');
        final messages = await _client!.getMessages();
        if (messages != null) {
          if (messages.isEmpty) {
            print('Nincs beérkezett üzenet.');
          } else {
            messages.sort((a, b) {
              final dateA = a.sentDate ?? DateTime(2000);
              final dateB = b.sentDate ?? DateTime(2000);
              return dateB.compareTo(dateA);
            });
  
            final limit = action == 0 ? 15 : messages.length;
            for (var msg in messages.take(limit)) {
              final dateStr = msg.sentDate?.toString().substring(0, 16) ?? '';
              final felado = msg.senderName;
              final targy = msg.subject;
              final isRead = msg.isRead;
              
              String marker = isRead ? " " : "*";
              print('[$marker] $dateStr - $felado');
              print('    Tárgy: $targy');
            }
            if (action == 0 && messages.length > 15) {
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
