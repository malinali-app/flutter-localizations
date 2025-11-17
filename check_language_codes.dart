// Script to check which language codes from our ARB files might not be in Flutter's registry
import 'dart:io';

void main() {
  final l10nDir = Directory('../flutter/packages/flutter_localizations/lib/src/l10n');
  
  if (!l10nDir.existsSync()) {
    print('ERROR: Flutter l10n directory not found!');
    exit(1);
  }
  
  // Get all existing ARB files to see what codes Flutter already supports
  final existingFiles = l10nDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb'))
      .toList();
  
  final existingCodes = <String>{};
  for (final file in existingFiles) {
    final filename = file.path.split(Platform.pathSeparator).last;
    final match = RegExp(r'(?:material|cupertino|widgets)_(\w+)(?:_\w+)?\.arb').firstMatch(filename);
    if (match != null) {
      existingCodes.add(match.group(1)!);
    }
  }
  
  print('Existing language codes in Flutter: ${existingCodes.length}');
  print('Sample: ${existingCodes.take(10).join(', ')}...\n');
  
  // Check our generated files
  final ourDir = Directory('arb_output');
  if (!ourDir.existsSync()) {
    print('ERROR: arb_output directory not found!');
    exit(1);
  }
  
  final ourFiles = ourDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb'))
      .toList();
  
  final ourCodes = <String>{};
  final problematicCodes = <String>[];
  
  for (final file in ourFiles) {
    final filename = file.path.split(Platform.pathSeparator).last;
    final match = RegExp(r'(?:material|cupertino|widgets)_(\w+)\.arb').firstMatch(filename);
    if (match != null) {
      final code = match.group(1)!;
      ourCodes.add(code);
      if (!existingCodes.contains(code) && code != 'en') {
        problematicCodes.add(code);
      }
    }
  }
  
  print('Our language codes: ${ourCodes.length}');
  print('Potentially problematic codes (not in Flutter registry): ${problematicCodes.length}');
  
  if (problematicCodes.isNotEmpty) {
    print('\nProblematic codes:');
    for (final code in problematicCodes.toList()..sort()) {
      print('  - $code');
    }
    print('\nThese codes might not be in the IANA language subtag registry.');
    print('You may need to find their correct ISO 639-1/639-2 codes.');
  } else {
    print('\nAll codes appear to be valid!');
  }
}


