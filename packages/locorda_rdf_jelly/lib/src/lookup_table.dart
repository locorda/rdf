/// Jelly RDF lookup table implementation.
///
/// Manages the three lookup tables (prefix, name, datatype) used by the Jelly
/// serialization format for IRI and datatype compression.
library;

/// A fixed-capacity lookup table mapping 1-based integer IDs to string values.
///
/// Supports the Jelly "delta ID" convention: when an ID of 0 is encountered,
/// it is interpreted as (previous ID + 1), or 1 for the first entry.
///
/// IDs are always in [1, maxSize] — the encoder recycles IDs within this
/// range once the table is full. A [List] indexed directly by ID gives O(1)
/// set/get and makes eviction implicit (overwriting an occupied slot). This
/// avoids the O(n) minimum-key scan that a HashMap approach requires.
class JellyLookupTable {
  final int maxSize;
  // 1-indexed: index 0 is always null; valid IDs are 1..maxSize.
  final List<String?> _entries;
  int _lastId = 0;

  JellyLookupTable(this.maxSize) : _entries = List.filled(maxSize + 1, null);

  /// Resolves [rawId] (0 = delta: lastId + 1), stores [value] at that slot,
  /// and returns the resolved ID.
  ///
  /// Overwriting an existing slot implicitly evicts the old entry — no linear
  /// scan is required.
  int set(int rawId, String value) {
    final resolvedId = rawId == 0 ? _lastId + 1 : rawId;
    _lastId = resolvedId;
    _entries[resolvedId] = value;
    return resolvedId;
  }

  /// Looks up a value by 1-based [id].
  ///
  /// Returns null for out-of-range IDs or empty slots.
  String? get(int id) {
    if (id <= 0 || id > maxSize) return null;
    return _entries[id];
  }

  /// Returns the last resolved ID.
  int get lastId => _lastId;

  /// Clears all entries and resets the last-ID counter.
  void clear() {
    _entries.fillRange(0, _entries.length, null);
    _lastId = 0;
  }
}
