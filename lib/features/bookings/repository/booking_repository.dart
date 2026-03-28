import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tent_app/core/config/app_config.dart';

import '../models/booking_model.dart';
import '../models/booked_item_model.dart';
import '../models/booking_service_model.dart';

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ===============================
  /// CREATE BOOKING
  /// ===============================
  Future<void> createBooking(BookingModel booking) async {
    String businessId = await getBusinessId();

    await _firestore
        .collection("businesses")
        .doc(businessId)
        .collection("bookings")
        .doc(booking.id)
        .set(booking.toMap());
  }

  

  /// ===============================
  /// ADD BOOKED ITEM
  /// ===============================
  Future<void> addBookedItem({
    required String bookingId,
    required BookedItemModel item,
  }) async {
    String businessId = await getBusinessId();

    final bookedItemsRef = _firestore
        .collection("businesses")
        .doc(businessId)
        .collection("bookings")
        .doc(bookingId)
        .collection("bookedItems");

    final globalRef = _firestore
        .collection("businesses")
        .doc(businessId)
        .collection("bookedItems");

    final existing = await bookedItemsRef
        .where("inventoryItemId", isEqualTo: item.inventoryItemId)
        .get();

    /// ===============================
    /// ITEM EXISTS → UPDATE
    /// ===============================
    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;

      int oldQty = doc["requestedQuantity"];
      int oldShortage = doc["shortageQuantity"];

      await doc.reference.update({
        "requestedQuantity": oldQty + item.requestedQuantity,
        "shortageQuantity": oldShortage + item.shortageQuantity,
      });

      /// ✅ ALSO ADD TO GLOBAL (APPEND ENTRY)
      await globalRef.doc().set(item.toMap());
    }

    /// ===============================
    /// NEW ITEM → CREATE
    /// ===============================
    else {
      await bookedItemsRef.doc(item.id).set(item.toMap());

      /// ✅ ALSO ADD TO GLOBAL
      await globalRef.doc().set(item.toMap());
    }
  }

  /// ===============================
  /// ADD BOOKING SERVICE
  /// ===============================
  Future<void> addBookingService({
    required String bookingId,
    required BookingServiceModel service,
  }) async {
    String businessId = await getBusinessId();

    final serviceRef = _firestore
        .collection("businesses")
        .doc(businessId)
        .collection("bookings")
        .doc(bookingId)
        .collection("bookingServices");

    /// Check if service already exists
    final existing =
        await serviceRef.where("serviceId", isEqualTo: service.serviceId).get();

    /// If already exists → do nothing
    if (existing.docs.isNotEmpty) {
      return;
    }

    /// Else → create
    await serviceRef.doc(service.id).set(service.toMap());
  }
}