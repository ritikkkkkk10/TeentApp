import 'package:cloud_firestore/cloud_firestore.dart';

class BookedItemModel {
  final String id;
  final String inventoryItemId;
  final String itemName;

  final bool isManual;

  final int requestedQuantity;
  final int availableQuantityAtBooking;
  final int shortageQuantity;

  final int dispatchedQuantity; // ✅ NEW FIELD
  final String bookingId; // ✅ ADD THIS

  final int receivedQuantity;
  final int missingQuantity;

  final double rentPriceSnapshot;
  final Timestamp createdAt;

  final DateTime bookingStartDate;
  final DateTime bookingEndDate;

  final String? businessId;
  

  BookedItemModel({
    required this.id,
    required this.inventoryItemId,
    required this.itemName,
    this.isManual = false,
    required this.requestedQuantity,
    required this.availableQuantityAtBooking,
    required this.shortageQuantity,
    required this.rentPriceSnapshot,
    required this.createdAt,
    required this.bookingStartDate,
    required this.bookingEndDate,
    this.businessId,
    required this.bookingId, // ✅ ADD
    this.dispatchedQuantity = 0,
    this.receivedQuantity = 0,
    this.missingQuantity = 0, // ✅ default
  });

  Map<String, dynamic> toMap() {
    return {
      "inventoryItemId": inventoryItemId,
      "itemName": itemName,
      "isManual": isManual,
      "requestedQuantity": requestedQuantity,
      "dispatchedQuantity": dispatchedQuantity, // ✅ NEW
      "availableQuantityAtBooking": availableQuantityAtBooking,
      "shortageQuantity": shortageQuantity,
      "rentPriceSnapshot": rentPriceSnapshot,
      "createdAt": createdAt,
      "bookingStartDate": Timestamp.fromDate(bookingStartDate),
      "bookingEndDate": Timestamp.fromDate(bookingEndDate),
      "receivedQuantity": receivedQuantity,
      "missingQuantity": missingQuantity,
      "bookingId": bookingId, // ✅ ADD
      "id": id,
      "businessId": businessId,
    };
  }
}
