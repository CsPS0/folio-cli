import 'state/app_state.dart';
import 'package:interact/interact.dart';

class FolioTheme {
  // Available theme options
  static const String themeBlue = 'blue';
  static const String themeGreen = 'green';
  static const String themePink = 'pink';
  static const String themeOrange = 'orange';

  // Helper to get the currently selected theme
  static String get _current => AppState.instance.theme;

  // Primary color (used for selected menu items, primary headers, etc.)
  static String get primary {
    switch (_current) {
      case themeGreen:
        return '\x1B[32m'; // Green
      case themePink:
        return '\x1B[35m'; // Magenta/Pink
      case themeOrange:
        return '\x1B[38;5;208m'; // Orange
      case themeBlue:
      default:
        return '\x1B[36m'; // Cyan/Blue
    }
  }

  // Primary bold color
  static String get primaryBold {
    switch (_current) {
      case themeGreen:
        return '\x1B[1;32m';
      case themePink:
        return '\x1B[1;35m';
      case themeOrange:
        return '\x1B[1;38;5;208m';
      case themeBlue:
      default:
        return '\x1B[1;36m';
    }
  }

  // Common colors
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String success = '\x1B[32m';
  static const String warning = '\x1B[33m';
  static const String error = '\x1B[31m';
  static const String muted = '\x1B[90m';
  
  // Custom prefix for menu and prompts
  static String get promptPrefix => '$primary?$reset';
  static String get arrowPrefix => '$primary❯$reset';

  static void configureInteractTheme() {
    Theme.defaultTheme = Theme(
      inputPrefix: '$primary?$reset ',
      inputSuffix: ' \x1B[90m›\x1B[0m',
      successPrefix: '\x1B[32m✔\x1B[0m ',
      successSuffix: ' \x1B[90m·\x1B[0m',
      errorPrefix: '\x1B[31m✘\x1B[0m ',
      hiddenPrefix: '****',
      messageStyle: (x) => '\x1B[1m$x\x1B[0m',
      errorStyle: (x) => '\x1B[31m$x\x1B[0m',
      hintStyle: (x) => '\x1B[90m($x)\x1B[0m',
      valueStyle: (x) => '$primary$x$reset',
      defaultStyle: (x) => '$primary$x$reset',
      activeItemPrefix: '$primary❯$reset',
      inactiveItemPrefix: ' ',
      activeItemStyle: (x) => '$primaryBold$x$reset',
      inactiveItemStyle: (x) => x,
      checkedItemPrefix: '$primary✔$reset',
      uncheckedItemPrefix: ' ',
      pickedItemPrefix: '$primary❯$reset',
      unpickedItemPrefix: ' ',
      showActiveCursor: false,
      progressPrefix: '',
      progressSuffix: '',
      emptyProgress: '░',
      filledProgress: '█',
      leadingProgress: '█',
      emptyProgressStyle: (x) => x,
      filledProgressStyle: (x) => x,
      leadingProgressStyle: (x) => x,
      spinners: '⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'.split(''),
      spinningInterval: 80,
    );
  }
}
