import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/media_item_model.dart';

class MediaCard extends StatelessWidget {
  final MediaItem item;
  final bool showGenre;
  final double width;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const MediaCard({super.key, required this.item, this.showGenre = false, this.width = 200, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          onTap ??
          () {
            Navigator.pushNamed(context, item.detailPath, arguments: item.id);
          },
      child: SizedBox(
        width: width,
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image
              AspectRatio(
                aspectRatio: 2 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(),
                    // Badge
                    if (item.badge != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.3 * 255).toInt()), blurRadius: 4)],
                          ),
                          child: Text(item.badge!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    // Delete button (only if onDelete is provided)
                    if (onDelete != null)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onDelete,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.3 * 255).toInt()), blurRadius: 4)],
                              ),
                              child: const Icon(Icons.delete, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Content - Using Flexible to prevent overflow
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      // Rating stars
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < item.rating ? Icons.star : Icons.star_border,
                            size: 12,
                            color: index < item.rating ? Theme.of(context).colorScheme.primary : Theme.of(context).iconTheme.color,
                          );
                        }),
                      ),
                      const SizedBox(height: 2),
                      // Type, Genre, Year
                      if (showGenre && item.genre != null)
                        Text(
                          '${item.typeLabel} • ${item.genre}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          '${item.typeLabel} • ${item.year ?? ""}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    // Check if it's a local file path (starts with 'data:' for base64 or '/' for file path)
    if (item.image.startsWith('data:')) {
      // Handle base64 images (from image picker) safely
      try {
        final comma = item.image.indexOf(',');
        if (comma != -1) {
          final data = item.image.substring(comma + 1);
          final bytes = base64Decode(data);
          return Image.memory(bytes, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildPlaceholder());
        }
      } catch (_) {}
      return _buildPlaceholder();
    } else if (item.image.startsWith('/') || item.image.contains('\\')) {
      // Handle file system paths
      return Image.file(File(item.image), fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildPlaceholder());
    } else if (item.image.startsWith('assets/')) {
      // Handle asset images
      return Image.asset(item.image, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildPlaceholder());
    } else {
      // Handle network images
      return Image.network(item.image, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildPlaceholder());
    }
  }

  Widget _buildPlaceholder() {
    return Container(color: Colors.grey[800], child: const Center(child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey)));
  }
}
