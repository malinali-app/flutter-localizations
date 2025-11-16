// Script to create base language ARB files from script-specific ones
// This is needed because Flutter's generator expects base language files
// when script-specific files exist

import 'dart:io';

void main() {
  final l10nDir = Directory('../flutter/packages/flutter_localizations/lib/src/l10n');
  
  if (!l10nDir.existsSync()) {
    print('ERROR: Flutter l10n directory not found!');
    exit(1);
  }
  
  print('Creating base language ARB files from script-specific ones...');
  
  final prefixes = ['material', 'cupertino', 'widgets'];
  int created = 0;
  
  for (final prefix in prefixes) {
    final files = l10nDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb') && f.path.contains('${prefix}_'))
        .toList();
    
    for (final file in files) {
      final filename = file.path.split(Platform.pathSeparator).last;
      final match = RegExp('${prefix}_(\\w+)_(\\w+)\\.arb').firstMatch(filename);
      
      if (match != null) {
        final languageCode = match.group(1)!;
        final scriptCode = match.group(2)!;
        
        // Check if base language file already exists
        final baseFilename = '${prefix}_$languageCode.arb';
        final baseFile = File('${l10nDir.path}/$baseFilename');
        
        if (!baseFile.existsSync()) {
          // Copy script-specific file to base language file
          final content = file.readAsStringSync();
          baseFile.writeAsStringSync(content);
          print('Created: $baseFilename (from ${filename})');
          created++;
        }
      }
    }
  }
  
  print('\nCreated $created base language ARB files.');
  print('You can now run the generator:');
  print('  cd ../flutter');
  print('  dart dev\\tools\\localization\\bin\\gen_localizations.dart --overwrite');
}

