import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  final String _cloudName = 'dxpufap96';
  final String _uploadPreset = 'straycare';

  Future<String> uploadImage(File imageFile) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonMap = jsonDecode(responseString);

      if (response.statusCode == 200) {
        return jsonMap['secure_url'];
      } else {
        throw Exception(
          'Failed to upload image: ${jsonMap['error']['message']}',
        );
      }
    } catch (e) {
      throw Exception('Error uploading image to Cloudinary: $e');
    }
  }
}
