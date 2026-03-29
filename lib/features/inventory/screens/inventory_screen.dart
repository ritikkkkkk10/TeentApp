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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/add_category_dialog.dart';
import '../widgets/add_item_dialog.dart';
import '../widgets/build_all_sections.dart';
import '../../../core/utils/input_decoration.dart';

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
                              backgroundColor: Colors.white,
                              title: Text(AppLocalizations.of(context)!.delete),
                              content: Text(AppLocalizations.of(context)!
                                  .deleteItemConfirm),
                              actions: [
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF1E4FA3),
                                  ),
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(
                                      AppLocalizations.of(context)!.cancel),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF1E4FA3),
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                      AppLocalizations.of(context)!.delete),
                                ),
                              ],
                            ),
                          ) ??
                          false;

                      if (!confirm) return;

                      await InventoryService().deleteNodeRecursive(doc.id);
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
                    title: Text(
                      AppLocalizations.of(context)!.more,
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
                title: Text(
                  AppLocalizations.of(context)!.addCategory,
                  style: TextStyle(
                    color: Color(0xFF1E4FA3),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showAddCategoryDialog(context, widget.parentId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory, color: Color(0xFF1E4FA3)),
                title: Text(AppLocalizations.of(context)!.addItem,
                    style: TextStyle(color: Color(0xFF1E4FA3))),
                onTap: () {
                  Navigator.pop(context);
                  showAddItemDialog(
                    context,
                    widget.parentId,
                    defaultItemImage,
                    inputStyle, // still works (now imported)
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.miscellaneous_services,
                    color: Color(0xFF1E4FA3)),
                title: Text(AppLocalizations.of(context)!.addService,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E4FA3),
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.inventory,
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
                  _filterButton(AppLocalizations.of(context)!.all, "all"),
                  _filterButton(
                      AppLocalizations.of(context)!.categories, "category"),
                  _filterButton(AppLocalizations.of(context)!.items, "item"),
                  _filterButton(
                      AppLocalizations.of(context)!.services, "service"),
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
                  hintText: AppLocalizations.of(context)!.searchInventory,
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
                    AppLocalizations.of(context)!.category(widget.title),
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
                      return Center(
                        child: Text(AppLocalizations.of(context)!.noInventory),
                      );
                    }

                    if (filterMode == "all" && searchText.isEmpty) {
                      return buildAllSections(
                        docs: docs,
                        parentId: widget.parentId,
                        showAllItems: showAllItems,
                        showAllServices: showAllServices,
                        showAllCategories: showAllCategories,
                        sectionBuilder: _section,
                      );
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
                                      backgroundColor: Colors.white,
                                      title: Text(
                                          AppLocalizations.of(context)!.delete),
                                      content: Text(
                                          AppLocalizations.of(context)!
                                              .deleteItemConfirmShort),
                                      actions: [
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFF1E4FA3),
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context, false);
                                          },
                                          child: Text(
                                              AppLocalizations.of(context)!
                                                  .cancel),
                                        ),
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFF1E4FA3),
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context, true);
                                          },
                                          child: Text(
                                              AppLocalizations.of(context)!
                                                  .delete),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;

                              if (!confirm) return;

                              await InventoryService()
                                  .deleteNodeRecursive(docs[index].id);
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
}
