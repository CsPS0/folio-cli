part of '../cli_app.dart';

extension FolioCliAppDaemonLogic on FolioCliApp {
  Future<void> _checkNewItems() async {
      final state = AppState.instance;
      final oldGradesCount = int.tryParse(state.getAuthData()['gradesCount']?.toString() ?? '0') ?? 0;
      
      final grades = await _client!.getGrades();
      if (grades != null) {
        if (grades.length > oldGradesCount && oldGradesCount > 0) {
          final newGradesCount = grades.length - oldGradesCount;
          await _showToast('Folio (Kréta)', 'Kaptál $newGradesCount új jegyet!');
        }
        final currentData = state.getAuthData();
        currentData['gradesCount'] = grades.length;
        state.saveAuthData(currentData);
      }
  
      final oldHwCount = int.tryParse(state.getAuthData()['homeworkCount']?.toString() ?? '0') ?? 0;
      final homeworks = await _client!.getHomework(start: DateTime.now().subtract(Duration(days: 7)));
      if (homeworks != null) {
        if (homeworks.length > oldHwCount && oldHwCount > 0) {
          final newHwCount = homeworks.length - oldHwCount;
          await _showToast('Folio (Kréta)', 'Kaptál $newHwCount új házi feladatot!');
        }
        final currentData = state.getAuthData();
        currentData['homeworkCount'] = homeworks.length;
        state.saveAuthData(currentData);
      }

      final exams = await _client!.getExams();
      if (exams != null) {
        final tomorrow = DateTime.now().add(Duration(days: 1));
        final tomorrowStr = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
        
        for (var exam in exams) {
          final examDateStr = exam.date?.toString().split(' ').first;
          if (examDateStr == tomorrowStr) {
            await _showToast('Folio (Kréta)', 'Holnap dolgozat: ${exam.subject} (${exam.mode})');
            break;
          }
        }
      }
    }

  Future<void> _showToast(String title, String message) async {
      final safeTitle = title.replaceAll("'", "''").replaceAll('"', '\\"');
      final safeMessage = message.replaceAll("'", "''").replaceAll('"', '\\"');
      
      if (Platform.isWindows) {
        final script = '''
  [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > \$null
  \$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
  \$texts = \$template.GetElementsByTagName("text")
  \$texts[0].AppendChild(\$template.CreateTextNode('$safeTitle')) > \$null
  \$texts[1].AppendChild(\$template.CreateTextNode('$safeMessage')) > \$null
  \$toast = [Windows.UI.Notifications.ToastNotification]::new(\$template)
  \$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("FolioCLI")
  \$notifier.Show(\$toast)
  ''';
        await Process.run('powershell', ['-Command', script]);
      } else if (Platform.isLinux) {
        await Process.run('notify-send', [title, message]);
      } else if (Platform.isMacOS) {
        final script = 'display notification "$safeMessage" with title "$safeTitle"';
        await Process.run('osascript', ['-e', script]);
      }
    }

  void _setupDaemon(bool enable) {
    if (enable) {
      installDaemon();
    } else {
      uninstallDaemon();
    }
  }

  void installDaemon() {
    if (!Platform.isWindows) return;
    try {
      final exePath = Platform.resolvedExecutable;
      final script = '''
\$action = New-ScheduledTaskAction -Execute "$exePath" -Argument "--daemon"
\$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 60)
Register-ScheduledTask -Action \$action -Trigger \$trigger -TaskName "FolioCLIDaemon" -Description "Folio CLI háttérfolyamat" -Force
''';
      Process.runSync('powershell', ['-Command', script]);
      print('Háttérfolyamat sikeresen telepítve (óránként fut).');
    } catch (e) {
      print('Hiba a telepítés során: \$e');
    }
  }

  void uninstallDaemon() {
    if (!Platform.isWindows) return;
    try {
      Process.runSync('schtasks', ['/Delete', '/TN', 'FolioCLIDaemon', '/F']);
      print('Háttérfolyamat eltávolítva.');
    } catch (e) {
      print('Hiba az eltávolítás során: \$e');
    }
  }
}
