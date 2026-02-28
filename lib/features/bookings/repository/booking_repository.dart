import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/booked_item_model.dart';

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

    await _firestore
        .collection("businesses")
        .doc(businessId)
        .collection("bookings")
        .doc(bookingId)
        .collection("bookedItems")
        .doc(item.id)
        .set(item.toMap());
  }
}