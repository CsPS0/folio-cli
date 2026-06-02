import 'dart:io';
import 'dart:convert';

class AppState {
  static final AppState instance = AppState._internal();
  
  AppState._internal();

  String get configDir {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    return '$home/.config/folio';
  }

  void _ensureConfigDir() {
    final dir = Directory(configDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  void migrateOldFiles() {
    _ensureConfigDir();
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    
    final oldAuth = File('$home/.folio_auth.json');
    if (oldAuth.existsSync() && !authFile.existsSync()) {
      oldAuth.copySync(authFile.path);
      oldAuth.deleteSync();
    }
    
    final oldState = File('$home/.folio_state.json');
    if (oldState.existsSync() && !stateFile.existsSync()) {
      oldState.copySync(stateFile.path);
      oldState.deleteSync();
    }
    
    final oldCache = File('$home/.folio_cache.json');
    if (oldCache.existsSync() && !File('$configDir/cache.json').existsSync()) {
      oldCache.copySync('$configDir/cache.json');
      oldCache.deleteSync();
    }
  }

  File get stateFile {
    _ensureConfigDir();
    return File('$configDir/state.json');
  }

  File get authFile {
    _ensureConfigDir();
    return File('$configDir/auth.json');
  }

  Map<String, dynamic> _load(File file) {
    if (!file.existsSync()) return {};
    try {
      final content = file.readAsStringSync();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  void _save(File file, Map<String, dynamic> data) {
    try {
      file.writeAsStringSync(jsonEncode(data));
    } catch (_) {}
  }

  String getTheme() {
    final state = _load(stateFile);
    return state['theme'] ?? 'dark';
  }

  void setTheme(String theme) {
    final state = _load(stateFile);
    state['theme'] = theme;
    _save(stateFile, state);
  }

  Map<String, dynamic> getAuthData() {
    return _load(authFile);
  }

  void saveAuthData(Map<String, dynamic> data) {
    _save(authFile, data);
  }
}
