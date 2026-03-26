import 'package:flutter/material.dart';
import 'package:tent_app/features/inventory/services/inventory_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/utils/image_compressor.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddServiceScreen extends StatefulWidget {
  final String? parentId;

  const AddServiceScreen({
    super.key,
    this.parentId,
  });

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final ImagePicker _picker = ImagePicker();
  int currentImageIndex = 0;

  List<File> selectedImages = [];
  List<String> uploadedUrls = [];

  final TextEditingController nameController = TextEditingController();

  final TextEditingController priceController = TextEditingController();

  final TextEditingController descController = TextEditingController();

  bool isLoading = false;

  InputDecoration inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 16,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF2563EB),
        fontWeight: FontWeight.w500,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF2563EB),
          width: 2,
        ),
      ),
    );
  }

  Future<void> pickImage() async {
    int remaining = 5 - selectedImages.length;

    if (remaining <= 0) return;

    final List<XFile> picked = await _picker.pickMultiImage();

    if (picked.isEmpty) return;

    for (var img in picked.take(remaining)) {
      File file = File(img.path);

      File? compressed = await compressImage(file);

      if (compressed != null) {
        selectedImages.add(compressed);
      }
    }

    setState(() {});
  }

  Future<void> uploadImages() async {
    uploadedUrls.clear();

    for (File file in selectedImages) {
      String? url = await CloudinaryService.uploadImage(file);

      if (url != null) {
        uploadedUrls.add(url);
      }
    }
  }

  Future<void> saveService() async {
    if (nameController.text.isEmpty || priceController.text.isEmpty) {
      return;
    }

    try {
      setState(() => isLoading = true);

      await uploadImages();

      final service = InventoryService();

      await service.addService(
        name: nameController.text,
        price: double.parse(priceController.text),
        description: descController.text,
        imageUrls: uploadedUrls,
        parentId: widget.parentId,
      );

      setState(() => isLoading = false);

      Navigator.pop(context);
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll("Exception:", "").trim(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.addService),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// SERVICE NAME
              TextField(
                controller: nameController,
                cursorColor: const Color(0xFF2563EB),
                style: const TextStyle(color: Colors.black),
                decoration:
                    inputStyle(AppLocalizations.of(context)!.serviceName),
              ),

              const SizedBox(height: 18),

              /// PRICE
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                cursorColor: const Color(0xFF2563EB),
                style: const TextStyle(color: Colors.black),
                decoration: inputStyle(AppLocalizations.of(context)!.price),
              ),

              const SizedBox(height: 18),

              /// DESCRIPTION
              TextField(
                controller: descController,
                maxLines: 4,
                cursorColor: const Color(0xFF2563EB),
                style: const TextStyle(color: Colors.black),
                decoration:
                    inputStyle(AppLocalizations.of(context)!.description),
              ),

              const SizedBox(height: 24),

              /// ADD PHOTOS BUTTON
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF3B82F6),
                        Color(0xFF2563EB),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: Text("Add Photos (${selectedImages.length}/5)"),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// IMAGE PREVIEW
              if (selectedImages.isNotEmpty)
                Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: PageView.builder(
                        itemCount: selectedImages.length,
                        onPageChanged: (index) {
                          setState(() {
                            currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                selectedImages[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        selectedImages.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: currentImageIndex == index ? 10 : 6,
                          height: currentImageIndex == index ? 10 : 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentImageIndex == index
                                ? Colors.blue
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 30),

              /// SAVE SERVICE BUTTON
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF3B82F6),
                        Color(0xFF2563EB),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : saveService,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.white,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            AppLocalizations.of(context)!.saveService,
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
