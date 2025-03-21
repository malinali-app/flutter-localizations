import 'dart:convert';
import 'dart:io';

import 'ending.dart';

main() async {
  Directory('output').createSync();
  Directory('input').createSync();

  for (final file in Directory('input').listSync()) {
    final sb = StringBuffer();
    sb.write('''import 'package:flutter/material.dart';
class CustomMaterialLocalizations extends MaterialLocalizations {''');
    final contents = File(file.path).readAsStringSync();
    final jsonPhrases = json.decode(contents) as Map<String, dynamic>;
    for (final phrase in jsonPhrases.entries) {
      switch (phrase.key) {
        case 'licensesPackageDetailText':
          sb.write('''
  @override
  String licensesPackageDetailText(int licenseCount) {
    return '${phrase.value}';
  }
''');
          break;
        case 'remainingTextFieldCharacterCount':
          sb.write('''
  @override
  String remainingTextFieldCharacterCount(int remaining) {
    return '${phrase.value}';
  }
''');
          break;
        case 'scrimOnTapHint':
          sb.write('''
  @override
          String scrimOnTapHint(String modalRouteContentName) {
            return '${phrase.value}';
          }
''');
          break;
        case 'selectedRowCountTitle':
          sb.write('''
 @override
  String selectedRowCountTitle(int selectedRowCount) {
    return '${phrase.value}';
  }
''');
          break;
        case 'aboutListTileTitle':
          sb.write(''' @override
  String aboutListTileTitle(String applicationName) {
    return '\$applicationName';
  }''');
          break;

        case 'dateRangeEndDateSemanticLabel':
          sb.write('''
    @override
  String dateRangeEndDateSemanticLabel(String formattedDate) {
    return "${phrase.value}";
  }''');
          break;

        case 'dateRangeStartDateSemanticLabel':
          sb.write('''
    @override
  String dateRangeStartDateSemanticLabel(String formattedDate) {
    return "${phrase.value}";
  }''');
          break;

        case 'pageRowsInfoTitle':
          break;
        case 'tabLabel':
          break;

        default:
          sb.write('@override\n');
          sb.write('String get ${phrase.key} => "${phrase.value}" ;');
          break;
      }
    }

// passing standard end
    sb.write(ending);
    final name = file.path.split(Platform.pathSeparator).last.split('.').first;
    File('output/$name.dart').writeAsStringSync(sb.toString());
    sb.clear();
  }
}
