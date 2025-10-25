class Collection {
  final String id;
  final String name;
  final String description;
  final String userId;
  final List<String> productIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Collection({
    required this.id,
    required this.name,
    required this.description,
    required this.userId,
    required this.productIds,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'userId': userId,
      'productIds': productIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Collection.fromMap(Map<String, dynamic> map) {
    return Collection(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      userId: map['userId'] ?? '',
      productIds: List<String>.from(map['productIds'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
