import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../screens/payment_history_screen.dart';
import '../../inventory/services/business_profile_service.dart';
import '../../../core/utils/invoice_generator.dart';
import 'payment_dialog.dart';

class BillSection extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final List items;
  final List services;
  final DocumentReference bookingRef;
  final String businessId;
  final String bookingId;

  const BillSection({
    super.key,
    required this.bookingData,
    required this.items,
    required this.services,
    required this.bookingRef,
    required this.businessId,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    double estimatedTotal = 0;

    for (var item in items) {
      final data = item.data() as Map<String, dynamic>;

      int requestedQty = data["requestedQuantity"] ?? 0;
      int dispatchedQty = data["dispatchedQuantity"] ?? 0;

      int qty = dispatchedQty > 0 ? dispatchedQty : requestedQty;

      double price = (data["rentPriceSnapshot"] ?? 0).toDouble();

      estimatedTotal += qty * price;
    }

    double serviceTotal = 0;

    for (var service in services) {
      serviceTotal += (service["priceSnapshot"] ?? 0).toDouble();
    }

    double grandTotal = estimatedTotal + serviceTotal;

    double paid = (bookingData["totalPaid"] ?? 0).toDouble();
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: Color(0xFF1E4FA3)),
                SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.estimatedBill,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              AppLocalizations.of(context)!
                  .itemsTotal(estimatedTotal.toStringAsFixed(2)),
            ),
            Text(
              AppLocalizations.of(context)!
                  .servicesTotal(serviceTotal.toStringAsFixed(2)),
            ),

            const Divider(height: 24),

            Text(
              AppLocalizations.of(context)!
                  .grandTotal(grandTotal.toStringAsFixed(2)),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            Text(AppLocalizations.of(context)!.paid(paid)),

            Text(
              AppLocalizations.of(context)!
                  .remainingAmount((grandTotal - paid).toStringAsFixed(2)),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 16),

            /// PAYMENT BUTTONS
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E4FA3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.payments, color: Colors.white),
                      label: Text(
                        AppLocalizations.of(context)!.makePayment,
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        showPaymentDialog(
                          context,
                          bookingRef,
                          paid,
                          grandTotal,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E4FA3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.history, color: Colors.white),
                      label: Text(
                        AppLocalizations.of(context)!.history,
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentHistoryScreen(
                              bookingId: bookingId,
                              businessId: businessId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// INVOICE BUTTON
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Row(
                children: [
                  /// 🔹 PREVIEW BUTTON
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E4FA3),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.visibility, color: Colors.white),
                      label: Text(
                        AppLocalizations.of(context)!.preview,
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        final profileService = BusinessProfileService();
                        final profile =
                            await profileService.getProfile(businessId);

                        if (profile == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)!
                                  .fillBusinessProfile),
                            ),
                          );
                          return;
                        }

                        generateInvoice(
                          context,
                          isPreview: true, // 👈 IMPORTANT
                          businessName: profile.businessName,
                          ownerName: profile.ownerName,
                          businessPhone: profile.phone,
                          businessAddress: profile.address,
                          gst: profile.gst,
                          customerName: bookingData["customerName"],
                          customerPhone: bookingData["customerPhone"],
                          customerAddress: bookingData["customerAddress"],
                          eventName: bookingData["eventName"],
                          startDate:
                              (bookingData["startDate"] as Timestamp).toDate(),
                          endDate:
                              (bookingData["endDate"] as Timestamp).toDate(),
                          items: items.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return {
                              "name": data["itemName"],
                              "requested": data["requestedQuantity"],
                              "dispatched": data["dispatchedQuantity"],
                              "price": data["rentPriceSnapshot"],
                            };
                          }).toList(),
                          services: services.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return {
                              "name": data["serviceName"],
                              "price": data["priceSnapshot"],
                            };
                          }).toList(),
                          total: grandTotal,
                          paid: paid,
                        );
                      },
                    ),
                  ),

                  /// 🔹 SEND WHATSAPP BUTTON
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.send, color: Colors.white),
                      label: Text(
                        AppLocalizations.of(context)!.send,
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        final profileService = BusinessProfileService();
                        final profile =
                            await profileService.getProfile(businessId);

                        if (profile == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)!
                                  .fillBusinessProfile),
                            ),
                          );
                          return;
                        }

                        generateInvoice(
                          context,
                          isPreview: false, // 👈 IMPORTANT
                          businessName: profile.businessName,
                          ownerName: profile.ownerName,
                          businessPhone: profile.phone,
                          businessAddress: profile.address,
                          gst: profile.gst,
                          customerName: bookingData["customerName"],
                          customerPhone: bookingData["customerPhone"],
                          customerAddress: bookingData["customerAddress"],
                          eventName: bookingData["eventName"],
                          startDate:
                              (bookingData["startDate"] as Timestamp).toDate(),
                          endDate:
                              (bookingData["endDate"] as Timestamp).toDate(),
                          items: items.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return {
                              "name": data["itemName"],
                              "requested": data["requestedQuantity"],
                              "dispatched": data["dispatchedQuantity"],
                              "price": data["rentPriceSnapshot"],
                            };
                          }).toList(),
                          services: services.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return {
                              "name": data["serviceName"],
                              "price": data["priceSnapshot"],
                            };
                          }).toList(),
                          total: grandTotal,
                          paid: paid,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}
