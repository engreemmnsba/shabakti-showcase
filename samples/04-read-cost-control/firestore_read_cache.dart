// Shabakti — public code sample (copied verbatim from the private repository).
// Tiny TTL cache for slow-changing collections (areas, sections, roles).
// Some inline comments are in Arabic.

/// ذاكرة مؤقتة بسيطة لنتائج Firestore الثابتة نسبياً (مناطق، أقسام، أدوار).
class FirestoreReadCache {
  FirestoreReadCache._();
  static final FirestoreReadCache instance = FirestoreReadCache._();

  final Map<String, _CacheEntry> _entries = {};

  Future<T> getOrFetch<T>(
    String key,
    Duration ttl,
    Future<T> Function() fetch,
  ) async {
    final now = DateTime.now();
    final hit = _entries[key];
    if (hit != null && now.isBefore(hit.expiresAt)) {
      return hit.value as T;
    }
    final value = await fetch();
    _entries[key] = _CacheEntry(value, now.add(ttl));
    return value;
  }

  void invalidatePrefix(String prefix) {
    _entries.removeWhere((k, _) => k.startsWith(prefix));
  }

  void clear() => _entries.clear();
}

class _CacheEntry {
  final Object? value;
  final DateTime expiresAt;
  _CacheEntry(this.value, this.expiresAt);
}
