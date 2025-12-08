import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/settings_icon_button.dart';
import '../models/saved_chat.dart';
import '../services/supabase_chat_storage_service.dart';
import '../services/supabase_auth_service.dart';
import 'saved_chat_view_screen.dart';

/// Search/Archive screen to view all saved chat conversations
class SearchContent extends StatefulWidget {
  const SearchContent({super.key});

  @override
  State<SearchContent> createState() => _SearchContentState();
}

class _SearchContentState extends State<SearchContent> {
  List<SavedChat> _savedChats = [];
  List<SavedChat> _filteredChats = [];
  final TextEditingController _searchController = TextEditingController();
  String? _currentUserId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  // Reload when page becomes visible
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSavedChats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await SupabaseAuthService.getCurrentUser();
    setState(() {
      _currentUserId = user?.email;
    });
    _loadSavedChats();
  }

  Future<void> _loadSavedChats() async {
    if (_currentUserId == null) {
      setState(() {
        _savedChats = [];
        _filteredChats = [];
        _isLoading = false;
      });
      print('🔍 No user logged in, showing no chats');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Supabase automatically filters by current user
    final chats = await SupabaseChatStorageService.getAllChats();

    setState(() {
      _savedChats = chats;
      _filteredChats = chats;
      _isLoading = false;
    });
    print(
        '🔍 Search page: Loaded ${_savedChats.length} saved chats for $_currentUserId');
  }

  void _filterChats(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredChats = _savedChats;
      } else {
        _filteredChats = _savedChats
            .where((chat) =>
                chat.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _deleteChat(SavedChat chat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Chat?'),
        content: Text('Are you sure you want to delete "${chat.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SupabaseChatStorageService.deleteChat(chat.id);
      _loadSavedChats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat deleted')),
        );
      }
    }
  }

  void _viewChat(SavedChat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavedChatViewScreen(savedChat: chat),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE1E1E1), width: 1),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterChats,
                style: const TextStyle(
                  fontFamily: 'Urbanist',
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Search saved chats...',
                  hintStyle: const TextStyle(
                    color: Color(0xFFA3A3A8),
                    fontFamily: 'Urbanist',
                  ),
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF616161)),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            // Chat count
            if (_filteredChats.isNotEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: const Color(0xFFF7F8FA),
                child: Text(
                  '${_filteredChats.length} saved conversation${_filteredChats.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF616161),
                    fontFamily: 'Urbanist',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // Chat list or empty state
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredChats.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadSavedChats,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _filteredChats.length,
                            itemBuilder: (context, index) {
                              return _buildChatCard(_filteredChats[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
        const SettingsIconButton(),
      ],
    );
  }

  Widget _buildEmptyState() {
    // If user not logged in, show login prompt
    if (_currentUserId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.login,
                size: 50,
                color: Color(0xFF616161),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Please Login',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF131416),
                fontFamily: 'Urbanist',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Login to save and view\nyour chat conversations',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF616161),
                fontFamily: 'Urbanist',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF155DFC),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Go to Login',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Urbanist',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // User is logged in but has no saved chats
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.bookmark_border,
              size: 50,
              color: Color(0xFF616161),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Saved Chats',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF131416),
              fontFamily: 'Urbanist',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Save important conversations\nto access them later',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF616161),
              fontFamily: 'Urbanist',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatCard(SavedChat chat) {
    final dateFormat = DateFormat('MMM d, y • h:mm a');

    // Get preview text from first message
    String preview = '';
    if (chat.messages.isNotEmpty) {
      final firstMsg = chat.messages.first.text;
      preview =
          firstMsg.length > 80 ? '${firstMsg.substring(0, 80)}...' : firstMsg;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE1E1E1), width: 1),
      ),
      child: InkWell(
        onTap: () => _viewChat(chat),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF155DFC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF155DFC),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      chat.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF131416),
                        fontFamily: 'Urbanist',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Preview
                    if (preview.isNotEmpty)
                      Text(
                        preview,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF616161),
                          fontFamily: 'Urbanist',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),

                    // Date and message count
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(chat.savedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'Urbanist',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.chat,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${chat.messageCount} messages',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'Urbanist',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteChat(chat),
                tooltip: 'Delete chat',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
