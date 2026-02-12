import 'dart:convert';
import 'dart:io';
import 'package:yaml/yaml.dart';

/// Scans the project for unused localization keys and removes them from `.arb` files.
void runLocalizationCleaner({
  bool keepUnused = false,
  List<String>? customSourceDirs,
}) {
  final File yamlFile = File('l10n.yaml'); // Path to the l10n.yaml file
  if (!yamlFile.existsSync()) {
    print('✅ Error: l10n.yaml file not found!');
    return;
  }

  // Read & parse YAML
  final String yamlContent = yamlFile.readAsStringSync();
  final Map yamlData = loadYaml(yamlContent);

  // Extract values dynamically
  final String arbDir = yamlData['arb-dir'] as String;

  // Construct values
  final Directory localizationDir = Directory(arbDir);
  final Set<String> excludedFiles = {'$arbDir/app_localizations.dart'};

  // Read .arb file
  final List<File> localizationFiles =
      localizationDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.arb'))
          .toList();

  if (localizationFiles.isEmpty) {
    print('✅ No .arb files found in ${localizationDir.path}');
    return;
  }

  final Set<String> allKeys = <String>{};
  final Map<File, Set<String>> fileKeyMap = <File, Set<String>>{};

  // Read all keys from ARB files
  for (final File file in localizationFiles) {
    final Map<String, dynamic> data =
        json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    final Set<String> keys =
        data.keys.where((key) => !key.startsWith('@')).toSet();
    allKeys.addAll(keys);
    fileKeyMap[file] = keys;
  }

  final Set<String> usedKeys = <String>{};
  
  // Use custom source directories or default to 'lib'
  final List<String> sourceDirs = customSourceDirs ?? ['lib'];

  // Reg Exp to detect localization keys
  final String keysPattern = allKeys.map(RegExp.escape).join('|');
  final RegExp regex = RegExp(
    r'(?:' // Start non-capturing group for all possible access patterns
            r'\(?\s*(?:[a-zA-Z0-9_]+\.)+' // e.g., `_appLocalizations.` or `(_appLocalizations.` with optional opening parenthesis
            r'|'
            r'\(?\s*[a-zA-Z0-9_]+\.of\(\s*(?:context|AppNavigation\.context|this\.context|BuildContext\s+\w+)\s*,?\s*\)[\!\?]?\s*\)?\s*\.\s*' // `(AppLocalizations.of(context,)!)` with optional wrapping parentheses and null-aware or force unwrap operator
            r'|'
            r'\(?\s*[a-zA-Z0-9_]+\.\w+\(\s*\)\s*\)?\s*\.\s*' // `(SomeClass.method())` with optional parentheses
            r')'
            r'(' +
        keysPattern +
        r')(?:\b|\()', // The actual key followed by word boundary OR opening parenthesis for function calls
    multiLine: true,
    dotAll: true, // Makes `.` match newlines (crucial for multi-line cases)
  );

  // Scan configured source directories for key usage
  for (final String sourceDirPath in sourceDirs) {
    final Directory sourceDir = Directory(sourceDirPath);
    if (!sourceDir.existsSync()) {
      print('⚠️ Warning: Source directory "$sourceDirPath" does not exist, skipping...');
      continue;
    }
    
    print('🔍 Scanning directory: $sourceDirPath');
    
    for (final FileSystemEntity file in sourceDir.listSync(recursive: true)) {
      if (file is File &&
          file.path.endsWith('.dart') &&
          !excludedFiles.contains(file.path)) {
        final String content = file.readAsStringSync();

        // Quick pre-check: skip files that don't contain any key substring
        if (!content.contains(RegExp(keysPattern))) continue;

        for (final Match match in regex.allMatches(content)) {
          usedKeys.add(match.group(1)!); // Capture only the key
        }
      }
    }
  }

  // Determine unused keys
  final Set<String> unusedKeys = allKeys.difference(usedKeys);
  if (unusedKeys.isEmpty) {
    print('✅ No unused localization keys found.');
    return;
  }

  print("✅ Unused keys found: ${unusedKeys.join(', ')}");

  if (keepUnused) {
    // Keep unused keys to a file instead of deleting them
    final File unusedKeysFile = File('unused_localization_keys.txt');
    unusedKeysFile.writeAsStringSync(unusedKeys.join('\n'));
    print('✅ Unused keys saved to ${unusedKeysFile.path}');
  } else {
    // Remove unused keys from all .arb files
    for (final MapEntry<File, Set<String>> entry in fileKeyMap.entries) {
      final File file = entry.key;
      final Set<String> keys = entry.value;
      final Map<String, dynamic> data =
          json.decode(file.readAsStringSync()) as Map<String, dynamic>;

      bool updated = false;
      for (final key in keys) {
        if (unusedKeys.contains(key)) {
          data.remove(key);
          data.remove('@$key');
          updated = true;
        }
      }

      if (updated) {
        file.writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(data),
        );
        print('✅ Updated ${file.path}, removed unused keys.');
      }
    }
    print('✅ Unused keys successfully removed.');
  }
}
