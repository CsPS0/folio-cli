import 'dart:io';
import 'package:interact/interact.dart';

void main() {
  Select(
    prompt: 'Válassz',
    options: ['Opció 1', 'Opció 2'],
  ).interact();

  try {
    stdin.echoMode = true;
    stdin.lineMode = true;
  } catch (e) {
  }

  stdout.write('\nIde másold: ');
  final text = stdin.readLineSync();
  print('Beírtad: $text');
}
