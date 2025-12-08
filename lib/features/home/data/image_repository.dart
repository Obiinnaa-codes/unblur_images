import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

final imageRepositoryProvider = Provider<ImageRepository>((ref) {
  return ImageRepository(Supabase.instance.client);
});

class ImageRepository {
  final SupabaseClient _supabase;

  ImageRepository(this._supabase);

  /// Uploads image to Supabase Storage and returns the public URL
  Future<String> uploadImage(File file) async {
    final fileExt = path.extension(file.path);
    final fileName = '${const Uuid().v4()}$fileExt';
    final userId = _supabase.auth.currentUser!.id;
    final filePath = '$userId/$fileName';

    await _supabase.storage
        .from('images')
        .upload(
          filePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    final imageUrl = _supabase.storage.from('images').getPublicUrl(filePath);

    return imageUrl;
  }

  /// Calls the Edge Function to process the image
  Future<String> processImage(String imageUrl, String feature) async {
    final response = await _supabase.functions.invoke(
      'process-image',
      body: {'imageUrl': imageUrl, 'feature': feature},
    );

    final data = response.data;
    if (data != null && data['processedImageUrl'] != null) {
      return data['processedImageUrl'];
    } else {
      throw Exception(
        'Failed to process image: ${data?['error'] ?? 'Unknown error'}',
      );
    }
  }
}
