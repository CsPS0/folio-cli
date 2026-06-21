// ignore_for_file: implementation_imports

import 'dart:io';
import 'dart:math';
import 'package:dart_console/dart_console.dart';
import 'package:interact/src/framework/framework.dart';
import 'package:interact/src/theme/theme.dart';
import 'package:interact/src/utils/prompt.dart';

String _truncate(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  if (maxLength <= 3) return text.substring(0, max(0, maxLength));
  return '${text.substring(0, maxLength - 3)}...';
}

class CustomMenu extends Component<int> {
  CustomMenu({
    required this.prompt,
    required this.options,
    this.unselectableIndices = const [],
    this.initialIndex = 0,
  }) : theme = Theme.defaultTheme;

  final Theme theme;
  final String prompt;
  final int initialIndex;
  final List<String> options;
  final List<int> unselectableIndices;

  @override
  _CustomMenuState createState() => _CustomMenuState();
}

class _CustomMenuState extends State<CustomMenu> {
  int index = 0;

  @override
  void init() {
    super.init();

    if (component.options.isEmpty) {
      throw Exception("Options can't be empty");
    }

    index = component.initialIndex;
    while (component.unselectableIndices.contains(index) && index < component.options.length - 1) {
      index++;
    }

    context.writeln(promptInput(
      theme: component.theme,
      message: component.prompt,
    ));
    context.hideCursor();
  }

  @override
  void dispose() {
    context.writeln(promptSuccess(
      theme: component.theme,
      message: component.prompt,
      value: component.options[index],
    ));
    context.showCursor();
    super.dispose();
  }

  @override
  void render() {
    final width = stdout.hasTerminal ? stdout.terminalColumns : 80;
    final maxLen = max(10, width - 6);

    for (var i = 0; i < component.options.length; i++) {
      var option = component.options[i];
      if (!component.unselectableIndices.contains(i)) {
        option = _truncate(option, maxLen);
      }
      final line = StringBuffer();

      if (component.unselectableIndices.contains(i)) {
        // Dim the separator without prefix
        final sepMaxLen = max(10, width - 4);
        line.write('  \x1B[90m${_truncate(option, sepMaxLen)}\x1B[0m');
      } else if (i == index) {
        line.write(component.theme.activeItemPrefix);
        line.write(' ');
        line.write(component.theme.activeItemStyle(option));
      } else {
        line.write(component.theme.inactiveItemPrefix);
        line.write(' ');
        line.write(component.theme.inactiveItemStyle(option));
      }
      context.writeln(line.toString());
    }
  }

  @override
  int interact() {
    while (true) {
      final key = context.readKey();

      switch (key.controlChar) {
        case ControlCharacter.arrowUp:
          setState(() {
            do {
              index = (index - 1) % component.options.length;
              if (index < 0) index += component.options.length;
            } while (component.unselectableIndices.contains(index));
          });
          break;
        case ControlCharacter.arrowDown:
          setState(() {
            do {
              index = (index + 1) % component.options.length;
            } while (component.unselectableIndices.contains(index));
          });
          break;
        case ControlCharacter.enter:
          if (!component.unselectableIndices.contains(index)) {
            return index;
          }
          break;
        default:
          break;
      }
    }
  }
}

class PaginatedMenu extends Component<int> {
  PaginatedMenu({
    required this.prompt,
    required this.allOptions,
    this.pageSize = 15,
    this.initialIndex = 0,
  }) : theme = Theme.defaultTheme;

  final Theme theme;
  final String prompt;
  final int initialIndex;
  final List<String> allOptions;
  final int pageSize;

  @override
  _PaginatedMenuState createState() => _PaginatedMenuState();
}

class _PaginatedMenuState extends State<PaginatedMenu> {
  int index = 0;
  int currentPage = 0;

  @override
  void init() {
    super.init();

    if (component.allOptions.isEmpty) {
      throw Exception("Options can't be empty");
    }

    index = component.initialIndex;
    currentPage = 0;

    context.writeln(promptInput(
      theme: component.theme,
      message: component.prompt,
    ));
    context.hideCursor();
  }

  @override
  void dispose() {
    final startIndex = currentPage * component.pageSize;
    final endIndex = min(startIndex + component.pageSize, component.allOptions.length);
    final pageItemsCount = endIndex - startIndex;
    
    final value = (index == pageItemsCount) ? 'Vissza' : component.allOptions[currentPage * component.pageSize + index];
    context.writeln(promptSuccess(
      theme: component.theme,
      message: component.prompt,
      value: value,
    ));
    context.showCursor();
    super.dispose();
  }

  @override
  void render() {
    final hasPrev = currentPage > 0;
    final hasNext = (currentPage + 1) * component.pageSize < component.allOptions.length;
    final totalPages = ((component.allOptions.length - 1) / component.pageSize).floor() + 1;
    
    final prevColor = hasPrev ? '\x1B[94m' : '\x1B[90m';
    final nextColor = hasNext ? '\x1B[94m' : '\x1B[90m';
    
    final width = stdout.hasTerminal ? stdout.terminalColumns : 80;
    
    var header = '  ${prevColor}◀ Előző (Bal nyíl)${'\x1B[0m'}  |  ${nextColor}Következő (Jobb nyíl) ▶${'\x1B[0m'}  (Oldal: ${currentPage + 1} / $totalPages)';
    final headerClean = header.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
    if (headerClean.length > width) {
      header = '  ${prevColor}◀ Előző${'\x1B[0m'} | ${nextColor}Következő ▶${'\x1B[0m'} (${currentPage + 1}/$totalPages)';
    }
    context.writeln(header);
    
    final sepLength = min(width - 4, 66);
    final separator = '─' * sepLength;
    context.writeln('  \x1B[90m$separator\x1B[0m');

    final startIndex = currentPage * component.pageSize;
    final endIndex = min(startIndex + component.pageSize, component.allOptions.length);
    final pageItemsCount = endIndex - startIndex;
    
    final maxLen = max(10, width - 6);
    
    for (var i = startIndex; i < endIndex; i++) {
      final option = _truncate(component.allOptions[i], maxLen);
      final localIndex = i - startIndex;
      final line = StringBuffer();
      
      if (localIndex == index) {
        line.write(component.theme.activeItemPrefix);
        line.write(' ');
        line.write(component.theme.activeItemStyle(option));
      } else {
        line.write(component.theme.inactiveItemPrefix);
        line.write(' ');
        line.write(component.theme.inactiveItemStyle(option));
      }
      context.writeln(line.toString());
    }

    final line = StringBuffer();
    if (index == pageItemsCount) {
      line.write(component.theme.activeItemPrefix);
      line.write(' ');
      line.write(component.theme.activeItemStyle('Vissza'));
    } else {
      line.write(component.theme.inactiveItemPrefix);
      line.write(' ');
      line.write(component.theme.inactiveItemStyle('Vissza'));
    }
    context.writeln(line.toString());
  }

  @override
  int interact() {
    while (true) {
      final key = context.readKey();

      final startIndex = currentPage * component.pageSize;
      final endIndex = min(startIndex + component.pageSize, component.allOptions.length);
      final pageItemsCount = endIndex - startIndex;
      final totalSelectable = pageItemsCount + 1;

      switch (key.controlChar) {
        case ControlCharacter.arrowUp:
          setState(() {
            index = (index - 1) % totalSelectable;
            if (index < 0) index += totalSelectable;
          });
          break;
        case ControlCharacter.arrowDown:
          setState(() {
            index = (index + 1) % totalSelectable;
          });
          break;
        case ControlCharacter.arrowLeft:
          if (currentPage > 0) {
            setState(() {
              currentPage--;
              index = 0;
            });
          }
          break;
        case ControlCharacter.arrowRight:
          final nextStartIndex = (currentPage + 1) * component.pageSize;
          if (nextStartIndex < component.allOptions.length) {
            setState(() {
              currentPage++;
              index = 0;
            });
          }
          break;
        case ControlCharacter.enter:
          if (index == pageItemsCount) {
            return -1;
          }
          return currentPage * component.pageSize + index;
        default:
          break;
      }
    }
  }
}
