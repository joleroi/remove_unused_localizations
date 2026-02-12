import 'package:remove_unused_localizations/remove_unused_localizations.dart';

void main(List<String> arguments) {
  // Check for help argument
  if (arguments.contains('--help') || arguments.contains('-h')) {
    _printHelp();
    return;
  }

  bool keepUnused = arguments.contains('--keep-unused');
  
  // Parse custom source directories from command line
  List<String>? customSourceDirs;
  final sourceDirsIndex = arguments.indexOf('--source-dirs');
  if (sourceDirsIndex != -1 && sourceDirsIndex + 1 < arguments.length) {
    // Support comma-separated directories in a single argument
    final sourceDirsArg = arguments[sourceDirsIndex + 1];
    customSourceDirs = sourceDirsArg.split(',').map((dir) => dir.trim()).toList();
  }

  print('✅ Running Localization Cleaner...');
  runLocalizationCleaner(
    keepUnused: keepUnused,
    customSourceDirs: customSourceDirs,
  );
  print('✅ Done.');
}

void _printHelp() {
  print('''
remove_unused_localizations

USAGE:
  dart run remove_unused_localizations [OPTIONS]

OPTIONS:
  --keep-unused          Keep unused keys in a file instead of removing them
  --source-dirs DIRS     Comma-separated list of source directories to scan
                        (e.g., --source-dirs lib,packages/core/lib,packages/shared/lib)
  -h, --help            Show this help message

EXAMPLES:
  # Scan only the default lib directory
  dart run remove_unused_localizations
  
  # Scan multiple directories
  dart run remove_unused_localizations --source-dirs lib,packages/core/lib
  
  # Keep unused keys in a file instead of removing them
  dart run remove_unused_localizations --keep-unused
  
  # Combine options
  dart run remove_unused_localizations --keep-unused --source-dirs lib,packages/shared/lib
''');
}
