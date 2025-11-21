import 'package:flutter/material.dart';
import 'dart:convert';

class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String fallbackText;
  final double radius;
  final Color? backgroundColor;

  const UserAvatar({super.key, this.photoUrl, required this.fallbackText, this.radius = 24, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.primary;

    // Se tem foto, renderiza a imagem
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(radius: radius, backgroundColor: bgColor, child: ClipOval(child: _buildImage(photoUrl!, bgColor)));
    }

    // Fallback para inicial do nome
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
        style: TextStyle(fontSize: radius * 0.75, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildImage(String imageUrl, Color bgColor) {
    // Base64 image
    if (imageUrl.startsWith('data:')) {
      try {
        final comma = imageUrl.indexOf(',');
        if (comma != -1) {
          final data = imageUrl.substring(comma + 1);
          final bytes = base64Decode(data);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: radius * 2,
            height: radius * 2,
            errorBuilder: (context, error, stackTrace) {
              return _fallbackIcon(bgColor);
            },
          );
        }
      } catch (e) {
        return _fallbackIcon(bgColor);
      }
    }

    // Network image
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: radius * 2,
        height: radius * 2,
        errorBuilder: (context, error, stackTrace) {
          return _fallbackIcon(bgColor);
        },
      );
    }

    return _fallbackIcon(bgColor);
  }

  Widget _fallbackIcon(Color bgColor) {
    return Container(color: bgColor, child: Icon(Icons.person, size: radius, color: Colors.white.withOpacity(0.7)));
  }
}
