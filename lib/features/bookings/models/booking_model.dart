import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String eventName;
  final String customerName;
  final String customerPhone;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final Timestamp createdAt;
  final String customerAddress;

  final double advancePaid;
  final double estimatedTotal;
  final double finalTotal;
  final double remainingAmount;
  final bool finalBillGenerated;

  BookingModel({
    required this.id,
    required this.eventName,
    required this.customerName,
    required this.customerPhone,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.customerAddress,
    this.advancePaid = 0,
    this.estimatedTotal = 0,
    this.finalTotal = 0,
    this.remainingAmount = 0,
    this.finalBillGenerated = false,
  });

  Map<String, dynamic> toMap() {
    return {
      "eventName": eventName,
      "customerName": customerName,
      "customerPhone": customerPhone,
      "startDate": Timestamp.fromDate(startDate),
      "endDate": Timestamp.fromDate(endDate),
      "status": status,
      "createdAt": createdAt,
      "customerAddress": customerAddress,
      "advancePaid": advancePaid,
      "estimatedTotal": estimatedTotal,
      "finalTotal": finalTotal,
      "remainingAmount": remainingAmount,
      "finalBillGenerated": finalBillGenerated,
    };
  }
}
