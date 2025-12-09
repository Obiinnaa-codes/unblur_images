import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unblur_images/features/home/data/image_repository.dart';
import 'package:intl/intl.dart';
import 'package:unblur_images/core/utils/download_utils.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageRepo = ref.watch(imageRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: FutureBuilder<List<UserImage>>(
        future: imageRepo.fetchUserHistory(),
        builder: (context, snapshot) {
          // Still loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // If we got an error
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final images = snapshot.data ?? [];

          // No history to show
          if (images.isEmpty) {
            return const Center(child: Text('No history found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: images.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final image = images[index];
              return _HistoryItem(image: image);
            },
          );
        },
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final UserImage image;

  const _HistoryItem({required this.image});

  @override
  Widget build(BuildContext context) {
    // IMPORTANT:
    // We now use the PROCESSED IMAGE instead of the original image.
    // This matches what the home screen downloads.
    final processedUrl = image.imageUrl;

    final feature = image.feature ?? 'Processed';
    final date = DateFormat.yMMMd().add_jm().format(image.createdAt);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =======================
            // THUMBNAIL (processed image)
            // =======================
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: processedUrl == null
                    ? Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      )
                    : Image.network(
                        processedUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // =======================
            // DETAILS
            // =======================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 8),

                  // Status tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Successful',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // =======================
            // DOWNLOAD BUTTON
            // =======================
            IconButton(
              icon: const Icon(Icons.download_rounded),
              onPressed: () {
                if (image.outputImage != null) {
                  // Download the PROCESSED image, not the original
                  DownloadUtils.downloadImage(context, image.outputImage!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Processed image not available'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
