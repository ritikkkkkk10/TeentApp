import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/app_config.dart';
import '../models/inventory_node.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> nodeExists({
  required String name,
  required String type,
  required String? parentId,
}) async {

  String businessId = await getBusinessId();
  final nameLower = name.trim().toLowerCase();

  final snapshot = await FirebaseFirestore.instance
      .collection('businesses')
      .doc(businessId)
      .collection('inventoryNodes')
      .where('parentId', isEqualTo: parentId)
      .where('type', isEqualTo: type)
      .get();

  for (var doc in snapshot.docs) {
    final data = doc.data();

    final existingName =
        (data['nameLower'] ?? data['name'] ?? "").toString().toLowerCase();

    if (existingName == nameLower) {
      return true;
    }
  }

  return false;
}

  /// ADD CATEGORY
  Future<void> addCategory({
  required String name,
  required String? parentId,
}) async {

  String businessId = await getBusinessId();
  final nameLower = name.trim().toLowerCase();

  final exists = await nodeExists(
    name: name,
    type: "category",
    parentId: parentId,
  );

  if (exists) {
    throw Exception("Category already exists");
  }

  await FirebaseFirestore.instance
      .collection('businesses')
      .doc(businessId)
      .collection('inventoryNodes')
      .add({
    "name": name.trim(),
    "nameLower": nameLower,
    "type": "category",
    "parentId": parentId,
    "createdAt": FieldValue.serverTimestamp(),
  });
}

  /// ADD ITEM
  Future<void> addItem({
  required String name,
  required int quantity,
  required double rentPrice,
  required String? parentId,
  required String description,
  required String? imageUrl,
}) async {

  String businessId = await getBusinessId();
  final nameLower = name.trim().toLowerCase();

  final exists = await nodeExists(
    name: name,
    type: "item",
    parentId: parentId,
  );

  if (exists) {
    throw Exception("Item already exists");
  }

  await FirebaseFirestore.instance
      .collection('businesses')
      .doc(businessId)
      .collection('inventoryNodes')
      .add({
    "name": name.trim(),
    "nameLower": nameLower,
    "type": "item",
    "parentId": parentId,
    "quantity": quantity,
    "rentPrice": rentPrice,
    "description": description,
    "imageUrl": imageUrl,
    "createdAt": FieldValue.serverTimestamp(),
  });
}

  /// ADD SERVICE
  Future<void> addService({
  required String name,
  required double price,
  required String description,
  required List<String> imageUrls,
  String? parentId,
}) async {

  String businessId = await getBusinessId();
  final nameLower = name.trim().toLowerCase();

  final exists = await nodeExists(
    name: name,
    type: "service",
    parentId: parentId,
  );

  if (exists) {
    throw Exception("Service already exists");
  }

  await _firestore
      .collection('businesses')
      .doc(businessId)
      .collection('inventoryNodes')
      .add({
    'name': name.trim(),
    'nameLower': nameLower,
    'type': 'service',
    'parentId': parentId,
    'price': price,
    'description': description,
    'imageUrls': imageUrls,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
}
