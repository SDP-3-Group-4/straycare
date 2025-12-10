import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile(File file, String folder) async {
    // Connectivity check
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('Connectivity check passed: google.com is reachable');
      }
    } catch (e) {
      print('Connectivity check failed: $e');
      throw Exception(
        'No internet connection. Please check your network settings.',
      );
    }

    try {
      final fileName = path.basename(file.path);
      final destination =
          '$folder/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final ref = _storage.ref(destination);

      print('Starting upload to: $destination');
      print('File size: ${await file.length()} bytes');

      final uploadTask = ref.putFile(file);

      uploadTask.snapshotEvents.listen(
        (event) {
          print(
            'Upload progress: ${event.bytesTransferred} / ${event.totalBytes}',
          );
        },
        onError: (e) {
          print('Upload stream error: $e');
        },
      );

      final snapshot = await uploadTask.whenComplete(() {});
      print('Upload task completed. State: ${snapshot.state}');
      print(
        'Bytes transferred: ${snapshot.bytesTransferred} / ${snapshot.totalBytes}',
      );

      if (snapshot.state == TaskState.success) {
        // Double check if bytes match
        if (snapshot.bytesTransferred == 0 && snapshot.totalBytes > 0) {
          throw Exception('Upload failed: 0 bytes transferred.');
        }

        try {
          final url = await snapshot.ref.getDownloadURL();
          print('Download URL: $url');
          return url;
        } catch (e) {
          print('Error getting download URL: $e');
          // If we can't get the URL, the upload might have "succeeded" locally but failed to sync?
          // Or the file is not there.
          throw Exception('Failed to get download URL: $e');
        }
      } else {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }
    } catch (e) {
      print('Error in uploadFile: $e');
      throw Exception('Error uploading file: $e');
    }
  }
}
