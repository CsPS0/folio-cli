import 'dart:io';
import 'dart:convert';
import '../state/app_state.dart';
import '../../utils/encryption.dart';
import '../../api/client.dart';

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
          // Migration check: If it starts with '{', it's plain text JSON
          if (content.trim().startsWith('{')) {
            final data = jsonDecode(content);
            if (data is Map<String, dynamic> && data.containsKey('profiles')) {
              root = data;
            }
            // Immediately encrypt it
            await authFile.writeAsString(EncryptionUtil.encrypt(jsonEncode(root)));
          } else {
            final decrypted = EncryptionUtil.decrypt(content);
            final data = jsonDecode(decrypted);
            if (data is Map<String, dynamic> && data.containsKey('profiles')) {
              root = data;
            }
          }
        } catch (e) {
          print('Nem sikerült betölteni a profilokat: $e');
        }
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
  
      await authFile.writeAsString(EncryptionUtil.encrypt(jsonEncode(root)));
    }

}
