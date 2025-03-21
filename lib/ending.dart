const ending = '''
  
  @override
  String pageRowsInfoTitle(
      int firstRow, int lastRow, int rowCount, bool rowCountIsApproximate) {
    if (rowCountIsApproximate) {
      return '\$firstRow–\$lastRow / ~\$rowCount';
    } else {
      return '\$firstRow–\$lastRow / \$rowCount';
    }
  }

    @override
  String get dateSeparator => '/';


  @override
  String tabLabel({required int tabIndex, required int tabCount}) {
    return 'Tab \$tabIndex of \$tabCount';
  }


  @override
  int get firstDayOfWeekIndex =>
      0; // Assuming Monday as the first day of the week

  @override
  String formatCompactDate(DateTime date) {
    return '\${date.day}/\${date.month}/\${date.year}';
  }

  @override
  String formatDecimal(int number) {
    return number.toString();
  }

  @override
  String formatFullDate(DateTime date) {
    return '\${date.day}/\${date.month}/\${date.year}';
  }

  @override
  String formatHour(TimeOfDay timeOfDay, {bool alwaysUse24HourFormat = false}) {
    final hour = alwaysUse24HourFormat
        ? timeOfDay.hour
        : (timeOfDay.hour % 12 == 0 ? 12 : timeOfDay.hour % 12);
    return hour.toString();
  }

  @override
  String formatMediumDate(DateTime date) {
    return '\${date.day}/\${date.month}/\${date.year}';
  }

  @override
  String formatMinute(TimeOfDay timeOfDay) {
    return timeOfDay.minute.toString().padLeft(2, '0');
  }

  @override
  String formatMonthYear(DateTime date) {
    return '\${date.month}/\${date.year}';
  }

  @override
  String formatShortDate(DateTime date) {
    return '/\${date.day}\${date.month}/\${date.year}';
  }

  @override
  String formatShortMonthDay(DateTime date) {
    return '\${date.day}/\${date.month}';
  }


  @override
  String licensesPackageDetailText(int licenseCount) {
    return '\$licenseCount licenses';
  }

    @override
  String remainingTextFieldCharacterCount(int remaining) {
    return '\$remaining characters remaining';
  }

    @override
  String selectedRowCountTitle(int selectedRowCount) {
    return '\$selectedRowCount items selected';
  }

    @override
  TimeOfDayFormat timeOfDayFormat({bool alwaysUse24HourFormat = false}) {
    return alwaysUse24HourFormat
        ? TimeOfDayFormat.HH_colon_mm
        : TimeOfDayFormat.H_colon_mm;
  }

 @override
  DateTime? parseCompactDate(String? inputString) {
    if (inputString == null || inputString.isEmpty) return null;
    final parts = inputString.split('/');
    if (parts.length != 3) return null;
    final month = int.tryParse(parts[0]);
    final day = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (month == null || day == null || year == null) return null;
    return DateTime(year, month, day);
  }

  @override
  ScriptCategory get scriptCategory => ScriptCategory.englishLike;

  // edited European style
  @override
  List<String> get narrowWeekdays => ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

   @override
  String formatYear(DateTime date) {
    return date.year.toString();
  }

  @override
  String formatTimeOfDay(TimeOfDay timeOfDay,
      {bool alwaysUse24HourFormat = false}) {
    final hour = alwaysUse24HourFormat
        ? timeOfDay.hour
        : (timeOfDay.hour % 12 == 0 ? 12 : timeOfDay.hour % 12);
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    final period = alwaysUse24HourFormat
        ? ''
        : (timeOfDay.period == DayPeriod.am ? ' AM' : ' PM');
    return '\$hour:\$minute\$period';
  }
}
''';
