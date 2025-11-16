// Script to add missing language codes to Flutter's language subtag registry
import 'dart:io';

void main() {
  final registryFile = File('../flutter/dev/tools/localization/language_subtag_registry.dart');
  final dictionaryFile = File('dictionary.tsv');
  
  if (!registryFile.existsSync()) {
    print('ERROR: Registry file not found!');
    exit(1);
  }
  
  if (!dictionaryFile.existsSync()) {
    print('ERROR: dictionary.tsv not found!');
    exit(1);
  }
  
  // Read existing registry
  final registryContent = registryFile.readAsStringSync();
  
  // Read dictionary to get language names
  // Maps both alpha2 and alpha3 codes to language names
  final dictionary = <String, String>{};
  final lines = dictionaryFile.readAsLinesSync();
  for (var i = 1; i < lines.length; i++) {
    final parts = lines[i].split('\t');
    if (parts.length >= 3) {
      final alpha2 = parts[0].trim();
      final alpha3 = parts[1].trim();
      final name = parts[2].trim();
      // Extract just the language name (before any additional info)
      final languageName = name.split(RegExp(r'\s+'))[0];
      if (alpha2.isNotEmpty) {
        dictionary[alpha2] = languageName;
      }
      if (alpha3.isNotEmpty) {
        dictionary[alpha3] = languageName;
      }
    }
  }
  
  // Get all language codes from our ARB files
  final arbDir = Directory('arb_output');
  if (!arbDir.existsSync()) {
    print('ERROR: arb_output directory not found! Run conversion first.');
    exit(1);
  }
  
  final ourCodes = <String>{};
  final arbFiles = arbDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb'))
      .toList();
  
  for (final file in arbFiles) {
    final filename = file.path.split(Platform.pathSeparator).last;
    final match = RegExp(r'(?:material|cupertino|widgets)_(\w+)\.arb').firstMatch(filename);
    if (match != null) {
      ourCodes.add(match.group(1)!);
    }
  }
  
  // Check which codes are missing from registry
  final missingCodes = <String>[];
  for (final code in ourCodes) {
    if (code == 'en') continue; // Skip English
    if (!registryContent.contains('Subtag: $code\n')) {
      missingCodes.add(code);
    }
  }
  
  if (missingCodes.isEmpty) {
    print('All language codes are already in the registry!');
    exit(0);
  }
  
  print('Found ${missingCodes.length} missing language codes:');
  for (final code in missingCodes.toList()..sort()) {
    print('  - $code');
  }
  
  // Generate entries for missing codes
  // Note: No comments allowed - the parser doesn't support them
  final newEntries = StringBuffer();
  
  for (final code in missingCodes.toList()..sort()) {
    final name = dictionary[code] ?? code.toUpperCase();
    newEntries.writeln('%%');
    newEntries.writeln('Type: language');
    newEntries.writeln('Subtag: $code');
    newEntries.writeln('Description: $name');
    newEntries.writeln('Added: 2024-01-01');
  }
  
  // Insert before the closing '''
  final insertPos = registryContent.lastIndexOf("'''");
  if (insertPos == -1) {
    print('ERROR: Could not find closing marker in registry file!');
    exit(1);
  }
  
  final newContent = registryContent.substring(0, insertPos) + 
                     newEntries.toString() + 
                     registryContent.substring(insertPos);
  
  // Write back
  registryFile.writeAsStringSync(newContent);
  
  print('\n✓ Added ${missingCodes.length} language codes to registry!');
  print('  File: ${registryFile.path}');
  print('\nYou can now run the generator again.');
}

