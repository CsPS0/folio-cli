part of '../cli_app.dart';

extension FolioCliAppHomeworkView on FolioCliApp {
  Future<void> _showHomework() async {
      while (true) {
        if (!await _ensureClientReady()) return;
        _clearScreen();
        _showMainMenuBanner();
        
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
        _pause();
      }
    }

  Future<void> _showMessages() async {
      while (true) {
        if (!await _ensureClientReady()) return;
        _clearScreen();
        _showMainMenuBanner();
        
        final action = Select(
          prompt: 'Üzenetek',
          options: [
            'Legutóbbi 5 üzenet (Gyorsolvasás)',
            'Üzenetek listázása és részletek',
            'Vissza'
          ],
        ).interact();
  
        if (action == 2) return;
        _clearScreen();
        print('\n--- Üzenetek ---');
        final messages = await _client!.getMessages();
        if (messages == null) {
          print('Nem sikerült lekérdezni az üzeneteket.');
          _pause();
          continue;
        }

        if (messages.isEmpty) {
          print('Nincs beérkezett üzenet.');
          _pause();
          continue;
        }

        messages.sort((a, b) {
          final dateA = a.sentDate ?? DateTime(2000);
          final dateB = b.sentDate ?? DateTime(2000);
          return dateB.compareTo(dateA);
        });

        if (action == 0) {
          final limit = 5;
          print('Üzenetek teljes tartalmának letöltése...\n');
          for (var msg in messages.take(limit)) {
            final dateStr = msg.sentDate?.toString().substring(0, 16) ?? '';
            final felado = msg.senderName;
            final targy = msg.subject;
            final isRead = msg.isRead;
            
            String fullText = msg.text;
            if (msg.id != 0) {
              try {
                final fetchedText = await _client!.getMessageContent(msg.id);
                if (fetchedText != null && fetchedText.isNotEmpty) {
                  fullText = fetchedText;
                }
              } catch (e) {
                FolioLogger.debug('Failed to fetch message content for id ${msg.id}: $e');
              }
            }
            
            final text = fullText.replaceAll(RegExp(r'<[^>]*>'), '').trim();
            
            String marker = isRead ? " " : "*";
            print('----------------------------------------');
            print('[$marker] Dátum: $dateStr');
            print('Feladó: \x1B[1;36m$felado\x1B[0m');
            print('Tárgy: \x1B[1;33m$targy\x1B[0m');
            print('Üzenet:\n$text\n');
            
            if (msg.attachments.isNotEmpty) {
              print('Csatolmányok:');
              for (var att in msg.attachments) {
                print('  - ${att.name} (ID: ${att.id})');
              }
              final downloadAns = Utf8Input(prompt: 'Szeretnél letölteni csatolmányt ebből az üzenetből? (i/N)').interact().trim().toLowerCase();
              if (downloadAns == 'i' || downloadAns == 'y') {
                await _downloadAttachmentFlow(msg.attachments);
              }
            }
          }
          _pause();
        } else {
          // List messages and let user choose using PaginatedMenu
          final List<String> formattedOptions = [];
          for (var msg in messages) {
            final dateStr = msg.sentDate?.toString().substring(0, 10) ?? '';
            final felado = msg.senderName;
            final targy = msg.subject.length > 30 ? '${msg.subject.substring(0, 27)}...' : msg.subject;
            final marker = msg.isRead ? " " : "*";
            formattedOptions.add('[$marker] $dateStr - $felado - $targy');
          }
          
          while (true) {
            _clearScreen();
            _showMainMenuBanner();
            
            final choice = PaginatedMenu(
              prompt: 'Válassz üzenetet a megtekintéshez:',
              allOptions: formattedOptions,
              pageSize: 15,
            ).interact();

            if (choice == -1) {
              break;
            }

            final msg = messages[choice];
            _clearScreen();
            print('\n--- Üzenet Részletei ---');
            final dateStr = msg.sentDate?.toString().substring(0, 16) ?? '';
            print('Dátum: $dateStr');
            print('Feladó: \x1B[1;36m${msg.senderName}\x1B[0m');
            print('Tárgy: \x1B[1;33m${msg.subject}\x1B[0m');
            print('----------------------------------------');

            String fullText = msg.text;
            if (msg.id != 0) {
              print('Üzenet letöltése...');
              try {
                final fetchedText = await _client!.getMessageContent(msg.id);
                if (fetchedText != null && fetchedText.isNotEmpty) {
                  fullText = fetchedText;
                }
              } catch (e) {
                FolioLogger.debug('Failed to fetch message content: $e');
              }
              _clearScreen();
              print('\n--- Üzenet Részletei ---');
              print('Dátum: $dateStr');
              print('Feladó: \x1B[1;36m${msg.senderName}\x1B[0m');
              print('Tárgy: \x1B[1;33m${msg.subject}\x1B[0m');
              print('----------------------------------------');
            }

            final text = fullText.replaceAll(RegExp(r'<[^>]*>'), '').trim();
            print('Szöveg:\n$text\n');

            if (msg.attachments.isNotEmpty) {
              print('----------------------------------------');
              print('Csatolmányok:');
              for (var att in msg.attachments) {
                print('  - ${att.name}');
              }
              print('');
              final downloadAns = Utf8Input(prompt: 'Szeretnél letölteni valamilyen csatolmányt? (i/N)').interact().trim().toLowerCase();
              if (downloadAns == 'i' || downloadAns == 'y') {
                await _downloadAttachmentFlow(msg.attachments);
              }
            } else {
              _pause();
            }
          }
        }
      }
    }

  Future<void> _downloadAttachmentFlow(List<MessageAttachment> attachments) async {
    if (attachments.isEmpty) return;
    
    final options = attachments.map((a) => a.name).toList();
    options.add('Mégse');
    
    final choice = Select(
      prompt: 'Válassz csatolmányt a letöltéshez:',
      options: options,
    ).interact();
    
    if (choice == options.length - 1) return;
    
    final selected = attachments[choice];
    print('Letöltés folyamatban: ${selected.name}...');
    final success = await _client!.downloadAttachment(selected.id, selected.name);
    if (success) {
      final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
      final downloadsPath = p.join(home, 'Downloads');
      final downloadsDir = Directory(downloadsPath);
      final outDir = downloadsDir.existsSync() ? downloadsDir.path : home;
      final safeName = selected.name.replaceAll(RegExp(r'\s+'), '_');
      final finalPath = p.join(outDir, safeName);
      print('\x1B[92mSikeresen letöltve! Fájl helye: $finalPath\x1B[0m');
    } else {
      print('\x1B[31mHiba történt a letöltés során.\x1B[0m');
    }
    _pause();
  }

}
