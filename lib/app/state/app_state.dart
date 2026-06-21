import 'dart:io';
import 'dart:convert';
import 'package:folio_cli/utils/logger.dart';

class AppState {
  static final AppState instance = AppState._internal();
  
  bool isOffline = false;
  String theme = 'blue';
  bool showAsciiBanner = true;

  AppState._internal() {
    loadTheme();
  }

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
    } catch (e) {
      FolioLogger.debug('Failed to load file ${file.path}: $e');
      return {};
    }
  }

  void _save(File file, Map<String, dynamic> data) {
    try {
      file.writeAsStringSync(jsonEncode(data));
    } catch (e) {
      FolioLogger.debug('Failed to save file ${file.path}: $e');
    }
  }

  Map<String, dynamic> getAuthData() {
    return _load(authFile);
  }

  void saveAuthData(Map<String, dynamic> data) {
    _save(authFile, data);
  }

  Map<String, dynamic> getAppState() {
    return _load(stateFile);
  }

  void saveAppState(Map<String, dynamic> data) {
    _save(stateFile, data);
  }

  File get aliasesFile {
    _ensureConfigDir();
    return File('$configDir/aliases.json');
  }

  Map<String, String> getAliases() {
    final data = _load(aliasesFile);
    return data.map((key, value) => MapEntry(key, value.toString()));
  }

  String applyAlias(String original) {
    if (Platform.environment['NO_RENAME'] == '1') return original;
    final aliases = getAliases();
    return aliases[original] ?? original;
  }

  void loadTheme() {
    final state = getAppState();
    if (state.containsKey('theme')) {
      theme = state['theme'];
    }
    if (state.containsKey('showAsciiBanner')) {
      showAsciiBanner = state['showAsciiBanner'] == true;
    }
  }

  void saveTheme(String newTheme) {
    theme = newTheme;
    final state = getAppState();
    state['theme'] = theme;
    saveAppState(state);
  }

  void setTheme(String newTheme) => saveTheme(newTheme);

  void setShowAsciiBanner(bool val) {
    showAsciiBanner = val;
    final state = getAppState();
    state['showAsciiBanner'] = showAsciiBanner;
    saveAppState(state);
  }

  void setAlias(String original, String alias) {
    final state = getAppState();
    if (state['aliases'] == null) state['aliases'] = <String, dynamic>{};
    state['aliases'][original] = alias;
    saveAppState(state);
  }

  void removeAlias(String original) {
    final state = getAppState();
    if (state['aliases'] != null) {
      state['aliases'].remove(original);
      saveAppState(state);
    }
  }

  void clearAllData() {
    if (stateFile.existsSync()) {
      stateFile.deleteSync();
    }
    if (authFile.existsSync()) {
      authFile.deleteSync();
    }
    final secureFile = File('$configDir/.secure_token');
    if (secureFile.existsSync()) {
      secureFile.deleteSync();
    }
    final cacheDir = Directory('$configDir/cache');
    if (cacheDir.existsSync()) {
      cacheDir.deleteSync(recursive: true);
    }
  }
}
