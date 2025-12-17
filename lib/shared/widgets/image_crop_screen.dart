import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:path_provider/path_provider.dart';

class ImageCropScreen extends StatefulWidget {
  final File imageFile;

  const ImageCropScreen({Key? key, required this.imageFile}) : super(key: key);

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  final CropController _cropController = CropController();
  Uint8List? _imageBytes;
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    setState(() {
      _imageBytes = bytes;
    });
  }

  void _onCrop() {
    setState(() => _isCropping = true);
    _cropController.crop();
  }

  Future<void> _onCropped(Uint8List croppedData) async {
    // Save cropped image to temp file
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
      '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await tempFile.writeAsBytes(croppedData);

    if (mounted) {
      Navigator.pop(context, tempFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B46C1),
        title: const Text(
          'Crop Profile Picture',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isCropping)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: _onCrop,
            ),
          if (_isCropping)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: _imageBytes == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Crop(
                    controller: _cropController,
                    image: _imageBytes!,
                    aspectRatio: 1,
                    withCircleUi: true,
                    baseColor: Colors.black,
                    maskColor: Colors.black.withOpacity(0.7),
                    cornerDotBuilder: (size, edgeAlignment) => Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B46C1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    onCropped: _onCropped,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Drag to adjust • Pinch to zoom',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ),
              ],
            ),
    );
  }
}
