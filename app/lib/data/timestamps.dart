/// The millisecond range representable by Dart DateTime.
const maxTimestampMillis = 8640000000000000;

bool validTimestampMillis(int value) =>
    value >= -maxTimestampMillis && value <= maxTimestampMillis;

final class TimestampRangeException implements Exception {
  const TimestampRangeException();
}

/// Advance a user version without wrapping or creating an unreadable version.
int nextTimestampMillis(int now, int previous) {
  if (!validTimestampMillis(now) ||
      !validTimestampMillis(previous) ||
      previous == maxTimestampMillis) {
    throw const TimestampRangeException();
  }
  return now > previous ? now : previous + 1;
}
