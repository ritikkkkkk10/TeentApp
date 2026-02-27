class InventoryNode {
  final String id;
  final String name;
  final String type; // category or item
  final String? parentId;

  /// Item fields (optional for categories)
  final int? quantity;
  final double? rentPrice;
  final String? description;
  final String? spec1;
  final String? spec2;
  final String? spec3;
  final String? imageUrl;

  InventoryNode({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
    this.quantity,
    this.rentPrice,
    this.description,
    this.spec1,
    this.spec2,
    this.spec3,
    this.imageUrl,
  });

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'parentId': parentId,
      'quantity': quantity,
      'rentPrice': rentPrice,
      'description': description,
      'spec1': spec1,
      'spec2': spec2,
      'spec3': spec3,
      'imageUrl': imageUrl,
    };
  }

  /// Convert from Firestore
  factory InventoryNode.fromMap(
      String id, Map<String, dynamic> map) {
    return InventoryNode(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? 'category',
      parentId: map['parentId'],
      quantity: map['quantity'],
      rentPrice:
          (map['rentPrice'] ?? 0).toDouble(),
      description: map['description'],
      spec1: map['spec1'],
      spec2: map['spec2'],
      spec3: map['spec3'],
      imageUrl: map['imageUrl'],
    );
  }
}