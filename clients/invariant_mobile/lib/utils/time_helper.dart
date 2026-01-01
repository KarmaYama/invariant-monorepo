// clients/invariant_mobile/lib/utils/time_helper.dart
class TimeHelper {
  /// Returns an ISO-8601 string in UTC, but forces the Rust-compatible
  /// `+00:00` offset suffix instead of `Z`.
  static String canonicalUtcTimestamp() {
    String ts = DateTime.now().toUtc().toIso8601String();
    return ts.endsWith('Z')
        ? "${ts.substring(0, ts.length - 1)}+00:00"
        : ts;
  }
}