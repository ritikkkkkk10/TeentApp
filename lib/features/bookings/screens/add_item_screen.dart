import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../repository/booking_repository.dart';
import '../models/booked_item_model.dart';
import '../../../core/config/app_config.dart';

class AddItemScreen extends StatefulWidget {
  final String bookingId;

  const AddItemScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  String? businessId;
  final BookingRepository repo = BookingRepository();

  DateTime? startDate;
  DateTime? endDate;

  /// ===============================
  /// LOAD BOOKING DATES
  /// ===============================
  @override
void initState() {
  super.initState();
  init();
}

Future<void> init() async {
  businessId = await getBusinessId(); // ✅ IMPORTANT
  await loadBookingDates();
}

  Future<void> loadBookingDates() async {
    final bookingDoc = await FirebaseFirestore.instance
        .collection("businesses")
        .doc(businessId!)
        .collection("bookings")
        .doc(widget.bookingId)
        .get();

    startDate = (bookingDoc["startDate"] as Timestamp).toDate();

    endDate = (bookingDoc["endDate"] as Timestamp).toDate();

    setState(() {});
  }

  /// ===============================
  /// DATE OVERLAP AVAILABILITY STREAM
  /// ===============================
  Stream<int> bookedQuantityStream(String inventoryItemId) {
  if (businessId == null || startDate == null || endDate == null) {
    return Stream.value(0);
  }

  return FirebaseFirestore.instance
      .collection("businesses")
      .doc(businessId)
      .collection("bookedItems") // ✅ FAST SOURCE
      .snapshots()
      .map((snapshot) {

    int totalBooked = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();

      if (data["inventoryItemId"] != inventoryItemId) continue;

      /// skip manual
      if (data["isManual"] == true) continue;

      DateTime otherStart =
          (data["bookingStartDate"] as Timestamp).toDate();
      DateTime otherEnd =
          (data["bookingEndDate"] as Timestamp).toDate();

      bool overlap =
          !(otherEnd.isBefore(startDate!) || otherStart.isAfter(endDate!));

      if (!overlap) continue;

      int requested = (data["requestedQuantity"] as num?)?.toInt() ?? 0;
      int dispatched = (data["dispatchedQuantity"] as num?)?.toInt() ?? 0;

      int effectiveQty = dispatched > 0 ? dispatched : requested;

      totalBooked += effectiveQty;
    }

    return totalBooked;
  });
}

  /// ===============================
  /// ADD ITEM
  /// ===============================
  void addItem(BuildContext context, DocumentSnapshot item, int available) {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(item["name"]),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Quantity"),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
    foregroundColor: const Color(0xFF1E4FA3),
  ),
            child: Text(AppLocalizations.of(context)!.add),
            onPressed: () async {
              int requested = int.parse(controller.text);

              int shortage = requested > available ? requested - available : 0;

              /// SHORTAGE WARNING
              if (shortage > 0) {
                bool? proceed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: Colors.white,
                    title: Text(AppLocalizations.of(context)!.stockShortage),
                    content: Text("Only $available available.\n"
                        "Short by $shortage items.\n\n"
                        "Continue booking?"),
                    actions: [
                      TextButton(
                        style: TextButton.styleFrom(
    foregroundColor: const Color(0xFF1E4FA3),
  ),
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
    foregroundColor: const Color(0xFF1E4FA3),
  ),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(AppLocalizations.of(context)!.proceed),
                      ),
                    ],
                  ),
                );

                if (proceed != true) return;
              }

              BookedItemModel booked = BookedItemModel(
                id: const Uuid().v4(),
                inventoryItemId: item.id,
                itemName: item["name"],
                requestedQuantity: requested,
                availableQuantityAtBooking: available,
                shortageQuantity: shortage,
                rentPriceSnapshot: item["rentPrice"].toDouble(),
                createdAt: Timestamp.now(),
                bookingId: widget.bookingId,
                businessId: businessId,
                /// ✅ ADD THESE
                bookingStartDate: startDate!,
                bookingEndDate: endDate!,
              );

              await repo.addBookedItem(
                bookingId: widget.bookingId,
                item: booked,
              );

              Navigator.pop(context);
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  /// ===============================
  /// UI
  /// ===============================
  @override
  Widget build(BuildContext context) {
    if (startDate == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.selectItem)),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("businesses")
            .doc(businessId)
            .collection("inventoryNodes")
            .where("type", isEqualTo: "item")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var items = snapshot.data!.docs;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              var item = items[index];

              return StreamBuilder<int>(
                stream: bookedQuantityStream(item.id),
                builder: (context, bookedSnap) {
                  if (!bookedSnap.hasData) {
                    return ListTile(title: Text(AppLocalizations.of(context)!.checking));
                  }

                  int booked = bookedSnap.data!;
                  int total = item["quantity"];

                  int available = total - booked;

                  return ListTile(
                    title: Text(item["name"]),
                    subtitle: Text("${AppLocalizations.of(context)!.available} $available / $total"),
                    onTap: () => addItem(
                      context,
                      item,
                      available,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
