import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/app_config.dart';
import '../services/inventory_service.dart';

class InventoryScreen extends StatefulWidget {
  final String? parentId;
  final String title;

  const InventoryScreen({
    super.key,
    this.parentId,
    this.title = "Inventory",
  });

  @override
  State<InventoryScreen> createState() =>
      _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {

  void _showAddOptions(BuildContext context) {

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              ListTile(
                leading: const Icon(Icons.create_new_folder),
                title: const Text("Add Category"),
                onTap: () {
                  Navigator.pop(context);
                  _showAddCategoryDialog(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.inventory),
                title: const Text("Add Item"),
                onTap: () {
                  Navigator.pop(context);
                  _showAddItemDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }




  void _showAddItemDialog(BuildContext context) {

    TextEditingController name = TextEditingController();
    TextEditingController qty = TextEditingController();
    TextEditingController rent = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("New Item"),

          content: SingleChildScrollView(
            child: Column(
              children: [

                TextField(
                  controller: name,
                  decoration:
                      const InputDecoration(
                          labelText: "Item Name"),
                ),

                TextField(
                  controller: qty,
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      const InputDecoration(
                          labelText: "Quantity"),
                ),

                TextField(
                  controller: rent,
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      const InputDecoration(
                          labelText: "Rent Price"),
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

                final service =
                    InventoryService();

                await service.addItem(
                  name: name.text,
                  quantity:
                      int.parse(qty.text),
                  rentPrice:
                      double.parse(rent.text),
                  parentId:
                      widget.parentId,
                );

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }



  

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
                parentId: widget.parentId,
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
          _showAddOptions(context);
        },
        child: const Icon(Icons.add),
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
                .where(
                  'parentId',
                  isEqualTo: widget.parentId ?? null,
                )
                .snapshots(),

            builder: (context, snap) {

              if (!snap.hasData) {
                return const SizedBox();
              }

              final docs = snap.data!.docs.where((doc) {

                final data = doc.data();

                if (widget.parentId == null) {
                  return !data.containsKey('parentId') ||
                      data['parentId'] == null;
                }

                return data['parentId'] == widget.parentId;

              }).toList();

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    "No Inventory Yet",
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (_, index) {

                  final data = docs[index].data();

                  return ListTile(
                    leading: Icon(
                      data['type'] == 'category'
                          ? Icons.folder
                          : Icons.inventory,
                    ),

                    title: Text(data['name']),

                    onTap: () {

                      if (data['type'] == 'category') {

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InventoryScreen(
                              parentId: docs[index].id,
                              title: data['name'],
                            ),
                          ),
                        );

                      }
                    },
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

