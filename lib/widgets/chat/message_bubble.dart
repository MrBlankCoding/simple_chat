import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/message_model.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: Row(
        mainAxisAlignment: isCurrentUser 
          ? MainAxisAlignment.end 
          : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isCurrentUser) const Spacer(flex: 1),
          Flexible(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
                vertical: AppConstants.paddingSmall,
              ),
              decoration: BoxDecoration(
                color: isCurrentUser 
                  ? AppConstants.primaryColor 
                  : AppConstants.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppConstants.borderRadiusMedium),
                  topRight: const Radius.circular(AppConstants.borderRadiusMedium),
                  bottomLeft: Radius.circular(
                    isCurrentUser ? AppConstants.borderRadiusMedium : AppConstants.borderRadiusSmall,
                  ),
                  bottomRight: Radius.circular(
                    isCurrentUser ? AppConstants.borderRadiusSmall : AppConstants.borderRadiusMedium,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.type == MessageType.image)
                    _buildImageContent()
                  else
                    _buildTextContent(),
                  
                  const SizedBox(height: 4),
                  
                  // Message metadata
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppHelpers.formatMessageTime(message.timestamp),
                        style: AppConstants.caption.copyWith(
                          color: isCurrentUser 
                            ? CupertinoColors.white.withOpacity(0.7)
                            : CupertinoColors.secondaryLabel,
                        ),
                      ),
                      if (message.isEdited) ...[
                        const SizedBox(width: 4),
                        Text(
                          '• edited',
                          style: AppConstants.caption.copyWith(
                            color: isCurrentUser 
                              ? CupertinoColors.white.withOpacity(0.7)
                              : CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.readBy.length > 1 
                            ? CupertinoIcons.checkmark_alt_circle_fill
                            : CupertinoIcons.checkmark_circle,
                          size: 12,
                          color: CupertinoColors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (!isCurrentUser) const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    return Text(
      message.text,
      style: AppConstants.bodyMedium.copyWith(
        color: isCurrentUser 
          ? CupertinoColors.white 
          : CupertinoColors.label,
      ),
    );
  }

  Widget _buildImageContent() {
    if (message.imageUrl == null || message.imageUrl!.isEmpty) {
      return _buildTextContent();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          child: CachedNetworkImage(
            imageUrl: message.imageUrl!,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 200,
              height: 200,
              color: CupertinoColors.systemGrey5,
              child: const Center(
                child: CupertinoActivityIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: 200,
              height: 200,
              color: CupertinoColors.systemGrey5,
              child: const Center(
                child: Icon(
                  CupertinoIcons.photo,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ),
          ),
        ),
        if (message.text.isNotEmpty && message.text != 'Photo') ...[
          const SizedBox(height: 8),
          _buildTextContent(),
        ],
      ],
    );
  }
}
