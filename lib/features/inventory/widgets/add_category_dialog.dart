import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/inventory_service.dart';

Future<void> showAddCategoryDialog(
  BuildContext context,
  String? parentId,
) async {
  TextEditingController controller = TextEditingController();

  await showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.newCategory),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.categoryName,
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
              try {
                final service = InventoryService();

                await service.addCategory(
                  name: controller.text,
                  parentId: parentId,
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
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      );
    },
  );
}