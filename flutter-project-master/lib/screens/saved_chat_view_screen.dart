import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/saved_chat.dart';

/// Screen to view a saved chat conversation
class SavedChatViewScreen extends StatelessWidget {
  final SavedChat savedChat;

  const SavedChatViewScreen({
    super.key,
    required this.savedChat,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF131416)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              savedChat.title,
              style: const TextStyle(
                color: Color(0xFF131416),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Urbanist',
              ),
            ),
            Text(
              DateFormat('MMM d, y • h:mm a').format(savedChat.savedAt),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontFamily: 'Urbanist',
              ),
            ),
          ],
        ),
        actions: [
          // Copy all text
          IconButton(
            icon: const Icon(Icons.copy_all, color: Color(0xFF155DFC)),
            onPressed: () => _copyAllMessages(context),
            tooltip: 'Copy all',
          ),
          // Share/Export
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF155DFC)),
            onPressed: () => _shareChat(context),
            tooltip: 'Share',
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFF7F8FA),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Color(0xFF616161),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Archived conversation • ${savedChat.messageCount} messages',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF616161),
                      fontFamily: 'Urbanist',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: savedChat.messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(savedChat.messages[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(SavedMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bot avatar on left
          if (!message.isUser) ...[
            Container(
              width: 37,
              height: 37,
              decoration: const ShapeDecoration(
                color: Color(0xFF141718),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: ShapeDecoration(
                color: message.isUser
                    ? const Color(0xFF155DFC)
                    : const Color(0xFFF7F7F8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: message.isUser 
                        ? const Radius.circular(12) 
                        : const Radius.circular(2),
                    bottomRight: message.isUser 
                        ? const Radius.circular(2) 
                        : const Radius.circular(12),
                  ),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser 
                      ? Colors.white 
                      : const Color(0xFF2E2E2E),
                  fontSize: 14,
                  fontFamily: 'Urbanist',
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
          ),
          
          // Spacing
          if (message.isUser)
            const SizedBox(width: 50)
          else
            const SizedBox(width: 50),
        ],
      ),
    );
  }

  void _copyAllMessages(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('Conversation: ${savedChat.title}');
    buffer.writeln('Saved: ${DateFormat('MMM d, y • h:mm a').format(savedChat.savedAt)}');
    buffer.writeln('=' * 50);
    buffer.writeln();

    for (final message in savedChat.messages) {
      buffer.writeln('${message.isUser ? "You" : "Medi-Bot"}:');
      buffer.writeln(message.text);
      buffer.writeln();
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Copied to clipboard'),
          ],
        ),
        backgroundColor: Color(0xFF155DFC),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareChat(BuildContext context) {
    // For now, just copy to clipboard
    // You can integrate share_plus package for native sharing
    _copyAllMessages(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard! You can now paste and share.'),
        duration: Duration(seconds: 3),
      ),
    );
  }
}