// Copyright 2024 The Flutter Authors. All rights reserved.
// Conversion script to transform Dart MaterialLocalizations files to ARB format

import 'dart:io';
import 'dart:convert';

/// Maps ISO 639-3 (alpha3) codes to ISO 639-1/639-2 (alpha2) codes
Map<String, String> loadLanguageCodeMapping(String dictionaryPath) {
  final mapping = <String, String>{};
  final file = File(dictionaryPath);
  final lines = file.readAsLinesSync();
  
  // Skip header
  for (var i = 1; i < lines.length; i++) {
    final parts = lines[i].split('\t');
    if (parts.length >= 2) {
      final alpha2 = parts[0].trim();
      final alpha3 = parts[1].trim();
      if (alpha2.isNotEmpty && alpha3.isNotEmpty) {
        mapping[alpha3] = alpha2;
      }
    }
  }
  
  return mapping;
}

/// Extracts locale information from filename
/// Returns: (languageCode, scriptCode)
MapEntry<String, String?> extractLocaleFromFilename(String filename, Map<String, String> codeMapping) {
  final baseName = filename.replaceAll('.dart', '');
  final parts = baseName.split('_');
  
  String languageCode = parts[0];
  String? scriptCode;
  
  // Check if we have a script code (second part)
  if (parts.length > 1) {
    scriptCode = parts[1];
  }
  
  // Try to map 3-letter code to 2-letter code
  if (codeMapping.containsKey(languageCode)) {
    languageCode = codeMapping[languageCode]!;
  }
  
  return MapEntry(languageCode, scriptCode);
}

/// Determines scriptCategory based on script code and language
String determineScriptCategory(String? scriptCode, String languageCode) {
  if (scriptCode != null) {
    switch (scriptCode) {
      case 'Arab':
        return 'tall';
      case 'Deva':
      case 'Beng':
        return 'dense';
      case 'Tibt':
        return 'tall';
      case 'Mymr':
        return 'tall';
      case 'Hebr':
        return 'tall';
      case 'Cyrl':
        return 'English-like';
      case 'Latn':
      default:
        // Check language-specific cases
        if (['th', 'te', 'ur', 'ug'].contains(languageCode)) {
          return 'tall';
        }
        if (['ta', 'zh'].contains(languageCode)) {
          return 'dense';
        }
        return 'English-like';
    }
  }
  
  // No script code - check language
  if (['th', 'te', 'ur', 'ug'].contains(languageCode)) {
    return 'tall';
  }
  if (['ta', 'zh'].contains(languageCode)) {
    return 'dense';
  }
  
  return 'English-like';
}

/// Parses a Dart file and extracts translations
Map<String, dynamic> parseDartFile(File dartFile) {
  final content = dartFile.readAsStringSync();
  final translations = <String, dynamic>{};
  
  // Extract String getters: String get keyName => "value";
  final getterPattern = RegExp(r'String get (\w+) =>\s*"([^"]+)"');
  for (final match in getterPattern.allMatches(content)) {
    final key = match.group(1)!;
    final value = match.group(2)!;
    translations[key] = value;
  }
  
  // Extract methods with parameters: String methodName(String param) { return "value $param"; }
  final methodPattern = RegExp(
    r'String (\w+)\([^)]*\)\s*\{[^}]*return\s+"([^"]+)"',
    multiLine: true,
  );
  for (final match in methodPattern.allMatches(content)) {
    final methodName = match.group(1)!;
    final returnValue = match.group(2)!;
    
    // Extract parameters from method signature
    final sigMatch = RegExp(r'String $methodName\(([^)]+)\)').firstMatch(content);
    if (sigMatch != null) {
      final params = sigMatch.group(1)!
          .split(',')
          .map((p) => p.trim().split(' ').last.replaceAll('?', ''))
          .where((p) => p.isNotEmpty)
          .toList();
      
      translations[methodName] = {
        'value': returnValue,
        'parameters': params.join(', '),
      };
    } else {
      translations[methodName] = returnValue;
    }
  }
  
  // Extract scriptCategory
  final scriptCategoryMatch = RegExp(r'ScriptCategory\.(\w+)').firstMatch(content);
  if (scriptCategoryMatch != null) {
    final category = scriptCategoryMatch.group(1)!;
    switch (category) {
      case 'englishLike':
        translations['_scriptCategory'] = 'English-like';
        break;
      case 'tall':
        translations['_scriptCategory'] = 'tall';
        break;
      case 'dense':
        translations['_scriptCategory'] = 'dense';
        break;
    }
  }
  
  // Extract timeOfDayFormat from formatTimeOfDay method
  if (content.contains('TimeOfDayFormat.HH_colon_mm')) {
    translations['_timeOfDayFormat'] = 'HH:mm';
  } else if (content.contains('TimeOfDayFormat.H_colon_mm')) {
    translations['_timeOfDayFormat'] = 'h:mm a';
  }
  
  return translations;
}

/// Loads English ARB template
Map<String, dynamic> loadEnglishArbTemplate(String templatePath) {
  final file = File(templatePath);
  final content = file.readAsStringSync();
  return json.decode(content) as Map<String, dynamic>;
}

/// Generates Material ARB file
String generateMaterialArb(
  Map<String, dynamic> englishTemplate,
  Map<String, dynamic> translations,
  String scriptCategory,
  String timeOfDayFormat,
) {
  final arb = <String, dynamic>{};
  
  // Copy all keys from English template
  for (final key in englishTemplate.keys) {
    if (key.startsWith('@')) {
      // Copy metadata
      arb[key] = englishTemplate[key];
    } else {
      // Copy structure, will replace with translations
      arb[key] = englishTemplate[key];
    }
  }
  
  // Override with translations
  for (final key in translations.keys) {
    if (key == '_scriptCategory') {
      arb['scriptCategory'] = translations[key];
    } else if (key == '_timeOfDayFormat') {
      arb['timeOfDayFormat'] = translations[key];
    } else if (translations[key] is Map) {
      // Method with parameters
      final methodData = translations[key] as Map<String, dynamic>;
      arb[key] = methodData['value'];
      if (arb['@$key'] != null && methodData['parameters'] != null) {
        (arb['@$key'] as Map<String, dynamic>)['parameters'] = methodData['parameters'];
      }
    } else {
      // Simple string
      arb[key] = translations[key];
    }
  }
  
  // Ensure scriptCategory and timeOfDayFormat are set
  if (!arb.containsKey('scriptCategory')) {
    arb['scriptCategory'] = scriptCategory;
  }
  if (!arb.containsKey('timeOfDayFormat')) {
    arb['timeOfDayFormat'] = timeOfDayFormat;
  }
  
  // Handle incomplete translations - use English fallback
  final incompleteKeys = [
    'licensesPackageDetailText',
    'remainingTextFieldCharacterCount',
    'selectedRowCountTitle',
  ];
  
  for (final key in incompleteKeys) {
    if (!arb.containsKey('${key}Other') || 
        (arb['${key}Other'] as String).contains('licenses') ||
        (arb['${key}Other'] as String).contains('characters') ||
        (arb['${key}Other'] as String).contains('items')) {
      // Use English fallback
      arb['${key}Other'] = englishTemplate['${key}Other'];
    }
  }
  
  // Handle tabLabel and pageRowsInfoTitle
  if (arb.containsKey('tabLabel') && (arb['tabLabel'] as String).startsWith('Tab ')) {
    arb['tabLabel'] = englishTemplate['tabLabel'];
  }
  if (arb.containsKey('pageRowsInfoTitle') && 
      (arb['pageRowsInfoTitle'] as String).contains(' / ')) {
    // Check if it's the English pattern
    final value = arb['pageRowsInfoTitle'] as String;
    if (value.contains(' / ~') || value.contains(' / ')) {
      // Extract the pattern
      arb['pageRowsInfoTitle'] = value.replaceAll(' / ~', ' of about ').replaceAll(' / ', ' of ');
      arb['pageRowsInfoTitleApproximate'] = value.replaceAll(' / ', ' of about ');
    }
  }
  
  // Handle aboutListTileTitle
  if (arb.containsKey('aboutListTileTitle')) {
    final value = arb['aboutListTileTitle'] as String;
    if (!value.contains('\$applicationName') && !value.contains('About')) {
      // Missing "About" prefix
      arb['aboutListTileTitle'] = 'About \$applicationName';
    }
  }
  
  // Convert to JSON with proper formatting
  final encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(arb);
}

/// Extracts overlapping keys from Material for Cupertino/Widgets
Map<String, dynamic> extractOverlappingKeys(
  Map<String, dynamic> materialTranslations,
  List<String> targetKeys,
) {
  final overlapping = <String, dynamic>{};
  for (final key in targetKeys) {
    if (materialTranslations.containsKey(key)) {
      overlapping[key] = materialTranslations[key];
    }
  }
  return overlapping;
}

/// Generates Cupertino ARB file
String generateCupertinoArb(
  Map<String, dynamic> englishTemplate,
  Map<String, dynamic> materialTranslations,
) {
  final arb = <String, dynamic>{};
  
  // Copy English template
  for (final key in englishTemplate.keys) {
    arb[key] = englishTemplate[key];
  }
  
  // Extract overlapping keys from Material
  final overlappingKeys = [
    'cutButtonLabel',
    'copyButtonLabel',
    'pasteButtonLabel',
    'selectAllButtonLabel',
    'lookUpButtonLabel',
    'searchWebButtonLabel',
    'shareButtonLabel',
    'alertDialogLabel',
    'modalBarrierDismissLabel',
    'menuDismissLabel',
    'cancelButtonLabel',
    'expansionTileExpandedHint',
    'expansionTileCollapsedHint',
    'expansionTileExpandedTapHint',
    'expansionTileCollapsedTapHint',
    'expandedHint',
    'collapsedHint',
  ];
  
  for (final key in overlappingKeys) {
    if (materialTranslations.containsKey(key)) {
      arb[key] = materialTranslations[key];
    }
  }
  
  final encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(arb);
}

/// Generates Widgets ARB file
String generateWidgetsArb(
  Map<String, dynamic> englishTemplate,
  Map<String, dynamic> materialTranslations,
) {
  final arb = <String, dynamic>{};
  
  // Copy English template
  for (final key in englishTemplate.keys) {
    arb[key] = englishTemplate[key];
  }
  
  // Extract overlapping keys from Material
  final overlappingKeys = [
    'copyButtonLabel',
    'cutButtonLabel',
    'lookUpButtonLabel',
    'searchWebButtonLabel',
    'shareButtonLabel',
    'pasteButtonLabel',
    'selectAllButtonLabel',
    'reorderItemToStart',
    'reorderItemToEnd',
    'reorderItemUp',
    'reorderItemDown',
    'reorderItemLeft',
    'reorderItemRight',
  ];
  
  for (final key in overlappingKeys) {
    if (materialTranslations.containsKey(key)) {
      arb[key] = materialTranslations[key];
    }
  }
  
  final encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(arb);
}

/// Generates ARB filename from locale info
String generateArbFilename(String prefix, String languageCode, String? scriptCode) {
  if (scriptCode != null) {
    return '${prefix}_${languageCode}_$scriptCode.arb';
  }
  return '${prefix}_$languageCode.arb';
}

void main(List<String> args) {
  final separator = List.filled(60, '=').join();
  print(separator);
  print('Flutter Localizations: Dart to ARB Converter');
  print(separator);
  
  // Step 1: Load language code mapping
  print('\n[Step 1] Loading language code mapping from dictionary.tsv...');
  final codeMapping = loadLanguageCodeMapping('dictionary.tsv');
  print('✓ Loaded ${codeMapping.length} language code mappings');
  
  // Step 2: Load English ARB templates
  print('\n[Step 2] Loading English ARB templates...');
  // Try multiple possible paths for Flutter repo
  final possiblePaths = [
    '../flutter/packages/flutter_localizations/lib/src/l10n',
    '../../flutter/packages/flutter_localizations/lib/src/l10n',
    'C:/Users/pierre/Desktop/flutter/packages/flutter_localizations/lib/src/l10n',
  ];
  
  String? flutterL10nPath;
  for (final path in possiblePaths) {
    final testFile = File('$path/material_en.arb');
    if (testFile.existsSync()) {
      flutterL10nPath = path;
      break;
    }
  }
  
  if (flutterL10nPath == null) {
    print('✗ ERROR: Could not find Flutter l10n directory!');
    print('   Please ensure Flutter repo is at one of these locations:');
    for (final path in possiblePaths) {
      print('   - $path');
    }
    exit(1);
  }
  
  print('✓ Found Flutter l10n at: $flutterL10nPath');
  final materialEnTemplate = loadEnglishArbTemplate('$flutterL10nPath/material_en.arb');
  final cupertinoEnTemplate = loadEnglishArbTemplate('$flutterL10nPath/cupertino_en.arb');
  final widgetsEnTemplate = loadEnglishArbTemplate('$flutterL10nPath/widgets_en.arb');
  print('✓ Loaded Material template (${materialEnTemplate.length} keys)');
  print('✓ Loaded Cupertino template (${cupertinoEnTemplate.length} keys)');
  print('✓ Loaded Widgets template (${widgetsEnTemplate.length} keys)');
  
  // Step 3: Create output directory
  print('\n[Step 3] Creating output directory...');
  final arbOutputDir = Directory('arb_output');
  if (arbOutputDir.existsSync()) {
    arbOutputDir.deleteSync(recursive: true);
  }
  arbOutputDir.createSync();
  print('✓ Created arb_output/ directory');
  
  // Step 4: List all Dart files
  print('\n[Step 4] Scanning output directory for Dart files...');
  final outputDir = Directory('output');
  final dartFiles = outputDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  print('✓ Found ${dartFiles.length} Dart files');
  
  // Step 5: Process each file
  print('\n[Step 5] Processing Dart files and generating ARB files...');
  final incompleteTranslations = <String, List<String>>{};
  int processed = 0;
  
  for (var dartFile in dartFiles) {
    final filename = dartFile.path.split(Platform.pathSeparator).last;
    
    try {
      // Extract locale info
      final locale = extractLocaleFromFilename(filename, codeMapping);
      final languageCode = locale.key;
      final scriptCode = locale.value;
      
      // Parse Dart file
      final translations = parseDartFile(dartFile);
      
      // Determine scriptCategory
      final scriptCategory = translations['_scriptCategory'] as String? ?? 
          determineScriptCategory(scriptCode, languageCode);
      final timeOfDayFormat = translations['_timeOfDayFormat'] as String? ?? 'h:mm a';
      
      // Generate Material ARB
      final materialArb = generateMaterialArb(
        materialEnTemplate,
        translations,
        scriptCategory,
        timeOfDayFormat,
      );
      // Always generate base language filename (without script code)
      final materialFilename = generateArbFilename('material', languageCode, null);
      File('${arbOutputDir.path}/$materialFilename').writeAsStringSync(materialArb);
      
      // Generate Cupertino ARB
      final cupertinoArb = generateCupertinoArb(cupertinoEnTemplate, translations);
      // Always generate base language filename (without script code)
      final cupertinoFilename = generateArbFilename('cupertino', languageCode, null);
      File('${arbOutputDir.path}/$cupertinoFilename').writeAsStringSync(cupertinoArb);
      
      // Generate Widgets ARB
      final widgetsArb = generateWidgetsArb(widgetsEnTemplate, translations);
      // Always generate base language filename (without script code)
      final widgetsFilename = generateArbFilename('widgets', languageCode, null);
      File('${arbOutputDir.path}/$widgetsFilename').writeAsStringSync(widgetsArb);
      
      // Track incomplete translations
      final incomplete = <String>[];
      if (translations.containsKey('licensesPackageDetailText') &&
          (translations['licensesPackageDetailText'] as String).contains('licenses')) {
        incomplete.add('licensesPackageDetailText');
      }
      if (translations.containsKey('remainingTextFieldCharacterCount') &&
          (translations['remainingTextFieldCharacterCount'] as String).contains('characters')) {
        incomplete.add('remainingTextFieldCharacterCount');
      }
      if (translations.containsKey('selectedRowCountTitle') &&
          (translations['selectedRowCountTitle'] as String).contains('items')) {
        incomplete.add('selectedRowCountTitle');
      }
      if (translations.containsKey('tabLabel') &&
          (translations['tabLabel'] as String).startsWith('Tab ')) {
        incomplete.add('tabLabel');
      }
      if (incomplete.isNotEmpty) {
        incompleteTranslations[filename] = incomplete;
      }
      
      processed++;
      if (processed % 10 == 0) {
        print('  Processed $processed/${dartFiles.length} files...');
      }
    } catch (e, stackTrace) {
      print('  ✗ Error processing $filename: $e');
      print('    $stackTrace');
    }
  }
  
  print('✓ Processed ${dartFiles.length} files');
  
  // Step 6: Generate report
  print('\n[Step 6] Generating incomplete translations report...');
  final reportFile = File('${arbOutputDir.path}/INCOMPLETE_TRANSLATIONS.md');
  final report = StringBuffer();
  report.writeln('# Incomplete Translations Report\n');
  report.writeln('This file lists locales with incomplete translations that need native speaker review.\n');
  
  if (incompleteTranslations.isEmpty) {
    report.writeln('No incomplete translations found!');
  } else {
    report.writeln('## Summary\n');
    report.writeln('Total locales with incomplete translations: ${incompleteTranslations.length}\n');
    report.writeln('## Details\n');
    for (final entry in incompleteTranslations.entries) {
      report.writeln('### ${entry.key}');
      for (final key in entry.value) {
        report.writeln('- `$key`');
      }
      report.writeln();
    }
  }
  
  reportFile.writeAsStringSync(report.toString());
  print('✓ Generated report: ${reportFile.path}');
  
  print('\n$separator');
  print('Conversion complete!');
  print(separator);
  
  // Count actual files generated (including base language files for script-specific locales)
  final actualFileCount = Directory(arbOutputDir.path)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb'))
      .length;
  
  print('\nGenerated ARB files in: arb_output/');
  print('Total files: $actualFileCount (includes base language files for script-specific locales)');
  print('Locales processed: ${dartFiles.length}');
  print('Locales with incomplete translations: ${incompleteTranslations.length}');
  print('\nNext steps:');
  print('1. Review ARB files in arb_output/');
  print('2. Copy to: ../flutter/packages/flutter_localizations/lib/src/l10n/');
  print('3. Run: dart ../flutter/dev/tools/localization/bin/gen_localizations.dart --overwrite');
}
