import 'package:flutter/material.dart';
import 'package:flutter_application_2/services/chat/chat_service.dart';
import 'package:flutter_application_2/themes/theme_provider.dart';
import 'package:provider/provider.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentuser;
  final String messageId;
  final String userId;
  final String? mediaURL;    // Media URL, optional
  final String? mediaType;   // Media type ('image', 'video'), optional

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentuser,
    required this.messageId,
    required this.userId,
    this.mediaURL,          // Optional mediaURL
    this.mediaType,         // Optional mediaType
  });

  void _showOptions(BuildContext context, String messageId, String userId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.flag),
                title: const Text('Report'),
                onTap: () {
                  Navigator.pop(context);
                  _reportMessage(context, messageId, userId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Block User'),
                onTap: () {
                  Navigator.pop(context);
                  _blockUser(context, userId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              )
            ],
          ),
        );
      },
    );
  }

  void _reportMessage(BuildContext context, String messageId, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Message'),
        content: const Text('Are you sure you want to report this message'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ChatService().reportUser(messageId, userId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report has been sent')),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _blockUser(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: const Text('Are you sure you want to block this user'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ChatService().blockUser(userId);
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User blocked')),
              );
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    return GestureDetector(
      onLongPress: () {
        if (!isCurrentuser) {
          _showOptions(context, messageId, userId);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 15.0),
        child: Column(
          crossAxisAlignment: isCurrentuser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // If media exists, show the media
            if (mediaURL != null && mediaType == 'image')
              Container(
                margin: const EdgeInsets.only(bottom: 5.0),
                child: Image.network(
                  mediaURL!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else if (mediaURL != null && mediaType == 'video')
              Container(
                margin: const EdgeInsets.only(bottom: 5.0),
                child: const Text('Video message (to be implemented)'), // Placeholder for video
              ),
            
            // Show the message text
            Container(
              decoration: BoxDecoration(
                color: isCurrentuser
                    ? (isDarkMode ? Colors.green.shade600 : Colors.green.shade500)
                    : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(14),
              child: Text(
                message,
                style: TextStyle(
                  color: isCurrentuser
                      ? Colors.white
                      : (isDarkMode ? Colors.white : Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
