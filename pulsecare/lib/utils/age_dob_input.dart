import 'package:flutter/services.dart';

class AgeOrDobInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);

    if (digits.length <= 2 && !newValue.text.contains('/')) {
      return TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }

    final parts = <String>[];
    if (digits.isNotEmpty) {
      parts.add(digits.substring(0, digits.length.clamp(0, 2)));
    }
    if (digits.length > 2) {
      parts.add(digits.substring(2, digits.length.clamp(2, 4)));
    }
    if (digits.length > 4) {
      parts.add(digits.substring(4, digits.length.clamp(4, 8)));
    }

    final formatted = parts.join('/');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

DateTime? parseTypedDob(String text, {DateTime? now}) {
  final match = RegExp(r'^(\d{2})\/(\d{2})\/(\d{4})$').firstMatch(text);
  if (match == null) return null;

  final day = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  final year = int.tryParse(match.group(3)!);
  if (day == null || month == null || year == null) return null;

  final candidate = DateTime(year, month, day);
  final isValidDate =
      candidate.year == year &&
      candidate.month == month &&
      candidate.day == day;
  if (!isValidDate) return null;

  final currentDate = now ?? DateTime.now();
  if (candidate.isAfter(currentDate) || year < 1900) return null;
  return candidate;
}

int calculateAgeFromDob(DateTime dob, {DateTime? now}) {
  final currentDate = now ?? DateTime.now();
  var age = currentDate.year - dob.year;
  final hadBirthday =
      currentDate.month > dob.month ||
      (currentDate.month == dob.month && currentDate.day >= dob.day);
  if (!hadBirthday) age -= 1;
  return age;
}

int? parseAgeInput(String text, {DateTime? now}) {
  final value = text.trim();
  if (value.isEmpty) return null;

  final numericAge = int.tryParse(value);
  if (numericAge != null) {
    if (numericAge < 1 || numericAge > 120) return null;
    return numericAge;
  }

  final dob = parseTypedDob(value, now: now);
  if (dob == null) return null;
  return calculateAgeFromDob(dob, now: now);
}

DateTime resolveAgePickerInitialDate(
  String text, {
  DateTime? lastDobFromInput,
  DateTime? now,
}) {
  final currentDate = now ?? DateTime.now();
  final typedDob = parseTypedDob(text.trim(), now: currentDate);
  if (typedDob != null) return typedDob;
  if (lastDobFromInput != null) return lastDobFromInput;

  final typedAge = int.tryParse(text.trim());
  if (typedAge != null && typedAge >= 1 && typedAge <= 120) {
    return DateTime(
      currentDate.year - typedAge,
      currentDate.month,
      currentDate.day,
    );
  }

  return DateTime(currentDate.year - 20, currentDate.month, currentDate.day);
}

String formatDob(DateTime dob) {
  final day = dob.day.toString().padLeft(2, '0');
  final month = dob.month.toString().padLeft(2, '0');
  return '$day/$month/${dob.year}';
}
