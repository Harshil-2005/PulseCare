import 'package:intl/intl.dart';

class TimeUtils {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateTimeFormat =
      DateFormat('dd/MM/yyyy hh:mm a');

  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  static DateTime parseDateTime(String date, String time) {
    return _dateTimeFormat.parse('$date $time');
  }

  static DateTime parseTime(String time) {
    final format = DateFormat('hh:mm a');
    return format.parse(time);
  }

  static DateTime parseDateStrict(String date) {
    final format = DateFormat('dd/MM/yyyy');
    return format.parseStrict(date);
  }
}
