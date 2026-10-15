// Shabakti — public code sample (copied verbatim from the private repository).
// Role model: permissions stored as a list or a map of flags.
// Some inline comments are in Arabic.

class RoleModel {
  String? id;
  String? name;
  List<String> permissions;
  bool active;

  RoleModel({
    this.id,
    this.name,
    this.permissions = const [],
    this.active = true,
  });

  static List<String> _parsePermissions(dynamic rawPerms) {
    final perms = <String>[];
    if (rawPerms is List) {
      for (final p in rawPerms) {
        if (p is String && p.trim().isNotEmpty) perms.add(p.trim());
      }
      return perms;
    }
    if (rawPerms is Map) {
      for (final entry in rawPerms.entries) {
        final key = entry.key;
        if (key is! String || key.trim().isEmpty) continue;
        final value = entry.value;
        if (value == true || value == 1 || value == 'true') {
          perms.add(key.trim());
        }
      }
    }
    return perms;
  }

  factory RoleModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return RoleModel(
      id: (map['id'] as String?) ?? docId,
      name: map['name'] as String?,
      permissions: _parsePermissions(map['permissions']),
      active: (map['active'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'permissions': permissions,
      'active': active,
    };
  }
}
