import 'package:hive/hive.dart';

/// Model for saved/archived chat conversations
class SavedChat {
  final String id;
  final String userId; // Email of the user who saved this chat
  final String title;
  final List<SavedMessage> messages;
  final DateTime savedAt;
  final int messageCount;

  SavedChat({
    required this.id,
    required this.userId,
    required this.title,
    required this.messages,
    required this.savedAt,
    required this.messageCount,
  });

  // Convert to Map for Hive storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'messages': messages.map((m) => m.toMap()).toList(),
      'savedAt': savedAt.toIso8601String(),
      'messageCount': messageCount,
    };
  }

  // Create from Map (handles both Map<String, dynamic> and Map<dynamic, dynamic>)
  factory SavedChat.fromMap(Map<dynamic, dynamic> map) {
    return SavedChat(
      id: map['id'].toString(),
      userId: map['userId']?.toString() ?? '', // Handle old data without userId
      title: map['title'].toString(),
      messages: (map['messages'] as List)
          .map((m) => SavedMessage.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList(),
      savedAt: DateTime.parse(map['savedAt'].toString()),
      messageCount: map['messageCount'] as int,
    );
  }
}

/// Individual message in a saved chat
class SavedMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  SavedMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SavedMessage.fromMap(Map<String, dynamic> map) {
    return SavedMessage(
      text: map['text'].toString(),
      isUser: map['isUser'] as bool,
      timestamp: DateTime.parse(map['timestamp'].toString()),
    );
  }
}