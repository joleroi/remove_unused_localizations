import 'package:remove_unused_localizations/remove_unused_localizations.dart';

void main() {
  // Example 1: Running with default configuration (scans 'lib' directory)
  print('--- Example 1: Default behavior ---');
  runLocalizationCleaner();

  // Example 2: Running with custom source directories
  print('\n--- Example 2: Custom source directories ---');
  runLocalizationCleaner(
    customSourceDirs: ['lib', 'packages/core/lib', 'packages/shared/lib'],
  );

  // Example 3: Keep unused keys instead of removing them
  print('\n--- Example 3: Keep unused keys ---');
  runLocalizationCleaner(
    keepUnused: true,
    customSourceDirs: ['lib', 'packages/feature_a/lib'],
  );
}
