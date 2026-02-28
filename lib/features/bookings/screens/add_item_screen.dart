    import 'package:flutter/material.dart';
    import 'package:cloud_firestore/cloud_firestore.dart';
    import 'package:uuid/uuid.dart';

    import '../repository/booking_repository.dart';
    import '../models/booked_item_model.dart';

    class AddItemScreen extends StatefulWidget {
    final String bookingId;

    const AddItemScreen({
        super.key,
        required this.bookingId,
    });

    @override
    State<AddItemScreen> createState() =>
        _AddItemScreenState();
    }

    class _AddItemScreenState extends State<AddItemScreen> {

    final String businessId = "demo_business";
    final BookingRepository repo =
        BookingRepository();

    DateTime? startDate;
    DateTime? endDate;

    /// ===============================
    /// LOAD BOOKING DATES
    /// ===============================
    @override
    void initState() {
        super.initState();
        loadBookingDates();
    }

    Future<void> loadBookingDates() async {

        final bookingDoc =
            await FirebaseFirestore.instance
                .collection("businesses")
                .doc(businessId)
                .collection("bookings")
                .doc(widget.bookingId)
                .get();

        startDate =
            (bookingDoc["startDate"] as Timestamp)
                .toDate();

        endDate =
            (bookingDoc["endDate"] as Timestamp)
                .toDate();

        setState(() {});
    }

    /// ===============================
    /// CALCULATE BOOKED QTY (OVERLAP)
    /// ===============================
    Future<int> calculateBookedQuantity(
        String inventoryItemId) async {

        if (startDate == null ||
            endDate == null) {
        return 0;
        }

        QuerySnapshot bookings =
            await FirebaseFirestore.instance
                .collection("businesses")
                .doc(businessId)
                .collection("bookings")
                .get();

        int totalBooked = 0;

        for (var booking in bookings.docs) {

        DateTime otherStart =
            (booking["startDate"]
                    as Timestamp)
                .toDate();

        DateTime otherEnd =
            (booking["endDate"]
                    as Timestamp)
                .toDate();

        /// DATE OVERLAP CHECK
        bool overlap =
            !(otherEnd.isBefore(startDate!) ||
                otherStart
                    .isAfter(endDate!));

        if (!overlap) continue;

        var items = await booking.reference
            .collection("bookedItems")
            .where(
                "inventoryItemId",
                isEqualTo: inventoryItemId,
            )
            .get();

        for (var item in items.docs) {
            totalBooked +=
                item["requestedQuantity"]
                    as int;
        }
        }

        return totalBooked;
    }

    /// ===============================
    /// ADD ITEM TO BOOKING
    /// ===============================
    void addItem(
        BuildContext context,
        DocumentSnapshot item) {

        TextEditingController qtyController =
            TextEditingController();

        showDialog(
        context: context,
        builder: (_) {
            return AlertDialog(
            title: Text(item["name"]),
            content: TextField(
                controller: qtyController,
                keyboardType:
                    TextInputType.number,
                decoration:
                    const InputDecoration(
                        labelText:
                            "Quantity"),
            ),
            actions: [
                TextButton(
                child: const Text("Add"),
                onPressed: () async {

                    int requested =
                        int.parse(
                            qtyController.text);

                    int totalQty =
                        item["quantity"];

                    int alreadyBooked =
    await calculateBookedQuantity(item.id);
                    int available = totalQty - alreadyBooked;

                    int shortage =
                        requested > available
                            ? requested - available
                            : 0;

                    /// ===============================
                    /// ⭐ SHORTAGE WARNING HERE
                    /// ===============================


                    if (shortage > 0) {

                    bool proceed =
                        await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                        title:
                            const Text("Stock Shortage"),
                        content: Text(
                            "Short by $shortage items.\nContinue booking?"),
                        actions: [
                            TextButton(
                            onPressed: () =>
                                Navigator.pop(
                                    context,
                                    false),
                            child:
                                const Text("Cancel"),
                            ),
                            TextButton(
                            onPressed: () =>
                                Navigator.pop(
                                    context,
                                    true),
                            child:
                                const Text("Proceed"),
                            ),
                        ],
                        ),
                    );

                    if (proceed != true) return;
                    }

                    BookedItemModel booked =
                        BookedItemModel(
                    id:
                        const Uuid().v4(),
                    inventoryItemId:
                        item.id,
                    itemName:
                        item["name"],
                    requestedQuantity:
                        requested,
                    availableQuantityAtBooking:
                        totalQty,
                    shortageQuantity:
                        shortage,
                    rentPriceSnapshot:
                        item["rentPrice"]
                            .toDouble(),
                    createdAt:
                        Timestamp.now(),
                    );

                    await repo
                        .addBookedItem(
                    bookingId:
                        widget.bookingId,
                    item: booked,
                    );

                    Navigator.pop(context);
                    Navigator.pop(context);
                },
                )
            ],
            );
        },
        );
    }

    /// ===============================
    /// UI
    /// ===============================
    @override
    Widget build(BuildContext context) {

        return Scaffold(
        appBar: AppBar(
            title:
                const Text("Select Item")),

        body: StreamBuilder(
            stream: FirebaseFirestore
                .instance
                .collection(
                    "businesses")
                .doc(businessId)
                .collection(
                    "inventoryNodes")
                .where("type",
                    isEqualTo: "item")
                .snapshots(),
            builder:
                (context, snapshot) {

            if (!snapshot.hasData) {
                return const Center(
                child:
                    CircularProgressIndicator(),
                );
            }

            var items =
                snapshot.data!.docs;

            return ListView.builder(
                itemCount:
                    items.length,
                itemBuilder:
                    (context, index) {

                var item =
                    items[index];

                return ListTile(
                    title:
                        Text(item["name"]),

                    /// ⭐ REAL AVAILABILITY
                    subtitle:
                        FutureBuilder<int>(
                    future:
                        calculateBookedQuantity(
                            item.id),
                    builder:
                        (context,
                            snap) {

                        if (!snap
                            .hasData) {
                        return const Text(
                            "Checking...");
                        }

                        int booked =
                            snap.data!;
                        int total =
                            item[
                                "quantity"];

                        int available =
                            total -
                                booked;

                        return Text(
                        "Available: $available / $total",
                        );
                    },
                    ),

                    onTap: () =>
                        addItem(
                            context,
                            item),
                );
                },
            );
            },
        ),
        );
    }
    }