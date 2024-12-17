import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class QRImageOverlay extends StatefulWidget {
  final String imageUrl;
  final List<Offset> qrCodeCorners;

  const QRImageOverlay({
    Key? key,
    required this.imageUrl,
    required this.qrCodeCorners,
  }) : super(key: key);

  @override
  State<QRImageOverlay> createState() => _QRImageOverlayState();
}

class _QRImageOverlayState extends State<QRImageOverlay> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _loadImageFromNetwork();
  }

  Future<void> _loadImageFromNetwork() async {
    try {
      print("Fetching image from URL: ${widget.imageUrl}");
      final response = await http.get(Uri.parse(widget.imageUrl));

      if (response.statusCode == 200) {
        print("Image fetched successfully. Decoding...");

        final bytes = response.bodyBytes;
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();

        setState(() {
          _image = frame.image;
        });
        print("Image decoded successfully. Dimensions: ${_image?.width}x${_image?.height}");
      } else {
        print("Failed to fetch image. HTTP Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error loading image: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Image Overlay')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Overlay'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomPaint(
        painter: ImageOverlayPainter(
          image: _image!,
          corners: widget.qrCodeCorners,
        ),
      ),
    );
  }
}

class ImageOverlayPainter extends CustomPainter {
  final ui.Image image;
  final List<Offset> corners;

  ImageOverlayPainter({
    required this.image,
    required this.corners,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.high;

    if (corners.length != 4) {
      print('Invalid corners detected, expected 4 points.');
      return;
    }

    final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final path = Path()..addPolygon(corners, true);

    // Clip the canvas to the destination path and draw the image
    canvas.save();
    canvas.clipPath(path);
    canvas.drawImageRect(image, srcRect, path.getBounds(), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

