import 'package:cloud_firestore/cloud_firestore.dart';

class BookedItemModel {
  final String id;
  final String inventoryItemId;
  final String itemName;

  final int requestedQuantity;
  final int availableQuantityAtBooking;
  final int shortageQuantity;

  final double rentPriceSnapshot;
  final Timestamp createdAt;

  BookedItemModel({
    required this.id,
    required this.inventoryItemId,
    required this.itemName,
    required this.requestedQuantity,
    required this.availableQuantityAtBooking,
    required this.shortageQuantity,
    required this.rentPriceSnapshot,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "inventoryItemId": inventoryItemId,
      "itemName": itemName,
      "requestedQuantity": requestedQuantity,
      "availableQuantityAtBooking":
          availableQuantityAtBooking,
      "shortageQuantity": shortageQuantity,
      "rentPriceSnapshot": rentPriceSnapshot,
      "createdAt": createdAt,
    };
  }
}