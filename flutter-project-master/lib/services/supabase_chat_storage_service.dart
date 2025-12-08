import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/saved_chat.dart';

/// Supabase-based chat storage service
/// Stores chat archives in cloud database with automatic sync
class SupabaseChatStorageService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Save a chat conversation to cloud
  static Future<void> saveChat(SavedChat chat) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      await _supabase.from('saved_chats').insert({
        'id': chat.id,
        'user_id': user.id,
        'title': chat.title,
        'messages': chat.messages.map((m) => m.toMap()).toList(),
        'message_count': chat.messageCount,
        'saved_at': chat.savedAt.toIso8601String(),
      });

      print('💾 Saved chat to cloud: ${chat.title}');
    } catch (e) {
      print('❌ Error saving chat: $e');
      rethrow;
    }
  }

  /// Get all saved chats for current user
  static Future<List<SavedChat>> getAllChats() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('⚠️ No user logged in');
      return [];
    }

    try {
      final response = await _supabase
          .from('saved_chats')
          .select()
          .eq('user_id', user.id)
          .order('saved_at', ascending: false);

      final chats = (response as List).map((data) {
        return SavedChat(
          id: data['id'],
          userId: data['user_id'],
          title: data['title'],
          messages: (data['messages'] as List)
              .map((m) => SavedMessage.fromMap(Map<String, dynamic>.from(m)))
              .toList(),
          savedAt: DateTime.parse(data['saved_at']),
          messageCount: data['message_count'],
        );
      }).toList();

      print('📚 Retrieved ${chats.length} chats from cloud');
      return chats;
    } catch (e) {
      print('❌ Error loading chats: $e');
      return [];
    }
  }

  /// Get a specific chat by ID
  static Future<SavedChat?> getChatById(String id) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('saved_chats')
          .select()
          .eq('id', id)
          .eq('user_id', user.id)
          .single();

      return SavedChat(
        id: response['id'],
        userId: response['user_id'],
        title: response['title'],
        messages: (response['messages'] as List)
            .map((m) => SavedMessage.fromMap(Map<String, dynamic>.from(m)))
            .toList(),
        savedAt: DateTime.parse(response['saved_at']),
        messageCount: response['message_count'],
      );
    } catch (e) {
      print('❌ Error loading chat: $e');
      return null;
    }
  }

  /// Delete a saved chat
  static Future<void> deleteChat(String id) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('saved_chats')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);

      print('🗑️ Deleted chat: $id');
    } catch (e) {
      print('❌ Error deleting chat: $e');
      rethrow;
    }
  }

  /// Delete all saved chats for current user
  static Future<void> deleteAllChats() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('saved_chats')
          .delete()
          .eq('user_id', user.id);

      print('🗑️ Deleted all chats for user');
    } catch (e) {
      print('❌ Error deleting chats: $e');
      rethrow;
    }
  }

  /// Get count of saved chats
  static Future<int> getChatCount() async {
    final chats = await getAllChats();
    return chats.length;
  }

  /// Update chat title
  static Future<void> updateChatTitle(String id, String newTitle) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('saved_chats')
          .update({'title': newTitle})
          .eq('id', id)
          .eq('user_id', user.id);

      print('✏️ Updated chat title: $newTitle');
    } catch (e) {
      print('❌ Error updating title: $e');
      rethrow;
    }
  }

  /// Search chats by title
  static Future<List<SavedChat>> searchChats(String query) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('saved_chats')
          .select()
          .eq('user_id', user.id)
          .ilike('title', '%$query%')
          .order('saved_at', ascending: false);

      final chats = (response as List).map((data) {
        return SavedChat(
          id: data['id'],
          userId: data['user_id'],
          title: data['title'],
          messages: (data['messages'] as List)
              .map((m) => SavedMessage.fromMap(Map<String, dynamic>.from(m)))
              .toList(),
          savedAt: DateTime.parse(data['saved_at']),
          messageCount: data['message_count'],
        );
      }).toList();

      print('🔍 Found ${chats.length} chats matching "$query"');
      return chats;
    } catch (e) {
      print('❌ Error searching chats: $e');
      return [];
    }
  }

  /// Listen to real-time changes (optional)
  static Stream<List<SavedChat>> watchChats() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('saved_chats')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('saved_at', ascending: false)
        .map((data) {
          return data.map((chat) {
            return SavedChat(
              id: chat['id'],
              userId: chat['user_id'],
              title: chat['title'],
              messages: (chat['messages'] as List)
                  .map((m) => SavedMessage.fromMap(Map<String, dynamic>.from(m)))
                  .toList(),
              savedAt: DateTime.parse(chat['saved_at']),
              messageCount: chat['message_count'],
            );
          }).toList();
        });
  }
}