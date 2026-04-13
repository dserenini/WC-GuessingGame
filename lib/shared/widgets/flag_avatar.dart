import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FlagAvatar extends StatelessWidget {
  final String? flagUrl;
  final double radius;

  const FlagAvatar({super.key, this.flagUrl, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: flagUrl != null
            ? CachedNetworkImage(
                imageUrl: flagUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _placeholder(context),
                errorWidget: (_, __, ___) => _placeholder(context),
              )
            : _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Text('🏳️', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
