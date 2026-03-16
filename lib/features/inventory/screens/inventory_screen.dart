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
  String defaultItemImage = "https://placehold.co/400x300/png?text=No+Image";
  TextEditingController searchController = TextEditingController();
  String searchText = "";

  bool showAllItems = false;
  bool showAllServices = false;
  bool showAllCategories = false;

  Widget _filterButton(String label, String mode) {
    bool selected = filterMode == mode;

    return GestureDetector(
      onTap: () {
        setState(() {
          filterMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E4FA3) : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAllSections(List docs) {
    List items = docs
        .where((d) =>
            (d.data() as Map)["type"] == "item" &&
            (d.data() as Map)["parentId"] == widget.parentId)
        .toList();

    List services = docs
        .where((d) =>
            (d.data() as Map)["type"] == "service" &&
            (d.data() as Map)["parentId"] == widget.parentId)
        .toList();

    List categories = docs
        .where((d) =>
            (d.data() as Map)["type"] == "category" &&
            (d.data() as Map)["parentId"] == widget.parentId)
        .toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          _section("Items", "item", items, showAllItems),
          _section("Services", "service", services, showAllServices),
          _section("Categories", "category", categories, showAllCategories)
        ],
      ),
    );
  }

  Widget _section(String title, String type, List docs, bool expanded) {
    /// show only first 2 unless expanded
    final displayDocs = expanded ? docs : docs.take(2).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// BLUE SECTION TITLE
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E4FA3),
            ),
          ),

          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                )
              ],
            ),
            child: Column(
              children: [
                /// SHOW ITEMS
                ...displayDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  return ListTile(
                    leading: Icon(
                      type == "category"
                          ? Icons.folder
                          : type == "service"
                              ? Icons.miscellaneous_services
                              : Icons.inventory,
                      color: const Color(0xFF1E4FA3),
                    ),
                    title: Text(data["name"]),
                    onLongPress: () async {
                      bool confirm = await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Delete"),
                              content:
                                  const Text("Delete this item permanently?"),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Delete"),
                                ),
                              ],
                            ),
                          ) ??
                          false;

                      if (!confirm) return;

                      await deleteNodeRecursive(doc.id);
                    },
                    onTap: () {
                      if (type == "category") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InventoryScreen(
                              parentId: doc.id,
                              title: data["name"],
                            ),
                          ),
                        );
                      } else if (type == "item") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemDetailScreen(
                              itemData: data,
                              itemId: doc.id,
                            ),
                          ),
                        );
                      } else if (type == "service") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ServiceDetailScreen(
                              serviceData: data,
                              serviceId: doc.id,
                            ),
                          ),
                        );
                      }
                    },
                  );
                }),

                /// SHOW MORE BUTTON ONLY IF NOT EXPANDED
                if (!expanded) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.expand_more,
                      color: Color(0xFF1E4FA3),
                    ),
                    title: const Text(
                      "More",
                      style: TextStyle(
                        color: Color(0xFF1E4FA3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        if (type == "item") showAllItems = true;
                        if (type == "service") showAllServices = true;
                        if (type == "category") showAllCategories = true;
                      });
                    },
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ADD OPTIONS
  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.create_new_folder,
                  color: Color(0xFF1E4FA3),
                ),
                title: const Text(
                  "Add Category",
                  style: TextStyle(
                    color: Color(0xFF1E4FA3),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showAddCategoryDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory, color: Color(0xFF1E4FA3)),
                title: const Text("Add Item",
                    style: TextStyle(color: Color(0xFF1E4FA3))),
                onTap: () {
                  Navigator.pop(context);
                  _showAddItemDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.miscellaneous_services,
                    color: Color(0xFF1E4FA3)),
                title: const Text("Add Service",
                    style: TextStyle(color: Color(0xFF1E4FA3))),
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
                    try {
                      final service = InventoryService();

                      String? imageUrl = defaultItemImage;

                      if (selectedImage != null) {
                        final compressed = await compressImage(selectedImage!);

                        if (compressed != null) {
                          imageUrl =
                              await CloudinaryService.uploadImage(compressed);
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
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceAll("Exception:", "").trim(),
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text("Save"),
                )
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
                try {
                  final service = InventoryService();

                  await service.addCategory(
                    name: controller.text,
                    parentId: widget.parentId,
                  );

                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceAll("Exception:", "").trim(),
                      ),
                    ),
                  );
                }
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
        backgroundColor: const Color(0xFF1E4FA3),
        centerTitle: true,
        title: const Text(
          "Inventory",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        elevation: 3,
        onPressed: () {
          _showAddOptions(context);
        },
        child: const Icon(
          Icons.add,
          color: Color(0xFF1E4FA3),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _filterButton("All", "all"),
                  _filterButton("Categories", "category"),
                  _filterButton("Items", "item"),
                  _filterButton("Services", "service"),
                ],
              ),
            ),
          ),

          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                  )
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search inventory",
                  prefixIcon: const Icon(Icons.search),

                  /// CLEAR BUTTON
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            searchController.clear();

                            setState(() {
                              searchText = "";
                            });

                            FocusScope.of(context).unfocus(); // closes keyboard
                          },
                        )
                      : null,

                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF1E4FA3),
                      width: 1,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchText = value.toLowerCase();
                  });
                },
              ),
            ),
          ),

          if (widget.parentId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.folder,
                    color: Color(0xFF1E4FA3),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Category: ${widget.title}",
                    style: const TextStyle(
                      color: Color(0xFF1E4FA3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: FutureBuilder(
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
                    .collection('inventoryNodes');

                /// only restrict by parent when NOT searching
                if (searchText.isEmpty) {
                  query = query.where('parentId', isEqualTo: widget.parentId);
                }

                if (filterMode != "all") {
                  query = query.where('type', isEqualTo: filterMode);
                }

                return StreamBuilder(
                  stream: query.snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const SizedBox();
                    }

                    var docs = snap.data!.docs;

                    if (searchText.isNotEmpty) {
                      docs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? "").toLowerCase();
                        return name.contains(searchText);
                      }).toList();
                    }

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text("No Inventory Yet"),
                      );
                    }

                    if (filterMode == "all" && searchText.isEmpty) {
                      return _buildAllSections(docs);
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (_, index) {
                        final data = docs[index].data() as Map<String, dynamic>;

                        return Card(
                          color: Colors.white,
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: Icon(
                              data['type'] == 'category'
                                  ? Icons.folder
                                  : data['type'] == 'service'
                                      ? Icons.miscellaneous_services
                                      : Icons.inventory,
                              color: const Color(0xFF1E4FA3),
                            ),
                            title: Text(
                              data['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onLongPress: () async {
                              bool confirm = await showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Delete"),
                                      content: const Text("Delete this item?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context, false);
                                          },
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context, true);
                                          },
                                          child: const Text("Delete"),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;

                              if (!confirm) return;

                              await deleteNodeRecursive(docs[index].id);
                            },
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
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> deleteNodeRecursive(String nodeId) async {
    String businessId = await getBusinessId();

    final nodeRef = FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('inventoryNodes')
        .doc(nodeId);

    /// find children
    final children = await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('inventoryNodes')
        .where("parentId", isEqualTo: nodeId)
        .get();

    /// delete children first
    for (var child in children.docs) {
      await deleteNodeRecursive(child.id);
    }

    /// delete this node
    await nodeRef.delete();
  }
}
