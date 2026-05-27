import '../../../../core/network/dio_client.dart';

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;
  final bool isError;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.isError = false,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class AiChatRemoteDataSource {
  final DioClient dioClient;

  AiChatRemoteDataSource({required this.dioClient});

  Future<String> sendMessage(String message, List<ChatMessage> history) async {
    final historyPayload = history
        .where((m) => !m.isError)
        .toList();

    // Limit to last 10 messages (5 turns) to keep payload light
    final trimmed = historyPayload.length > 10
        ? historyPayload.sublist(historyPayload.length - 10)
        : historyPayload;

    final response = await dioClient.dio.post(
      '/ai/chat',
      data: {
        'message': message,
        'history': trimmed.map((m) => m.toJson()).toList(),
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data['reply'] as String;
    }

    throw Exception(
        response.data?['error'] ?? 'Failed to get response from Owl');
  }
}
