part of '../cli_app.dart';

extension FolioCliAppAuthManager on FolioCliApp {
  Future<void> _saveAuth() async {
      if (_client?.accessToken == null) return;
      
      String profileName = 'Ismeretlen Profil';
      final studentData = await _client!.getStudentData();
      if (studentData != null) {
        profileName = studentData.name;
      }
  
      final authFile = _getAuthFile();
      Map<String, dynamic> root = {'activeProfileIndex': 0, 'profiles': []};
      
      if (authFile.existsSync()) {
        try {
          final content = await authFile.readAsString();
          final data = jsonDecode(content);
          if (data is Map<String, dynamic>) {
            if (data.containsKey('profiles')) {
              root = data;
            } else if (data.containsKey('accessToken')) {
              root['profiles'].add({
                'name': 'Régi Profil',
                'instituteCode': data['instituteCode'],
                'accessToken': data['accessToken'],
                'refreshToken': data['refreshToken']
              });
            }
          }
        } catch (_) {}
      }
  
      List profiles = root['profiles'];
      
      int existingIdx = -1;
      for (int i = 0; i < profiles.length; i++) {
        if (profiles[i]['name'] == profileName && profiles[i]['instituteCode'] == _client!.instituteCode) {
          existingIdx = i;
          break;
        }
      }
  
      final newProfile = {
        'name': profileName,
        'instituteCode': _client!.instituteCode,
        'accessToken': _client!.accessToken,
        'refreshToken': _client!.refreshToken,
      };
  
      if (existingIdx != -1) {
        profiles[existingIdx] = newProfile;
        root['activeProfileIndex'] = existingIdx;
      } else {
        profiles.add(newProfile);
        root['activeProfileIndex'] = profiles.length - 1;
      }
  
      await authFile.writeAsString(jsonEncode(root));
    }

}
