part of '../cli_app.dart';

extension FolioCliAppDaemonLogic on FolioCliApp {
  Future<void> _checkNewItems() async {
      final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
      final stateFile = File('$home/.folio_state.json');
      Map<String, dynamic> state = {};
      if (stateFile.existsSync()) {
        try {
          state = jsonDecode(stateFile.readAsStringSync());
        } catch (_) {}
      }
  
      final oldGradesCount = state['gradesCount'] ?? 0;
      
      final grades = await _client!.getGrades();
      if (grades != null) {
        if (grades.length > oldGradesCount && oldGradesCount > 0) {
          final newGradesCount = grades.length - oldGradesCount;
          _showWindowsToast('Folio (Kréta)', 'Kaptál $newGradesCount új jegyet!');
        }
        state['gradesCount'] = grades.length;
      }
  
      final oldHwCount = state['homeworkCount'] ?? 0;
      final homeworks = await _client!.getHomework(start: DateTime.now().subtract(Duration(days: 7)));
      if (homeworks != null) {
        if (homeworks.length > oldHwCount && oldHwCount > 0) {
          final newHwCount = homeworks.length - oldHwCount;
          _showWindowsToast('Folio (Kréta)', 'Kaptál $newHwCount új házi feladatot!');
        }
        state['homeworkCount'] = homeworks.length;
      }
  
      stateFile.writeAsStringSync(jsonEncode(state));
    }

  void _showWindowsToast(String title, String message) {
      if (!Platform.isWindows) return;
      
      final safeTitle = title.replaceAll("'", "''");
      final safeMessage = message.replaceAll("'", "''");
      
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
      
      Process.run('powershell', ['-Command', script]);
    }

}
