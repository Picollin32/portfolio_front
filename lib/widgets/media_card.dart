import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/media_item_model.dart';

class MediaCard extends StatefulWidget {
  final MediaItem item;
  final bool showGenre;
  final double width;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const MediaCard({super.key, required this.item, this.showGenre = false, this.width = 200, this.onTap, this.onDelete});

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _elevationAnimation = Tween<double>(begin: 4.0, end: 12.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap:
                  widget.onTap ??
                  () {
                    Navigator.pushNamed(context, widget.item.detailPath, arguments: widget.item.id);
                  },
              child: SizedBox(
                width: widget.width,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: _elevationAnimation.value,
                  shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        Expanded(
                          flex: 3,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildImage(),
                              // Overlay gradient when hovered
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: _isHovered ? 1.0 : 0.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                                    ),
                                  ),
                                ),
                              ),
                              // Badge
                              if (widget.item.badge != null)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    constraints: const BoxConstraints(maxWidth: 110),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                          blurRadius: _isHovered ? 12 : 6,
                                          spreadRadius: _isHovered ? 2 : 0,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      widget.item.badge!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.2,
                                        height: 1.2,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.clip,
                                    ),
                                  ),
                                ),
                              // Delete button
                              if (widget.onDelete != null)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 200),
                                    scale: _isHovered ? 1.0 : 0.0,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: widget.onDelete,
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade600,
                                            shape: BoxShape.circle,
                                            boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)],
                                          ),
                                          child: const Icon(Icons.delete, color: Colors.white, size: 18),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Content
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.item.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 13, height: 1.2),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                // Rating stars with animation
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(5, (index) {
                                    return TweenAnimationBuilder<double>(
                                      duration: Duration(milliseconds: 300 + (index * 50)),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: Icon(
                                            index < widget.item.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                            size: 14,
                                            color:
                                                index < widget.item.rating
                                                    ? Theme.of(context).colorScheme.primary
                                                    : Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                          ),
                                        );
                                      },
                                    );
                                  }),
                                ),
                                const SizedBox(height: 4),
                                // Type, Genre, Year
                                if (widget.showGenre && widget.item.genre != null)
                                  Text(
                                    '${widget.item.typeLabel} • ${widget.item.genre}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, height: 1.1),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                else
                                  Text(
                                    '${widget.item.typeLabel} • ${widget.item.year ?? ""}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, height: 1.1),
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
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImage() {
    // Check if it's a local file path (starts with 'data:' for base64 or '/' for file path)
    if (widget.item.image.startsWith('data:')) {
      // Handle base64 images (from image picker) safely
      try {
        final comma = widget.item.image.indexOf(',');
        if (comma != -1) {
          final data = widget.item.image.substring(comma + 1);
          final bytes = base64Decode(data);
          return Image.memory(bytes, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildPlaceholder());
        }
      } catch (_) {}
      return _buildPlaceholder();
    } else if (widget.item.image.startsWith('/') || widget.item.image.contains('\\')) {
      // Handle file system paths
      return Image.file(File(widget.item.image), fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildPlaceholder());
    } else if (widget.item.image.startsWith('assets/')) {
      // Handle asset images
      return Image.asset(widget.item.image, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildPlaceholder());
    } else {
      // Handle network images
      return Image.network(widget.item.image, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildPlaceholder());
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.grey[850]!, Colors.grey[900]!]),
      ),
      child: Center(child: Icon(Icons.image_not_supported_rounded, size: 48, color: Colors.grey[700])),
    );
  }
}
