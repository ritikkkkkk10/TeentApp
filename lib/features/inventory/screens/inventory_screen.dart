import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/app_config.dart';
import '../services/inventory_service.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  void _showAddCategoryDialog(BuildContext context) {

  TextEditingController controller =
      TextEditingController();

  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text("New Category"),

        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(
                  hintText: "Category Name"),
        ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),

          TextButton(
            onPressed: () async {

              final service =
                  InventoryService();

              await service.addCategory(
                name: controller.text,
              );

              Navigator.pop(context);
            },
            child: const Text("Create"),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory"),
      ),

      floatingActionButton: FloatingActionButton(
  onPressed: () {
    _showAddCategoryDialog(context);
  },
  child: const Icon(Icons.create_new_folder),
),

      body: FutureBuilder(
        future: getBusinessId(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          String businessId = snapshot.data.toString();

          return StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('businesses')
                .doc(businessId)
                .collection('inventoryNodes')
                .where('parentId', isEqualTo: null)
                .snapshots(),

            builder: (context, snap) {

              if (!snap.hasData) {
                return const SizedBox();
              }

              final docs = snap.data!.docs;

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    "No Inventory Yet\nAdd Category First",
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (_, index) {

                  final data = docs[index];

                  return ListTile(
                    leading: Icon(
                      data['type'] == 'category'
                          ? Icons.folder
                          : Icons.inventory,
                    ),
                    title: Text(data['name']),
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