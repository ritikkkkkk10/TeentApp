import 'package:cloud_firestore/cloud_firestore.dart';

class BookingServiceModel {
  final String id;
  final String serviceId;
  final String serviceName;
  final double priceSnapshot;
  final Timestamp createdAt;

  BookingServiceModel({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.priceSnapshot,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "serviceId": serviceId,
      "serviceName": serviceName,
      "priceSnapshot": priceSnapshot,
      "createdAt": createdAt,
    };
  }
}