import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../services/inventory_service.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/utils/image_compressor.dart';

Future<void> showAddItemDialog(
  BuildContext context,
  String? parentId,
  String defaultItemImage,
  InputDecoration Function(String) inputStyle,
) async {
  TextEditingController name = TextEditingController();
  TextEditingController qty = TextEditingController();
  TextEditingController rent = TextEditingController();
  TextEditingController description = TextEditingController();

  File? selectedImage;

  await showDialog(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            titlePadding: EdgeInsets.zero,
            title: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFEAEAEA)),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.newItem,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: name,
                    cursorColor: const Color(0xFF2563EB),
                    style: const TextStyle(color: Colors.black),
                    decoration:
                        inputStyle(AppLocalizations.of(context)!.itemName),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: qty,
                    keyboardType: TextInputType.number,
                    cursorColor: const Color(0xFF2563EB),
                    style: const TextStyle(color: Colors.black),
                    decoration:
                        inputStyle(AppLocalizations.of(context)!.quantity),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: rent,
                    keyboardType: TextInputType.number,
                    cursorColor: const Color(0xFF2563EB),
                    style: const TextStyle(color: Colors.black),
                    decoration:
                        inputStyle(AppLocalizations.of(context)!.rentPrice),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: description,
                    maxLines: 3,
                    cursorColor: const Color(0xFF2563EB),
                    style: const TextStyle(color: Colors.black),
                    decoration:
                        inputStyle(AppLocalizations.of(context)!.description),
                  ),
                  const SizedBox(height: 16),

                  InkWell(
                    onTap: () async {
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
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF3B82F6),
                            Color(0xFF2563EB),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            AppLocalizations.of(context)!.selectImage,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (selectedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        selectedImage!,
                        height: 100,
                      ),
                    ),
                ],
              ),
            ),
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    final service = InventoryService();

                    String? imageUrl = defaultItemImage;

                    if (selectedImage != null) {
                      final compressed =
                          await compressImage(selectedImage!);

                      if (compressed != null) {
                        imageUrl =
                            await CloudinaryService.uploadImage(compressed);
                      }
                    }

                    await service.addItem(
                      name: name.text,
                      quantity: int.parse(qty.text),
                      rentPrice: double.parse(rent.text),
                      parentId: parentId,
                      description: description.text,
                      imageUrl: imageUrl,
                    );

                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString()
                              .replaceAll("Exception:", "")
                              .trim(),
                        ),
                      ),
                    );
                  }
                },
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          );
        },
      );
    },
  );
}