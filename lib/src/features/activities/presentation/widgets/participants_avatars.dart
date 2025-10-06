import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../friends/domain/entities/friend.dart';
import '../../domain/entities/activity.dart';

class ParticipantsAvatars extends StatelessWidget {
  final Activity activity;
  final int maxAvatars;
  final double avatarSize;
  final VoidCallback? onTap;

  const ParticipantsAvatars({
    super.key,
    required this.activity,
    this.maxAvatars = 3,
    this.avatarSize = 28,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final confirmedCount = activity.confirmedParticipantsCount;

    if (confirmedCount == 0) {
      return const SizedBox.shrink();
    }

    if (confirmedCount == 1) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 4),
              Text(
                '1 pessoa',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final confirmed = activity.participants
        .where((p) => p.status == ParticipantStatus.accepted)
        .take(maxAvatars)
        .toList();

    final remaining = confirmedCount - confirmed.length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (confirmed.isNotEmpty)
              SizedBox(
                height: avatarSize,
                width: _calculateWidth(confirmed.length),
                child: Stack(
                  children: [
                    for (int i = 0; i < confirmed.length; i++)
                      Positioned(
                        left: i * (avatarSize * 0.6),
                        child: _buildAvatar(confirmed[i]),
                      ),
                  ],
                ),
              ),

            const SizedBox(width: 8),

            Text(
              '$confirmedCount pessoas',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.blue[700],
              ),
            ),

            if (remaining > 0) ...[
              const SizedBox(width: 4),
              Text(
                '(+$remaining)',
                style: TextStyle(fontSize: 11, color: Colors.blue[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _calculateWidth(int count) {
    if (count == 0) return 0;
    if (count == 1) return avatarSize;
    return avatarSize + ((count - 1) * avatarSize * 0.6);
  }

  Widget _buildAvatar(EventParticipant participant) {
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        color: Colors.grey[300],
      ),
      child: ClipOval(
        child: participant.photoUrl != null
            ? CachedNetworkImage(
                imageUrl: participant.photoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) =>
                    _buildInitialsAvatar(participant),
              )
            : _buildInitialsAvatar(participant),
      ),
    );
  }

  Widget _buildInitialsAvatar(EventParticipant participant) {
    final initials = participant.name.isNotEmpty
        ? participant.name[0].toUpperCase()
        : '?';

    return Container(
      color: _getColorForInitial(initials),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getColorForInitial(String initial) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.cyan,
    ];

    final index = initial.codeUnitAt(0) % colors.length;
    return colors[index];
  }
}
