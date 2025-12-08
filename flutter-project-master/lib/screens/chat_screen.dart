import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../widgets/settings_icon_button.dart';
import '../services/api_service.dart';
import '../models/saved_chat.dart';
import '../services/supabase_chat_storage_service.dart';
import '../services/supabase_auth_service.dart';

// Message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// Main chat interface screen
// Shows AI capability cards and message input field
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  final List<String> _capabilities = [
    'Remembers what user said earlier in the conversation',
    'Allows user to provide follow-up questions and corrections',
    'Trained to decline inappropriate requests',
    'May occasionally generate incorrect information',
    'Limited knowledge of world and events after 2023',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isLoading = false;
  
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isLoading) return;
    
    String userMessage = _messageController.text.trim();
    _messageController.clear();
    
    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
      ));
      _isLoading = true;
    });
    _scrollToBottom();
    
    // Call Flask API
    try {
      String response = await ApiService.sendMessage(userMessage);
      
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Sorry, I could not connect to the server. Please try again.',
          isUser: false,
        ));
        _isLoading = false;
      });
    }
    
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Pull-to-refresh to clear chat
  Future<void> _onPullToRefresh() async {
    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep, color: Color(0xFF155DFC)),
            SizedBox(width: 8),
            Text('Clear Chat?'),
          ],
        ),
        content: const Text('This will clear all messages and conversation history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Clear on server
      await ApiService.clearConversation();
      
      // Clear locally
      setState(() {
        _messages.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Chat cleared'),
              ],
            ),
            backgroundColor: Color(0xFF155DFC),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Save current chat to archive
  Future<void> _saveCurrentChat() async {
    if (_messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No messages to save')),
      );
      return;
    }

    // Get current user
    final currentUser = await SupabaseAuthService.getCurrentUser();
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to save chats')),
      );
      return;
    }

    // Generate title from first user message or use timestamp
    String title;
    final firstUserMsg = _messages.firstWhere(
      (m) => m.isUser,
      orElse: () => _messages.first,
    );
    
    if (firstUserMsg.text.length > 40) {
      title = '${firstUserMsg.text.substring(0, 40)}...';
    } else {
      title = firstUserMsg.text;
    }

    // Show dialog to edit title
    final TextEditingController titleController = TextEditingController(text: title);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.bookmark, color: Color(0xFF155DFC)),
            SizedBox(width: 8),
            Text('Save Chat'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Give this conversation a title:'),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              autofocus: true,
              style: const TextStyle(
                fontFamily: 'Urbanist',
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'e.g., Diabetes Information',
                hintStyle: const TextStyle(
                  color: Color(0xFFA3A3A8),
                  fontFamily: 'Urbanist',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE1E1E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF155DFC), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              maxLength: 50,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF155DFC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && titleController.text.isNotEmpty) {
      // Convert messages to SavedMessage format
      final savedMessages = _messages.map((m) => SavedMessage(
        text: m.text,
        isUser: m.isUser,
        timestamp: m.timestamp,
      )).toList();

      // Create SavedChat (userId is handled by Supabase automatically)
      final savedChat = SavedChat(
        id: const Uuid().v4(),
        userId: currentUser.email, // Keep for local model compatibility
        title: titleController.text.trim(),
        messages: savedMessages,
        savedAt: DateTime.now(),
        messageCount: _messages.length,
      );

      // Save to storage
      await SupabaseChatStorageService.saveChat(savedChat);
      print('💾 Chat saved! ID: ${savedChat.id}, Title: "${savedChat.title}", User: ${savedChat.userId}');
      final chatCount = await SupabaseChatStorageService.getChatCount();
      print('📊 Total saved chats for ${currentUser.email}: $chatCount');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Saved "${titleController.text.trim()}"'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF155DFC),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to search page to view saved chats
                DefaultTabController.of(context).animateTo(1); // Index 1 = Search tab
              },
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Header with save/clear buttons (only show when messages exist)
            if (_messages.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE1E1E1), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Medi-Bot',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Urbanist',
                      ),
                    ),
                    Row(
                      children: [
                        // Save button
                        IconButton(
                          icon: const Icon(Icons.bookmark_border, color: Color(0xFF155DFC)),
                          onPressed: _saveCurrentChat,
                          tooltip: 'Save chat',
                        ),
                        // Clear button
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: _onPullToRefresh,
                          tooltip: 'Clear chat',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Header with logo (only show when no messages)
            if (_messages.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/FullLogo_Transparent.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Medi-Bot',
                      style: TextStyle(
                        color: Color(0xFF131416),
                        fontSize: 24,
                        fontFamily: 'Urbanist',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

            // Message list or capability cards
            Expanded(
              child: _messages.isEmpty
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // Diagnosis Mode Button
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushNamed('/diagnosis');
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF155DFC),
                                    Color(0xFF1E6FFF),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF155DFC).withOpacity(0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.health_and_safety_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Start Diagnosis',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontFamily: 'Urbanist',
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Get AI-powered health assessment',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 13,
                                            fontFamily: 'Urbanist',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          const Text(
                            'Capabilities',
                            style: TextStyle(
                              color: Color(0xFF616161),
                              fontSize: 16,
                              fontFamily: 'Urbanist',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._capabilities.map((capability) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildCapabilityCard(capability),
                              )),
                          const SizedBox(height: 20),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF155DFC),
                      backgroundColor: Colors.white,
                      onRefresh: _onPullToRefresh,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(_messages[index]);
                        },
                      ),
                    ),
            ),

            // Message input field at bottom
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFE1E1E1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                          side: const BorderSide(
                            color: Color(0xFFE1E1E1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(
                          color: Color(0xFF323142),
                          fontSize: 16,
                          fontFamily: 'Urbanist',
                          fontWeight: FontWeight.w400,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Send a message.',
                          hintStyle: TextStyle(
                            color: Color(0xFFA3A3A8),
                            fontSize: 16,
                            fontFamily: 'Urbanist',
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        maxLines: null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _isLoading ? null : _sendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: ShapeDecoration(
                        color: _isLoading ? Colors.grey : const Color(0xFF155DFC),
                        shape: const CircleBorder(),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Settings icon button
        const SettingsIconButton(),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                    ? const Color(0xFF155DFC)  // Blue for user messages
                    : const Color(0xFFF7F7F8), // Gray for bot messages
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: message.isUser ? const Radius.circular(12) : const Radius.circular(2),
                    bottomRight: message.isUser ? const Radius.circular(2) : const Radius.circular(12),
                  ),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : const Color(0xFF2E2E2E),
                  fontSize: 14,
                  fontFamily: 'Urbanist',
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
          ),
          // Spacing on the opposite side to prevent full width
          if (message.isUser)
            const SizedBox(width: 50)
          else
            const SizedBox(width: 50),
        ],
      ),
    );
  }

  Widget _buildCapabilityCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: ShapeDecoration(
        color: const Color(0xFFF5F5F5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF155DFC),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF323142),
                fontSize: 14,
                fontFamily: 'Urbanist',
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}