enum EnvironmentType { cloud, selfHosted }

class EnvironmentProfile {
  final String id;
  final String name;
  final EnvironmentType type;
  final String? serverUrl;
  final DateTime createdAt;
  DateTime lastUsedAt;

  EnvironmentProfile({
    required this.id,
    required this.name,
    required this.type,
    this.serverUrl,
    required this.createdAt,
    DateTime? lastUsedAt,
  }) : lastUsedAt = lastUsedAt ?? createdAt;

  bool get isCloud => type == EnvironmentType.cloud;
  bool get isSelfHosted => type == EnvironmentType.selfHosted;

  factory EnvironmentProfile.cloud() => EnvironmentProfile(
    id: 'cloud',
    name: 'Cloud',
    type: EnvironmentType.cloud,
    createdAt: DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'serverUrl': serverUrl,
    'createdAt': createdAt.toIso8601String(),
    'lastUsedAt': lastUsedAt.toIso8601String(),
  };

  factory EnvironmentProfile.fromJson(Map<String, dynamic> json) => EnvironmentProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    type: EnvironmentType.values.byName(json['type'] as String),
    serverUrl: json['serverUrl'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastUsedAt: DateTime.tryParse(json['lastUsedAt'] as String? ?? ''),
  );

  EnvironmentProfile copyWith({
    String? name,
    EnvironmentType? type,
    String? serverUrl,
    DateTime? lastUsedAt,
  }) => EnvironmentProfile(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    serverUrl: serverUrl ?? this.serverUrl,
    createdAt: createdAt,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
  );
}
