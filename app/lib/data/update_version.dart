/// A stable release version, ignoring an optional `v` prefix and build number.
final class UpdateVersion implements Comparable<UpdateVersion> {
  const UpdateVersion(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  static UpdateVersion? parse(String value) {
    final match = RegExp(
      r'^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:\+\d+)?$',
    ).firstMatch(value);
    if (match == null) return null;
    final major = int.tryParse(match[1]!);
    final minor = int.tryParse(match[2]!);
    final patch = int.tryParse(match[3]!);
    if (major == null || minor == null || patch == null) return null;
    return UpdateVersion(major, minor, patch);
  }

  @override
  int compareTo(UpdateVersion other) {
    final first = major.compareTo(other.major);
    if (first != 0) return first;
    final second = minor.compareTo(other.minor);
    return second != 0 ? second : patch.compareTo(other.patch);
  }
}
