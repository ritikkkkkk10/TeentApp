import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/booked_item_model.dart';
import '../models/booking_service_model.dart';

class BookingRepository {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final String businessId = "demo_business";

  Future<void> createBooking(
      BookingModel booking) async {

    await _firestore
        .collection("businesses")
        .doc(businessId)
        .collection("bookings")
        .doc(booking.id)
        .set(booking.toMap());
  }

  Future<void> addBookedItem({
  required String bookingId,
  required BookedItemModel item,
}) async {

  final bookedItemsRef = _firestore
      .collection("businesses")
      .doc(businessId)
      .collection("bookings")
      .doc(bookingId)
      .collection("bookedItems");

  /// 🔎 Check if item already exists
  final existing = await bookedItemsRef
      .where(
        "inventoryItemId",
        isEqualTo: item.inventoryItemId,
      )
      .get();

  /// ===============================
  /// ITEM EXISTS → UPDATE
  /// ===============================
  if (existing.docs.isNotEmpty) {

    final doc = existing.docs.first;

    int oldQty =
        doc["requestedQuantity"];

    int oldShortage =
        doc["shortageQuantity"];

    await doc.reference.update({
      "requestedQuantity":
          oldQty + item.requestedQuantity,

      "shortageQuantity":
          oldShortage +
              item.shortageQuantity,
    });

  }
  /// ===============================
  /// NEW ITEM → CREATE
  /// ===============================
  else {

    await bookedItemsRef
        .doc(item.id)
        .set(item.toMap());
  }
}

Future<void> addBookingService({
  required String bookingId,
  required BookingServiceModel service,
}) async {

  final serviceRef = _firestore
      .collection("businesses")
      .doc(businessId)
      .collection("bookings")
      .doc(bookingId)
      .collection("bookingServices");

  /// 🔎 Check if service already exists
  final existing = await serviceRef
      .where("serviceId", isEqualTo: service.serviceId)
      .get();

  /// If already exists → do nothing
  if (existing.docs.isNotEmpty) {
    return;
  }

  /// Else → create
  await serviceRef
      .doc(service.id)
      .set(service.toMap());
}
}