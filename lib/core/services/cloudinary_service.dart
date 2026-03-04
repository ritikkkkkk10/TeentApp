import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {

  static const cloudName = "dtna5vemb";
  static const uploadPreset = "tent_upload";

  static Future<String?> uploadImage(File file) async {

    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    var request = http.MultipartRequest("POST", url);

    request.fields["upload_preset"] = uploadPreset;
    request.fields["folder"] = "tent_app/services";

    request.files.add(
      await http.MultipartFile.fromPath("file", file.path),
    );

    var response = await request.send();

    if (response.statusCode == 200) {

      final res = await http.Response.fromStream(response);
      final data = jsonDecode(res.body);

      return data["secure_url"];
    }

    return null;
  }
}