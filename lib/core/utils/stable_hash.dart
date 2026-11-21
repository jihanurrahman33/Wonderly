/// Deterministic 32-bit FNV-1a hash, used for stable content ids.
///
/// `String.hashCode` is not stable between runs, so it cannot be used for ids
/// that are stored on disk.
abstract final class StableHash {
  static String of(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
