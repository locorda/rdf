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
/// When the table exceeds [maxSize], older entries are evicted to make room.
class JellyLookupTable {
  final int maxSize;
  final Map<int, String> _entries = {};
  int _lastId = 0;

  JellyLookupTable(this.maxSize);

  /// Resolves a raw ID (which may be 0 for delta encoding) to the actual ID,
  /// sets it in the table with the given [value], and returns the resolved ID.
  int set(int rawId, String value) {
    final resolvedId = rawId == 0 ? _lastId + 1 : rawId;
    _lastId = resolvedId;

    // Evict if at capacity and this is a new entry
    if (!_entries.containsKey(resolvedId) && _entries.length >= maxSize) {
      // Remove the oldest entry (lowest ID that's still present).
      // In practice, eviction policy is implementation-defined per spec.
      final oldestId = _entries.keys.reduce((a, b) => a < b ? a : b);
      _entries.remove(oldestId);
    }

    _entries[resolvedId] = value;
    return resolvedId;
  }

  /// Looks up a value by resolved (1-based) ID.
  ///
  /// Returns null if the ID is not in the table.
  String? get(int id) => _entries[id];

  /// Returns the last resolved ID.
  int get lastId => _lastId;

  /// Clears all entries and resets the last-ID counter.
  void clear() {
    _entries.clear();
    _lastId = 0;
  }
}
