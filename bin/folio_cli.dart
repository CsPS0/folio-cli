import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:folio_cli/app/cli_app.dart';
import 'package:folio_cli/utils/logger.dart';
import 'package:folio_cli/utils/win32_console.dart';
import 'package:folio_cli/version.dart';

void main(List<String> arguments) async {
  enableUtf8Console();

  try {
    stdout.encoding = utf8;
    stderr.encoding = utf8;
  } catch (_) {}

  final parser = ArgParser()
    ..addOption('institute', abbr: 'i', help: 'Az intézmény kódja (pl. intezmeny123)')
    ..addOption('username', abbr: 'u', help: 'Felhasználónév (oktatási azonosító)')
    ..addOption('password', abbr: 'p', help: 'Jelszó')
    ..addFlag('daemon', abbr: 'd', negatable: false, help: 'Háttérfolyamatként futtatás értesítésekhez')
    ..addFlag('version', abbr: 'v', negatable: false, help: 'Verzióinformáció megjelenítése')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Megjeleníti a súgót')
    ..addFlag('debug', negatable: false, help: 'Debug mód: részletes hibaüzenetek a stderr-en')
    ..addOption('completions', help: 'Shell autocompletion szkript generálása (bash, zsh, fish, powershell)');

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    print(e);
    exit(1);
  }

  if (argResults['completions'] != null) {
    final shell = argResults['completions'].toString().toLowerCase();
    if (shell == 'bash') {
      print('complete -W "-i -u -p -d -v -h --institute --username --password --daemon --version --help --completions" folio-cli');
    } else if (shell == 'zsh') {
      print('compdef _folio-cli folio-cli\n_folio-cli() { _arguments "-i" "-u" "-p" "-d" "-v" "-h" "--institute" "--username" "--password" "--daemon" "--version" "--help" "--completions" }');
    } else if (shell == 'fish') {
      print('complete -c folio-cli -s i -l institute\ncomplete -c folio-cli -s u -l username\ncomplete -c folio-cli -s p -l password\ncomplete -c folio-cli -s d -l daemon\ncomplete -c folio-cli -s v -l version\ncomplete -c folio-cli -s h -l help\ncomplete -c folio-cli -l completions');
    } else if (shell == 'powershell') {
      print('Register-ArgumentCompleter -Native -CommandName folio-cli -ScriptBlock { param(\$commandName, \$parameterName, \$wordToComplete, \$commandAst, \$fakeBoundParameters); @("-i", "-u", "-p", "-d", "-v", "-h", "--institute", "--username", "--password", "--daemon", "--version", "--help", "--completions") | Where-Object { \$_ -like "\$wordToComplete*" } }');
    } else {
      print('Ismeretlen shell. Támogatott: bash, zsh, fish, powershell');
    }
    exit(0);
  }

  FolioLogger.init(enabled: argResults['debug']);

  if (argResults['version']) {
    print('Folio CLI $appVersion');
    exit(0);
  }

  if (argResults['help']) {
    print('Folio CLI (Kréta API)');
    print('Használat: folio-cli [opciók]');
    print(parser.usage);
    exit(0);
  }

  final app = FolioCliApp();

  if (argResults['daemon']) {
    await app.runDaemon();
    exit(0);
  }

  final institute = argResults['institute'];
  final username = argResults['username'];
  final password = argResults['password'];

  if (institute != null && username != null && password != null) {
    await app.runWithCredentials(institute, username, password, startInDashboard: argResults.rest.contains('dash'));
  } else {
    if (arguments.isNotEmpty && !argResults.rest.contains('dash')) {
      print('Figyelem: A parancssoros bejelentkezéshez az intézmény, felhasználónév és jelszó is szükséges.');
      print('Indítás interaktív módban...\n');
    }
    await app.runInteractive(startInDashboard: argResults.rest.contains('dash'));
  }
}
