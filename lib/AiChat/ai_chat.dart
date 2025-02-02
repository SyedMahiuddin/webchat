import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'chat_model.dart';
import 'controller.dart';
import 'db_service.dart';

class GeminiAIChat extends StatelessWidget {
  final ChatController chatController = Get.find<ChatController>();
  final DBService dbService = DBService();
  final GenerativeModel model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: 'AIzaSyCXAZx3pjfbHYWeMKUH05ntaY6dm6cWol8'
  );

  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Obx(() => ListView.builder(
            itemCount: chatController.chatMessages.length,
            itemBuilder: (context, index) {
              final message = chatController.chatMessages[index];
              return _buildMessageItem(message);
            },
          )),
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    return Align(
      alignment: message.isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.all(8),
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: message.isFromUser ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message.text ?? ''),
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () => _sendMessage(_textController.text),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) async {
    if (text.isEmpty) return;

    // User message
    final userMessage = ChatMessage(
      text: text,
      isFromUser: true,
      timestamp: DateTime.now(),
    );
    await dbService.insertChatMessage(userMessage);
    chatController.addMessage(userMessage);

    _textController.clear();

    // AI response
    try {
      final content = [Content.text(text)];
      final response = await model.generateContent(content);

      final aiMessage = ChatMessage(
        text: response.text,
        isFromUser: false,
        timestamp: DateTime.now(),
      );
      await dbService.insertChatMessage(aiMessage);
      chatController.addMessage(aiMessage);
    } catch (e) {
      print('Error generating AI response: $e');
      // Handle error (e.g., show an error message to the user)
    }
  }
}