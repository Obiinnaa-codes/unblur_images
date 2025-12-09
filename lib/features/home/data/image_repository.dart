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

  /// Fetches the history of images uploaded by the current user from the 'images' table.
  Future<List<UserImage>> fetchUserHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return [];
      }

      final List<dynamic> data = await _supabase
          .from('images')
          .select('input_image, output_image, created_at, updated_at, feature')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return data.map((json) => UserImage.fromJson(json)).toList();
    } catch (e) {
      // In a real app, you might want to log this error to a service like Sentry.
      throw Exception('Error fetching user history: $e');
    }
  }
}

class UserImage {
  final String id;
  final String? inputImage;
  final String? outputImage;
  final String? feature;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserImage({
    required this.id,
    this.inputImage,
    this.outputImage,
    this.feature,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserImage.fromJson(Map<String, dynamic> json) {
    return UserImage(
      id: json['id']?.toString() ?? '',
      inputImage: json['input_image'] as String?,
      outputImage: json['output_image'] as String?,
      feature: json['feature'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  String? get imageUrl {
    final path = outputImage ?? inputImage;
    if (path == null) return null;

    return Supabase.instance.client.storage.from('images').getPublicUrl(path);
  }
}
