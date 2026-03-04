import 'service_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/app_config.dart';
import '../services/inventory_service.dart';
import 'item_detail_screen.dart';
import 'package:tent_app/features/bookings/screens/add_service_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/utils/image_compressor.dart';

class InventoryScreen extends StatefulWidget {
  final String? parentId;
  final String title;

  const InventoryScreen({
    super.key,
    this.parentId,
    this.title = "Inventory",
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String filterMode = "all";

/// ADD OPTIONS
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

            ListTile(
              leading: const Icon(Icons.miscellaneous_services),
              title: const Text("Add Service"),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddServiceScreen(
                      parentId: widget.parentId,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

/// ADD ITEM
void _showAddItemDialog(BuildContext context) {

  TextEditingController name = TextEditingController();
  TextEditingController qty = TextEditingController();
  TextEditingController rent = TextEditingController();
  TextEditingController description = TextEditingController();

  File? selectedImage;

  showDialog(
    context: context,
    builder: (_) {

      return StatefulBuilder(
        builder: (context, setStateDialog) {

          return AlertDialog(
            title: const Text("New Item"),

            content: SingleChildScrollView(
              child: Column(
                children: [

                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: "Item Name",
                    ),
                  ),

                  TextField(
                    controller: qty,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Quantity",
                    ),
                  ),

                  TextField(
                    controller: rent,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Rent Price",
                    ),
                  ),

                  TextField(
                    controller: description,
                    decoration: const InputDecoration(
                      labelText: "Description",
                    ),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text("Select Image"),
                    onPressed: () async {

                      final picker = ImagePicker();

                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                      );

                      if (picked != null) {
                        setStateDialog(() {
                          selectedImage = File(picked.path);
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 10),

                  if (selectedImage != null)
                    Image.file(
                      selectedImage!,
                      height: 100,
                    ),

                ],
              ),
            ),

            actions: [

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),

              TextButton(
                onPressed: () async {

                  final service = InventoryService();

                  String? imageUrl;

                  if (selectedImage != null) {
                    final compressed =
                        await compressImage(selectedImage!);

                    if (compressed != null) {
                      imageUrl = await CloudinaryService.uploadImage(
                        compressed,
                      );
                    }
                  }

                  await service.addItem(
                    name: name.text,
                    quantity: int.parse(qty.text),
                    rentPrice: double.parse(rent.text),
                    parentId: widget.parentId,
                    description: description.text,
                    imageUrl: imageUrl,
                  );

                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      );
    },
  );
}

/// ADD CATEGORY
void _showAddCategoryDialog(BuildContext context) {

  TextEditingController controller = TextEditingController();

  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text("New Category"),

        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Category Name",
          ),
        ),

        actions: [

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          TextButton(
            onPressed: () async {

              final service = InventoryService();

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
  title: Text(widget.title),
  actions: [

    TextButton(
      onPressed: () {
        setState(() {
          filterMode = "all";
        });
      },
      child: const Text(
        "All",
        style: TextStyle(color: Colors.black),
      ),
    ),

    TextButton(
      onPressed: () {
        setState(() {
          filterMode = "category";
        });
      },
      child: const Text(
        "Categories",
        style: TextStyle(color: Colors.black),
      ),
    ),

    TextButton(
      onPressed: () {
        setState(() {
          filterMode = "item";
        });
      },
      child: const Text(
        "Items",
        style: TextStyle(color: Colors.black),
      ),
    ),

    TextButton(
      onPressed: () {
        setState(() {
          filterMode = "service";
        });
      },
      child: const Text(
        "Services",
        style: TextStyle(color: Colors.black),
      ),
    ),

  ],
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

        Query query = FirebaseFirestore.instance
    .collection('businesses')
    .doc(businessId)
    .collection('inventoryNodes')
    .where(
      'parentId',
      isEqualTo: widget.parentId,
    );

if (filterMode != "all") {
  query = query.where('type', isEqualTo: filterMode);
}

return StreamBuilder(
  stream: query.snapshots(),

          builder: (context, snap) {

            if (!snap.hasData) {
              return const SizedBox();
            }

            final docs = snap.data!.docs;

            if (docs.isEmpty) {
              return const Center(
                child: Text("No Inventory Yet"),
              );
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (_, index) {

                final data = docs[index].data() as Map<String, dynamic>;

                return ListTile(
                  leading: Icon(
                    data['type'] == 'category'
                        ? Icons.folder
                        : data['type'] == 'service'
                            ? Icons.miscellaneous_services
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

                    } else if (data['type'] == 'item') {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ItemDetailScreen(
                            itemData: data,
                            itemId: docs[index].id,
                          ),
                        ),
                      );

                    } else if (data['type'] == 'service') {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ServiceDetailScreen(
                            serviceData: data,
                            serviceId: docs[index].id,
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