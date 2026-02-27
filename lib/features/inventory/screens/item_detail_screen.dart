import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/app_config.dart';

class ItemDetailScreen extends StatefulWidget {

  final Map<String, dynamic> itemData;
  final String itemId;

  const ItemDetailScreen({
    super.key,
    required this.itemData,
    required this.itemId,
  });

  @override
  State<ItemDetailScreen> createState()
      => _ItemDetailScreenState();
}

class _ItemDetailScreenState
    extends State<ItemDetailScreen> {

  /// ===============================
  /// EDIT ITEM DIALOG
  /// ===============================
  void _showEditDialog(BuildContext context) {

    TextEditingController qty =
        TextEditingController(
            text: widget.itemData['quantity']
                .toString());

    TextEditingController rent =
        TextEditingController(
            text: widget.itemData['rentPrice']
                .toString());

    TextEditingController desc =
        TextEditingController(
            text:
                widget.itemData['description']
                    ?? "");

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Edit Item"),

          content: SingleChildScrollView(
            child: Column(
              children: [

                TextField(
                  controller: qty,
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      const InputDecoration(
                    labelText: "Quantity",
                  ),
                ),

                TextField(
                  controller: rent,
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      const InputDecoration(
                    labelText: "Rent Price",
                  ),
                ),

                TextField(
                  controller: desc,
                  decoration:
                      const InputDecoration(
                    labelText: "Description",
                  ),
                ),
              ],
            ),
          ),

          actions: [

            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            TextButton(
              onPressed: () async {

                String businessId =
                    await getBusinessId();

                await FirebaseFirestore
                    .instance
                    .collection(
                        'businesses')
                    .doc(businessId)
                    .collection(
                        'inventoryNodes')
                    .doc(widget.itemId)
                    .update({

                  'quantity':
                      int.parse(qty.text),

                  'rentPrice':
                      double.parse(rent.text),

                  'description':
                      desc.text,
                });

                Navigator.pop(context);

                setState(() {});
              },
              child: const Text("Save"),
            ),
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
            Text(widget.itemData['name']),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.edit),
            onPressed: () {
              _showEditDialog(
                  context);
            },
          )
        ],
      ),

      body: FutureBuilder(
  future: getBusinessId(),
  builder: (context, snapshot) {

    if (!snapshot.hasData) {
      return const Center(
          child:
              CircularProgressIndicator());
    }

    String businessId =
        snapshot.data.toString();

    return StreamBuilder(
      stream: FirebaseFirestore
          .instance
          .collection('businesses')
          .doc(businessId)
          .collection(
              'inventoryNodes')
          .doc(widget.itemId)
          .snapshots(),

      builder: (context, snap) {

        if (!snap.hasData) {
          return const SizedBox();
        }

        final data =
            snap.data!.data()!;

        return Padding(
          padding:
              const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              Text(
                "Total Quantity: "
                "${data['quantity']}",
                style:
                    const TextStyle(
                        fontSize: 18),
              ),

              const SizedBox(
                  height: 10),

              Text(
                "Rent Price: ₹"
                "${data['rentPrice']}",
                style:
                    const TextStyle(
                        fontSize: 18),
              ),

              const SizedBox(
                  height: 20),

              const Text(
                "Description:",
                style: TextStyle(
                    fontWeight:
                        FontWeight.bold),
              ),

              Text(
                data['description']
                        ??
                    "-",
              ),
            ],
          ),
        );
      },
    );
  },
),
    );
  }
}