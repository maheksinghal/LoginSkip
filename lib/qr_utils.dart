import 'dart:typed_data';
import 'dart:ui';
import 'package:http/http.dart' as http;

class QRUtils {
  static Future<bool> isImageUrl(String url) async {
    print("Validating URL: $url");

    try {
      // Attempt HEAD request first
      final headResponse = await http.head(Uri.parse(url));

      // Check Content-Type header in HEAD response
      final contentType = headResponse.headers['content-type'];
      print("HEAD Content-Type: $contentType");

      if (contentType != null && contentType.startsWith('image/')) {
        print("URL is a valid image via HEAD");
        return true;
      }

      // Fallback to GET request if HEAD response is inconclusive
      print("HEAD request failed, falling back to GET request...");
      final getResponse = await http.get(Uri.parse(url));

      // Check Content-Type in GET response
      final getContentType = getResponse.headers['content-type'];
      print("GET Content-Type: $getContentType");

      if (getContentType != null && getContentType.startsWith('image/')) {
        print("URL is a valid image via GET");
        return true;
      }

      // Validate by attempting to parse as image bytes
      final Uint8List bytes = getResponse.bodyBytes;
      if (bytes.isNotEmpty) {
        print("Image bytes fetched successfully, assuming valid image");
        return true;
      }
    } catch (e) {
      print("Error validating URL: $e");
    }

    print("URL is not a valid image");
    return false;
  }
  static List<Offset> extractQRCorners(dynamic result) {
    // This is a placeholder implementation. You'll need to adapt this
    // based on your QR code scanner's actual data structure
    return [
      Offset(result.corners[0].dx, result.corners[0].dy),
      Offset(result.corners[1].dx, result.corners[1].dy),
      Offset(result.corners[2].dx, result.corners[2].dy),
      Offset(result.corners[3].dx, result.corners[3].dy),
    ];
  }

}
