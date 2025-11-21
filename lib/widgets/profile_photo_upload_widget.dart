import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

class ProfilePhotoUploadWidget extends StatefulWidget {
  final String? imageUrl;
  final Function(String) onImageSelected;
  final double size;

  const ProfilePhotoUploadWidget({super.key, this.imageUrl, required this.onImageSelected, this.size = 100});

  @override
  State<ProfilePhotoUploadWidget> createState() => _ProfilePhotoUploadWidgetState();
}

class _ProfilePhotoUploadWidgetState extends State<ProfilePhotoUploadWidget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);

      if (image != null) {
        // Convert to base64 for storage
        final bytes = await image.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        widget.onImageSelected(base64Image);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: ClipOval(
              child:
                  widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                      ? _buildImage(widget.imageUrl!)
                      : Icon(Icons.person, size: widget.size * 0.5, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
              ),
              child: Icon(Icons.camera_alt, size: widget.size * 0.2, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('data:')) {
      try {
        final comma = imageUrl.indexOf(',');
        if (comma != -1) {
          final data = imageUrl.substring(comma + 1);
          final bytes = base64Decode(data);
          return Image.memory(bytes, fit: BoxFit.cover);
        }
      } catch (_) {}
      return Container(color: Colors.grey[800]);
    } else if (imageUrl.startsWith('/') || imageUrl.contains('\\')) {
      return Image.file(File(imageUrl), fit: BoxFit.cover);
    } else if (imageUrl.startsWith('assets/')) {
      return Image.asset(imageUrl, fit: BoxFit.cover);
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.person, size: widget.size * 0.5, color: Theme.of(context).colorScheme.primary.withOpacity(0.5));
        },
      );
    }
  }
}
