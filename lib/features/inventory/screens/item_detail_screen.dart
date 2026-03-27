import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/app_config.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/utils/image_compressor.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> itemData;
  final String itemId;

  const ItemDetailScreen({
    super.key,
    required this.itemData,
    required this.itemId,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  /// ===============================
  /// EDIT ITEM DIALOG
  /// ===============================
  void _showEditDialog(BuildContext context) {
    TextEditingController qty =
        TextEditingController(text: widget.itemData['quantity'].toString());

    TextEditingController rent =
        TextEditingController(text: widget.itemData['rentPrice'].toString());

    TextEditingController desc =
        TextEditingController(text: widget.itemData['description'] ?? "");

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(AppLocalizations.of(context)!.editItem),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: qty,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.quantity,
                  ),
                ),
                TextField(
                  controller: rent,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.rentPrice,
                  ),
                ),
                TextField(
                  controller: desc,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.description,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1E4FA3),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1E4FA3),
              ),
              onPressed: () async {
                String businessId = await getBusinessId();

                await FirebaseFirestore.instance
                    .collection('businesses')
                    .doc(businessId)
                    .collection('inventoryNodes')
                    .doc(widget.itemId)
                    .update({
                  'quantity': int.parse(qty.text),
                  'rentPrice': double.parse(rent.text),
                  'description': desc.text,
                });

                Navigator.pop(context);

                setState(() {});
              },
              child: Text(
                AppLocalizations.of(context)!.save,
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  void _adjustStock(bool isAdding) {
    TextEditingController qty = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isAdding ? AppLocalizations.of(context)!.addStock : AppLocalizations.of(context)!.removeStock,
          ),
          content: TextField(
            controller: qty,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.quantity,
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1E4FA3),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(color: Colors.blue),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1E4FA3),
              ),
              onPressed: () async {
                int change = int.parse(qty.text);

                if (!isAdding) {
                  change = -change;
                }

                Navigator.pop(context); // close dialog FIRST

                await Future.delayed(const Duration(milliseconds: 100));

                await _updateQuantity(change);
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateQuantity(int change) async {
    String businessId = await getBusinessId();

    DocumentReference doc = FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('inventoryNodes')
        .doc(widget.itemId);

    await FirebaseFirestore.instance.runTransaction(
      (transaction) async {
        final snapshot = await transaction.get(doc);

        int current = snapshot['quantity'];

        int updated = current + change;

        if (updated < 0) {
          updated = 0;
        }

        transaction.update(doc, {
          'quantity': updated,
        });
      },
    );
  }

  Future<void> _changeItemImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (picked == null) return;

    File image = File(picked.path);

    final compressed = await compressImage(image);

    if (compressed == null) return;

    final imageUrl = await CloudinaryService.uploadImage(compressed);

    String businessId = await getBusinessId();

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('inventoryNodes')
        .doc(widget.itemId)
        .update({
      'imageUrl': imageUrl,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemData['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditDialog(context);
            },
          )
        ],
      ),
      body: FutureBuilder(
        future: getBusinessId(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          String businessId = snapshot.data.toString();

          return StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('businesses')
                .doc(businessId)
                .collection('inventoryNodes')
                .doc(widget.itemId)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const SizedBox();
              }

              final data = snap.data!.data()!;

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// IMAGE CARD
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              backgroundColor: Colors.black,
                              insetPadding: const EdgeInsets.all(10),
                              child: InteractiveViewer(
                                child: Image.network(
                                  data['imageUrl'],
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          height: 260,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              data['imageUrl'],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      /// CHANGE IMAGE BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            elevation: 1,
                          ),
                          icon: const Icon(Icons.image),
                          label: Text("Change Image"),
                          onPressed: () {
                            _changeItemImage();
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// TOTAL QUANTITY
                      Text(
                        "Total Quantity: ${data['quantity']}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// ADD / REMOVE STOCK BUTTONS
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                _adjustStock(true);
                              },
                              child: const Text(
                                "Add Stock",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                _adjustStock(false);
                              },
                              child: const Text(
                                "Remove Stock",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      /// RENT PRICE
                      Text(
                        "Rent Price: ₹${data['rentPrice']}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// DESCRIPTION TITLE
                      const Text(
                        "Description:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// DESCRIPTION BOX
                      Card(
                        color: Colors.white,
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            data['description'] ?? "-",
                            style: const TextStyle(
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
