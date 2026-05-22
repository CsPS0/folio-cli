import 'dart:io';
import 'package:args/args.dart';
import 'package:folio_cli/app/cli_app.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('institute', abbr: 'i', help: 'Az intézmény kódja (pl. intezmeny123)')
    ..addOption('username', abbr: 'u', help: 'Felhasználónév (oktatási azonosító)')
    ..addOption('password', abbr: 'p', help: 'Jelszó')
    ..addFlag('daemon', abbr: 'd', negatable: false, help: 'Háttérfolyamatként futtatás értesítésekhez')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Megjeleníti a súgót');

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    print(e);
    exit(1);
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
    await app.runWithCredentials(institute, username, password);
  } else {
    if (arguments.isNotEmpty) {
      print('Figyelem: A parancssoros bejelentkezéshez az intézmény, felhasználónév és jelszó is szükséges.');
      print('Indítás interaktív módban...\n');
    }
    await app.runInteractive();
  }
}
