import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/app_config.dart';
import '../models/inventory_node.dart';

class InventoryService {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  /// ADD CATEGORY
  Future<void> addCategory({
    required String name,
    String? parentId,
  }) async {

    String businessId = await getBusinessId();

    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('inventoryNodes')
        .add({
      'name': name,
      'type': 'category',
      'parentId': parentId,
      'createdAt': Timestamp.now(),
    });
  }

  /// ADD ITEM
  Future<void> addItem({
  required String name,
  required int quantity,
  required double rentPrice,
  String? parentId,
  String? description,
  String? imageUrl,
}) async {

    String businessId = await getBusinessId();

    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('inventoryNodes')
        .add({
      'name': name,
      'type': 'item',
      'parentId': parentId,
      'quantity': quantity,
      'rentPrice': rentPrice,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.now(),
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

  await _firestore
      .collection('businesses')
      .doc(businessId)
      .collection('inventoryNodes')
      .add({
    'name': name,
    'type': 'service',
    'parentId': parentId,
    'price': price,
    'description': description,
    'imageUrls': imageUrls,
    'createdAt': Timestamp.now(),
  });
}
}