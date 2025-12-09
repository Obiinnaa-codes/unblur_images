import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import 'package:flutter/foundation.dart';

class DownloadUtils {
  /// Downloads an image from [imageUrl] and saves it to the gallery.
  /// Shows SnackBars for success/error feedback.
  static Future<void> downloadImage(
    BuildContext context,
    String imageUrl,
  ) async {
    try {
      // 1. Check/Request permissions
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final access = await Gal.requestAccess();
        if (!access) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permission denied to save to gallery'),
              ),
            );
          }
          return;
        }
      }

      // 2. Download image bytes
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download image: ${response.statusCode} ${response.reasonPhrase}\nURL: $imageUrl',
        );
      }

      if (kDebugMode) {
        print('Download successful. Size: ${response.bodyBytes.length} bytes');
        print('Content-Type: ${response.headers['content-type']}');
      }

      // 3. Save to gallery
      await Gal.putImageBytes(
        Uint8List.fromList(response.bodyBytes),
        name: "unblur_image_${DateTime.now().millisecondsSinceEpoch}",
      );

      // 4. Show appropriate message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved to gallery!')),
        );
      }
    } on GalException catch (e) {
      debugPrint(
        'GalException: $e, Type: ${e.type}, Message: ${e.type.message}',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving image: ${e.type.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('Unexpected Error: $e\n$stack');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving image: $e')));
      }
    }
  }
}
