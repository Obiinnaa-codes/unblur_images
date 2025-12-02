import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class HomeRepository {
  final SupabaseClient _supabase;

  HomeRepository(this._supabase);

  Future<String> uploadImage(File imageFile) async {
    final fileExt = path.extension(imageFile.path);
    final fileName = '${const Uuid().v4()}$fileExt';
    final filePath = 'inputs/$fileName';

    await _supabase.storage
        .from('images')
        .upload(
          filePath,
          imageFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    return filePath;
  }

  Future<String> processImage(String imagePath, String featureType) async {
    final response = await _supabase.functions.invoke(
      'process_image',
      body: {'image_path': imagePath, 'feature_type': featureType},
    );

    final data = response.data;
    if (data != null && data['output_path'] != null) {
      return data['output_path'];
    } else {
      throw 'Failed to process image';
    }
  }
}
