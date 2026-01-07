import 'dart:io';
import 'package:flutter/material.dart';
import 'package:unblur_images/core/utils/image_picker_utils.dart';
import 'package:unblur_images/core/utils/download_utils.dart';
import 'package:unblur_images/features/profile/presentation/profile_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unblur_images/features/paywall/data/usage_repository.dart';
import 'package:unblur_images/features/home/data/image_repository.dart';
import 'package:unblur_images/features/paywall/presentation/upgrade_to_pro_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  File? _selectedImage;
  bool _isUploading = false;
  String _selectedFeature = 'unblur'; // unblur, upscale, colorize
  Map<String, dynamic>? _subscriptionStatus;

  bool _isLoadingCredits = true;

  @override
  void initState() {
    super.initState();
    // Fetch initial credits when screen loads
    _fetchCredits();
  }

  /// Fetches latest credits and subscription status using the unified status function.
  Future<void> _fetchCredits() async {
    if (!mounted) return;
    setState(() => _isLoadingCredits = true);

    // Call the simplified usage status function (one of our two allowed repository functions)
    final status = await ref.read(usageRepositoryProvider).getUsageStatus();

    if (mounted) {
      setState(() {
        _subscriptionStatus = status;
        _isLoadingCredits = false;
      });
    }
  }

  /// Builds the widget to display credit balance or 'Pro' infinity icon.
  Widget _buildCreditsDisplay() {
    if (_isLoadingCredits) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // Extract credit and subscription from the unified status map
    final int credit = _subscriptionStatus?['credit'] ?? 0;
    final bool isSubscribed = _subscriptionStatus?['isSubscribed'] ?? false;

    // Use the fetched subscription status to determine UI
    if (isSubscribed) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.all_inclusive, // Premium infinity icon for Pro status
            color: Colors.deepPurple,
            size: 22,
          ),
          SizedBox(width: 4),
          Text(
            'Pro',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 16,
            ),
          ),
        ],
      );
    }

    // Show credit count for non-subscribers
    return Text(
      'Credits: $credit',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: Colors.black,
      ),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final image = await ImagePickerUtils.pickImageFromGallery();
                  if (image != null) {
                    setState(() {
                      _selectedImage = image;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final image = await ImagePickerUtils.pickImageFromCamera();
                  if (image != null) {
                    setState(() {
                      _selectedImage = image;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    // Check for credits
    // We check if the user has free credits available.
    // If hasFreeCredits returns false, it means the user has 0 credits left.
    try {
      final usageRepo = ref.read(usageRepositoryProvider);
      final hasCredits = await usageRepo.hasFreeCredits();

      if (!hasCredits) {
        if (!mounted) return;

        // Use a SnackBar (proper toast) to inform the user they have no active subscription or balance.
        // This is less intrusive than a dialog and follows the user's requirement.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'No active subscription or credits left. Upgrade to Pro for unlimited access.',
            ),
            action: SnackBarAction(
              label: 'Upgrade',
              onPressed: () async {
                // Navigate to the paywall screen if they choose to upgrade
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UpgradeToProScreen(),
                  ),
                );
                // Refresh credit/subscription state upon returning from the paywall
                _fetchCredits();
              },
            ),
            backgroundColor: Colors.orange[800],
            duration: const Duration(seconds: 4),
          ),
        );
        return; // Stop processing if no credits or subscription
      }
      // 1 upload user image to supabase bucket name images
      final imageRepo = ref.read(imageRepositoryProvider);
      final imageUrl = await imageRepo.uploadImage(_selectedImage!);

      // 2 get url of the image to pass to the edge fuction
      // (imageUrl is already the public URL)

      // 3 call edge function (get the exact feature the user wants to do with the image)
      // 4 get the result image from the edge function
      final processedImageUrl = await imageRepo.processImage(
        imageUrl,
        _selectedFeature,
      );

      // Refresh credits after usage, but only if the user is not on a Pro plan.
      // Pro users have unlimited access, so there's no need to refresh their balance.
      final bool isSubscribed = _subscriptionStatus?['isSubscribed'] ?? false;
      if (!isSubscribed) {
        _fetchCredits();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Processing complete!')));

      if (mounted) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(processedImageUrl),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Don't pop to allow multiple downloads if needed,
                        // or pop if desired. Let's keep it open.
                        DownloadUtils.downloadImage(context, processedImageUrl);
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unblur'),
        actions: [
          // Display Credits Balance or 'Unlimited'
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(child: _buildCreditsDisplay()),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              // Refresh credits when returning from profile (possible purchase)
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              _fetchCredits();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 300,
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey),
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 50,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10),
                            Text('Tap to add image'),
                          ],
                        )
                      : null,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _FeatureButton(
                      title: 'Unblur',
                      isSelected: _selectedFeature == 'unblur',
                      onTap: () => setState(() => _selectedFeature = 'unblur'),
                    ),
                    _FeatureButton(
                      title: '4K Upscale',
                      isSelected: _selectedFeature == 'upscale',
                      onTap: () => setState(() => _selectedFeature = 'upscale'),
                    ),
                    _FeatureButton(
                      title: 'Colorize',
                      isSelected: _selectedFeature == 'colorize',
                      onTap: () =>
                          setState(() => _selectedFeature = 'colorize'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _processImage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: _isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Generate'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _FeatureButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
