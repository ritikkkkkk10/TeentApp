import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tent_app/core/config/app_config.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/utils/image_compressor.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ServiceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> serviceData;
  final String serviceId;

  const ServiceDetailScreen({
    super.key,
    required this.serviceData,
    required this.serviceId,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final ImagePicker _picker = ImagePicker();
  int currentImageIndex = 0;

  List<String> imageUrls = [];
  List<File> newImages = [];

  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController descController;

  void openImageViewer(ImageProvider imageProvider) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image(
              image: imageProvider,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.serviceData["name"]);

    priceController =
        TextEditingController(text: widget.serviceData["price"].toString());

    descController =
        TextEditingController(text: widget.serviceData["description"] ?? "");

    imageUrls = List<String>.from(
      widget.serviceData["imageUrls"] ?? [],
    );
  }

  Future<void> updateService() async {
    String businessId = await getBusinessId();

    List<String> updatedImages = List.from(imageUrls);

    /// upload new images
    for (File file in newImages) {
      String? url = await CloudinaryService.uploadImage(file);

      if (url != null) {
        updatedImages.add(url);
      }
    }

    await FirebaseFirestore.instance
        .collection("businesses")
        .doc(businessId)
        .collection("inventoryNodes")
        .doc(widget.serviceId)
        .update({
      "name": nameController.text,
      "price": double.parse(priceController.text),
      "description": descController.text,
      "imageUrls": updatedImages,
    });

    Navigator.pop(context);
  }

  Future<void> pickImage() async {
    int remaining = 5 - (imageUrls.length + newImages.length);

    if (remaining <= 0) return;

    final List<XFile> picked = await _picker.pickMultiImage();

    if (picked.isEmpty) return;

    for (var img in picked.take(remaining)) {
      File file = File(img.path);

      File? compressed = await compressImage(file);

      if (compressed != null) {
        newImages.add(compressed);
      }
    }

    setState(() {});
  }

  Future<void> deleteService() async {
    String businessId = await getBusinessId();

    await FirebaseFirestore.instance
        .collection("businesses")
        .doc(businessId)
        .collection("inventoryNodes")
        .doc(widget.serviceId)
        .delete();

    Navigator.pop(context);
  }

  Widget sectionCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.serviceDetails),
        backgroundColor: Colors.blue.shade600,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// SERVICE NAME
              sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.serviceName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// PRICE ROW
              sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.price,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text(
                          "₹",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// DESCRIPTION
              sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.description,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// IMAGE PREVIEW
              if (imageUrls.isNotEmpty || newImages.isNotEmpty)
                SizedBox(
                  height: 220,
                  child: PageView(
                    onPageChanged: (index) {
                      setState(() {
                        currentImageIndex = index;
                      });
                    },
                    children: [
                      ...imageUrls.map((url) {
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: GestureDetector(
                                    onTap: () {
                                      openImageViewer(NetworkImage(url));
                                    },
                                    child: Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                    ),
                                  )),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    imageUrls.remove(url);
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      }),
                      ...newImages.map((file) {
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: GestureDetector(
                                    onTap: () {
                                      openImageViewer(FileImage(file));
                                    },
                                    child: Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                    ),
                                  )),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    newImages.remove(file);
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),

              const SizedBox(height: 10),

              /// DOT INDICATOR
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  imageUrls.length + newImages.length,
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

              const SizedBox(height: 18),

              /// ADD PHOTOS BUTTON (GRADIENT)
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1976D2),
                        Color(0xFF42A5F5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: Text(
                      AppLocalizations.of(context)!.addPhotos(imageUrls.length + newImages.length),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 26),

              /// UPDATE + DELETE BUTTONS
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: updateService,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(AppLocalizations.of(context)!.update),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: deleteService,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(AppLocalizations.of(context)!.delete),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
