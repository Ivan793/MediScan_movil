import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  final String cloudName = "drh88kp6w"; // tu cloud name
  final String uploadPreset = "flutter_unsigned"; // tu preset

  /// Sube una imagen a Cloudinary y devuelve SIEMPRE un String (URL)
  Future<String> uploadImage(File imageFile) async {
    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest("POST", url);

    request.fields["upload_preset"] = uploadPreset;

    request.files.add(
      await http.MultipartFile.fromPath("file", imageFile.path),
    );

    try {
      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      final data = jsonDecode(resBody);

      if (response.statusCode == 200) {
        if (data["secure_url"] == null) {
          throw Exception("Cloudinary no devolvió secure_url");
        }

        return data["secure_url"];
      } else {
        throw Exception("Error Cloudinary: $resBody");
      }
    } catch (e) {
      throw Exception("Error subiendo imagen a Cloudinary: $e");
    }
  }
}
