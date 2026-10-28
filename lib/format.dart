const weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const shortWeekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

String weekdayName(DateTime value) => weekdays[value.weekday - 1];

String monthName(DateTime value) => months[value.month - 1];

String friendlyDate(DateTime value) =>
    '${weekdayName(value)}, ${monthName(value)} ${value.day}';

String shortDate(DateTime value) =>
    '${value.month}/${value.day}/${value.year}';

String friendlyTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool inLast7Days(DateTime at, DateTime now) {
  final start = dateOnly(now).subtract(const Duration(days: 6));
  final day = dateOnly(at);
  return !day.isBefore(start) && !day.isAfter(dateOnly(now));
}

String csvField(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

const moodOptions = ['Very low', 'Low', 'Okay', 'Good', 'Steady'];

const useOptions = [
  'No',
  'Alcohol',
  'Other drugs',
  'Both',
  'Prefer not to say',
];

const contextOptions = [
  'Alone',
  'With a peer',
  'With friends',
  'With family',
  'Home',
  'Work',
];

const intentOptions = ['None', 'Slight', 'Moderate', 'Strong'];

const goalOptions = ['Yes', 'Partly', 'Not today'];

const presenceOptions = ['Yes, I am here', 'Not anymore', 'Wrong place'];

int moodScore(String? mood) => switch (mood) {
      'Very low' => 1,
      'Low' => 2,
      'Okay' => 3,
      'Good' => 4,
      'Steady' => 5,
      _ => 0,
    };

bool reportedUse(String? use) =>
    use == 'Alcohol' || use == 'Other drugs' || use == 'Both';
