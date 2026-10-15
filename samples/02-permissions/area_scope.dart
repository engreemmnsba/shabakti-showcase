// Shabakti — public code sample (copied verbatim from the private repository).
// Per-user area scope: one area, several areas, or all (SCOPE_ALL).
// Some inline comments are in Arabic.

/// نطاق المناطق للمستخدم: واحدة، عدة، أو الكل (`SCOPE_ALL`).
class AreaScope {
  final String primaryAreaId;
  final List<String> areaIds;
  final Set<String> permissions;

  const AreaScope({
    this.primaryAreaId = '',
    this.areaIds = const [],
    this.permissions = const {},
  });

  static List<String> parseAreaIdsFromMap(Map<String, dynamic>? data) {
    if (data == null) return const [];
    final raw = data['areaIds'];
    if (raw is List) {
      final out = raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (out.isNotEmpty) return out;
    }
    final single = (data['areaId'] as String?)?.trim() ?? '';
    if (single.isNotEmpty) return [single];
    return const [];
  }

  factory AreaScope.fromFields({
    String? areaId,
    List<String>? areaIds,
    Set<String> permissions = const {},
  }) {
    final ids = (areaIds ?? const [])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (ids.isEmpty) {
      final single = (areaId ?? '').trim();
      if (single.isNotEmpty) {
        return AreaScope(
          primaryAreaId: single,
          areaIds: [single],
          permissions: permissions,
        );
      }
      return AreaScope(permissions: permissions);
    }
    final primary = (areaId ?? '').trim();
    return AreaScope(
      primaryAreaId: primary.isNotEmpty ? primary : ids.first,
      areaIds: ids,
      permissions: permissions,
    );
  }

  bool get hasScopeAll => permissions.contains('SCOPE_ALL');

  /// مناطق مسموحة — فاضي مع `SCOPE_ALL` = الكل.
  List<String> get effectiveAreaIds {
    if (hasScopeAll) return const [];
    return areaIds;
  }

  bool get seesAllAreas => hasScopeAll;

  bool get isMultiArea => !hasScopeAll && areaIds.length > 1;

  bool get isSingleArea => !hasScopeAll && areaIds.length == 1;

  bool canAccessArea(String? areaId) {
    if (hasScopeAll) return true;
    final id = (areaId ?? '').trim();
    if (id.isEmpty) return false;
    if (areaIds.isEmpty) return false;
    return areaIds.contains(id);
  }

  bool matchesArea(String? areaId) => canAccessArea(areaId);
}
