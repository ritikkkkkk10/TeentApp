import 'package:flutter/material.dart';

Widget buildAllSections({
  required List docs,
  required String? parentId,
  required bool showAllItems,
  required bool showAllServices,
  required bool showAllCategories,
  required Widget Function(String, String, List, bool) sectionBuilder,
}) {
  List items = docs
      .where((d) =>
          (d.data() as Map)["type"] == "item" &&
          (d.data() as Map)["parentId"] == parentId)
      .toList();

  List services = docs
      .where((d) =>
          (d.data() as Map)["type"] == "service" &&
          (d.data() as Map)["parentId"] == parentId)
      .toList();

  List categories = docs
      .where((d) =>
          (d.data() as Map)["type"] == "category" &&
          (d.data() as Map)["parentId"] == parentId)
      .toList();

  return SingleChildScrollView(
    child: Column(
      children: [
        sectionBuilder("Items", "item", items, showAllItems),
        sectionBuilder("Services", "service", services, showAllServices),
        sectionBuilder("Categories", "category", categories, showAllCategories),
      ],
    ),
  );
}