import 'package:hive_flutter/hive_flutter.dart';
import '../models/saved_chat.dart';

/// Service for managing saved/archived chats
class ChatStorageService {
  static const String _boxName = 'saved_chats';
  static Box? _box;

  /// Initialize Hive (call in main.dart)
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    print('✅ Hive initialized: ${_box!.length} saved chats found');
  }

  /// Save a chat conversation
  static Future<void> saveChat(SavedChat chat) async {
    if (_box == null) {
      print('❌ Error: Hive not initialized! Call ChatStorageService.init() in main.dart');
      throw Exception('ChatStorageService not initialized');
    }
    await _box!.put(chat.id, chat.toMap());
    print('💾 Saved chat: ${chat.title}');
  }

  /// Get all saved chats for a specific user
  static List<SavedChat> getAllChats({String? userId}) {
    if (_box == null) {
      print('❌ Error: Hive not initialized!');
      return [];
    }
    
    final chats = <SavedChat>[];
    for (var key in _box!.keys) {
      try {
        final data = _box!.get(key);
        if (data != null) {
          // Convert dynamic map to SavedChat
          final chat = SavedChat.fromMap(data as Map<dynamic, dynamic>);
          
          // Filter by userId if provided
          if (userId == null || chat.userId == userId) {
            chats.add(chat);
          }
        }
      } catch (e) {
        print('⚠️ Error loading chat $key: $e');
      }
    }
    // Sort by savedAt date (newest first)
    chats.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    print('📚 Retrieved ${chats.length} chats from storage${userId != null ? " for user $userId" : ""}');
    return chats;
  }

  /// Get all saved chats (backward compatibility)
  @Deprecated('Use getAllChats(userId: email) instead')
  static List<SavedChat> getAllChatsLegacy() {
    return getAllChats();
  }

  /// Get a specific chat by ID
  static SavedChat? getChatById(String id) {
    if (_box == null) return null;
    
    try {
      final data = _box!.get(id);
      if (data != null) {
        return SavedChat.fromMap(data as Map<dynamic, dynamic>);
      }
    } catch (e) {
      print('⚠️ Error loading chat $id: $e');
    }
    return null;
  }

  /// Delete a saved chat
  static Future<void> deleteChat(String id) async {
    await _box!.delete(id);
  }

  /// Delete all saved chats (optionally for specific user)
  static Future<void> deleteAllChats({String? userId}) async {
    if (_box == null) return;
    
    if (userId != null) {
      // Delete only chats for this user
      final userChats = getAllChats(userId: userId);
      for (var chat in userChats) {
        await _box!.delete(chat.id);
      }
      print('🗑️ Deleted ${userChats.length} chats for user $userId');
    } else {
      // Delete all chats
      await _box!.clear();
      print('🗑️ Deleted all chats');
    }
  }

  /// Get count of saved chats (optionally for specific user)
  static int getChatCount({String? userId}) {
    if (userId != null) {
      return getAllChats(userId: userId).length;
    }
    return _box?.length ?? 0;
  }
}