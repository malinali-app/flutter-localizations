// Script to add missing language codes to Flutter's language subtag registry
import 'dart:io';

/// Extracts description from existing registry entry
String? extractDescriptionFromRegistry(String registryContent, String code) {
  final pattern = RegExp(
    r'Subtag: $code\nDescription: (.+)\n',
    multiLine: true,
  );
  final match = pattern.firstMatch(registryContent);
  return match?.group(1);
}

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
  var registryContent = registryFile.readAsStringSync();
  
  // Get current date in YYYY-MM-DD format
  final now = DateTime.now();
  final currentDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  
  // Read dictionary to get language names
  // Maps both alpha2 and alpha3 codes to full language names from nameEng column
  final dictionary = <String, String>{};
  final lines = dictionaryFile.readAsLinesSync();
  for (var i = 1; i < lines.length; i++) {
    final parts = lines[i].split('\t');
    if (parts.length >= 3) {
      final alpha2 = parts[0].trim();
      final alpha3 = parts[1].trim();
      final nameEng = parts[2].trim();
      // Use the full nameEng (e.g., "Mesopotamian Arabic", "Northern Uzbek", "Standard Malay")
      if (alpha2.isNotEmpty) {
        dictionary[alpha2] = nameEng;
      }
      if (alpha3.isNotEmpty) {
        dictionary[alpha3] = nameEng;
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
  
  // Find all existing language codes in registry (any date)
  // IMPORTANT: Only match base language codes, not script-specific ones (which contain underscores)
  final existingCodes = <String>{};
  final existingPattern = RegExp(r'Type: language\nSubtag: ([a-z]{2,3})\nDescription: (.+)\nAdded: (\d{4}-\d{2}-\d{2})', multiLine: true);
  for (final match in existingPattern.allMatches(registryContent)) {
    final code = match.group(1)!;
    // Only add codes that don't contain underscores (script codes are separate)
    if (!code.contains('_') && !code.contains('-')) {
      existingCodes.add(code);
    }
  }
  
  print('Found ${existingCodes.length} existing language codes in registry');
  
  // Filter our codes: remove any with underscores (script codes) and check against existing
  final missingCodes = <String>[];
  for (final code in ourCodes) {
    if (code == 'en') continue; // Skip English
    
    // Skip codes with underscores or hyphens (these are script-specific, not base language codes)
    if (code.contains('_') || code.contains('-')) {
      print('  Skipping $code (contains script code separator)');
      continue;
    }
    
    // Check if code already exists in registry
    if (!existingCodes.contains(code)) {
      missingCodes.add(code);
    } else {
      print('  $code already exists in registry');
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
    String description;
    
    // First try dictionary.tsv
    if (dictionary.containsKey(code)) {
      description = dictionary[code]!;
    } else {
      // Try to extract from existing registry (for codes that might already exist)
      final existingDesc = extractDescriptionFromRegistry(registryContent, code);
      if (existingDesc != null) {
        description = existingDesc;
      } else {
        // Fallback: use code in uppercase (shouldn't happen if dictionary is complete)
        description = code.toUpperCase();
        print('  WARNING: No description found for $code, using fallback');
      }
    }
    
    newEntries.writeln('%%');
    newEntries.writeln('Type: language');
    newEntries.writeln('Subtag: $code');
    newEntries.writeln('Description: $description');
    newEntries.writeln('Added: $currentDate');
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
  print('  Date used: $currentDate');
  print('\nYou can now run the generator again.');
}

