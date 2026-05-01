import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/player.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

/// Circular player photo with an optional name label below.
class PlayerAvatarWidget extends StatelessWidget {
  final Player player;
  final double size;
  final bool showName;
  final Color? borderColor;
  final VoidCallback? onTap;

  const PlayerAvatarWidget({
    super.key,
    required this.player,
    this.size = 44,
    this.showName = false,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final posColor = getPositionColor(player.elementType);
    final border = borderColor ?? posColor;
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.of(context).cardMedium,
        border: Border.all(color: border, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: player.photoUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => Icon(
          Icons.person,
          color: AppColors.of(context).textSecondary,
          size: size * 0.55,
        ),
        errorWidget: (_, __, ___) => Icon(
          Icons.person,
          color: AppColors.of(context).textSecondary,
          size: size * 0.55,
        ),
      ),
    );

    if (!showName) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          avatar,
          const SizedBox(height: 3),
          SizedBox(
            width: size + 8,
            child: Text(
              player.webName,
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
