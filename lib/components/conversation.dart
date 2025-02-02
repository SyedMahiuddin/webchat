import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webchat/AuthService/auth_service.dart';
import 'package:webchat/Controller/user_controller.dart';
import '../Controller/message_controller.dart';
import '../helpers/color_helper.dart';
import '../helpers/space_helper.dart';
import '../common/common_components.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/connections.dart';
import '../models/message_model.dart';

class ConversationScreen extends StatelessWidget {
  ConversationScreen({Key? key}) : super(key: key);

  final MessageController messageController = Get.put(MessageController());
  final UserController userController = Get.put(UserController());
  final GenerativeModel model = GenerativeModel(model: 'gemini-pro', apiKey: 'AIzaSyCXAZx3pjfbHYWeMKUH05ntaY6dm6cWol8');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorHelper.backgroundColor,
      body: Obx(() {
        if (AuthService().currentUser == null) {
          return Center(child: CommonComponents.appText("Please login to start chatting"));
        }

        // Set initial chat to Gemini AI if no connection is selected
        if (messageController.selectedConnection.isEmpty) {
          messageController.selectedConnection.add(Connection(
            id: 'gemini_ai',
            name: 'Gemini AI',
            image: 'https://cdn-wp.bulksignature.com/wp-content/uploads/2024/02/Frame-876-1024x569.png',
            lastMessage: '',
            lastMessageTime: DateTime.now(),
          ));
          messageController.getConversation(isAI: true);
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: messageController.onGoingConversation.length,
                itemBuilder: (context, index) {
                  final message = messageController.onGoingConversation[index];
                  bool isSent = message.senderId == AuthService().currentUser?.uid;
                  bool isAI = messageController.selectedConnection.isNotEmpty &&
                      messageController.selectedConnection[0].id == 'gemini_ai' &&
                      !isSent;
                  return _buildMessageItem(message, isSent, isAI);
                },
              ),
            ),
            _buildInputArea(),
          ],
        );
      }),
    );
  }


  Widget _buildMessageItem(Message message, bool isSent, bool isAI) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSent)
            Padding(
              padding: EdgeInsets.only(left: 8.w, top: 8.h),
              child: CircleAvatar(
                backgroundImage: NetworkImage(isAI ? 'https://cdn-wp.bulksignature.com/wp-content/uploads/2024/02/Frame-876-1024x569.png' :
                "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRZqAAoo7Gog69U-B0Sa-2Fuvl_vNu4vaUDwA&s"),
                radius: 16.r,
              ),
            ),
          Column(
            crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              _buildMessageContent(message, isSent),
              Padding(
                padding: EdgeInsets.only(
                  left: SpaceHelper.medium,
                  right: SpaceHelper.medium,
                  bottom: SpaceHelper.small,
                ),
                child: CommonComponents.appText(
                  DateFormat('HH:mm').format(message.sendTime ?? DateTime.now()),
                  textStyle: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(Message message, bool isSent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
         message.messageBody!=""?
          Container(
            width: 250.w,
            margin: EdgeInsets.symmetric(
              vertical: SpaceHelper.small,
              horizontal: SpaceHelper.medium,
            ),
            padding: EdgeInsets.all(SpaceHelper.small),
            decoration: BoxDecoration(
              color: isSent ? ColorHelper.sentMessageColor : ColorHelper.receivedMessageColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: CommonComponents.appText(message.messageBody ?? ''),
          ):SizedBox(),
        if (message.imageUrl != null)
          _buildImageMessage(message),
        if (message.fileUrl != null)
          _buildFileMessage(message),
      ],
    );
  }

  Widget _buildImageMessage(Message message) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(message.imageUrl ?? ''),
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: SpaceHelper.small,
          horizontal: SpaceHelper.medium,
        ),
        padding: EdgeInsets.all(SpaceHelper.small),
        height: 120.h,
        width: 160.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Image.network(
            message.imageUrl ?? '',
            height: 120.h,
            width: 160.w,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  Widget _buildFileMessage(Message message) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(message.fileUrl ?? '')),
      child: Container(
        padding: EdgeInsets.all(SpaceHelper.small),
        child: Icon(Icons.folder, size: 50.sp),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.all(16),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: Get.height - 30.h,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
              ),
            ),
            Positioned(
              top: -12,
              right: -12,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.black, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Column(
      children: [
        Obx(() {
          if (messageController.selectedFileName.value.isNotEmpty) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: SpaceHelper.medium, vertical: SpaceHelper.small),
              color: Colors.grey[800],
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      messageController.selectedFileName.value,
                      style: TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                 Obx(()=> messageController.sending.value?CircularProgressIndicator():
                 IconButton(
                   icon: Icon(Icons.close, color: Colors.white),
                   onPressed: messageController.clearSelectedFile,
                 ),)
                ],
              ),
            );
          }
          return SizedBox.shrink();
        }),
        Padding(
          padding: EdgeInsets.all(SpaceHelper.medium),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.attach_file),
                onPressed: () => messageController.pickFile(false),
                color: ColorHelper.primaryColor,
              ),
              IconButton(
                icon: Icon(Icons.image),
                onPressed: () => messageController.pickFile(true),
                color: ColorHelper.primaryColor,
              ),
              Expanded(
                child: Obx(() => TextField(
                  controller: messageController.messgTextController,
                  onChanged: (value) {
                    messageController.messageText.value = value;
                    messageController.updateMessageText(value);
                  },
                  onSubmitted: messageController.sending.value ? null : (value) {
                    _sendMessage();
                    messageController.messageText.value = "";
                    messageController.messgTextController.text = "";
                  },
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(fontSize: 15.sp, color: Colors.white),
                    filled: true,
                    fillColor: Colors.white12,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                )),
              ),
              SizedBox(width: SpaceHelper.small),
              Obx(() => IconButton(
                icon: Icon(Icons.send),
                onPressed: messageController.sending.value ? null : () {
                  _sendMessage();
                  messageController.messageText.value = "";
                  messageController.messgTextController.text = "";
                },
                color: ColorHelper.primaryColor,
              )),
            ],
          ),
        ),
      ],
    );
  }

  void _sendMessage() async {
    if (messageController.messageText.value.isEmpty && messageController.selectedFile.value == null) return;

    if (messageController.selectedConnection.isNotEmpty &&
        messageController.selectedConnection[0].id == 'gemini_ai') {
      await _sendAIMessage();
    } else {
      await _sendUserMessage();
    }
    messageController.updateMessageText("");
    messageController.clearSelectedFile();
  }

  Future<void> _sendAIMessage() async {
    final userMessage = messageController.messageText.value;
    List<Part> parts = [];

    // Add text content
    if (userMessage.isNotEmpty) {
      parts.add(TextPart(userMessage));
    }

    // Handle file content (only for images)
    if (messageController.selectedFile.value != null && messageController.isImage.value) {
      try {
        final bytes = messageController.selectedFile.value as Uint8List;
        final mimeType = messageController.getMimeType(messageController.selectedFileName.value);
        parts.add(DataPart(mimeType, bytes));
      } catch (e) {
        print('Error processing image file: $e');
        Get.snackbar('Error', 'Failed to process the image. Please try again.');
        return;
      }
    }

    // If no content to send, return early
    if (parts.isEmpty) return;

    // Create the Content object
    final content = Content.multi(parts);

    // Send user message
    await messageController.sendMessage(
      receiverData: {
        'userId': 'gemini_ai',
        'name': 'Gemini AI',
        'imageUrl': 'https://cdn-wp.bulksignature.com/wp-content/uploads/2024/02/Frame-876-1024x569.png',
      },
      messageBody: messageController.messageText.value
    );

    // Generate and send AI response
    try {
      final response = await model.generateContent([content]);
      await messageController.sendMessage(
        receiverData: {
          'userId': AuthService().currentUser?.uid ?? '',
          'name': AuthService().currentUser?.displayName ?? 'User',
          'imageUrl': AuthService().currentUser?.photoURL ?? '',
        },
        messageBody: response.text ?? 'Sorry, I couldn\'t generate a response.',
        isSentByAI: true,
      );
    } catch (e) {
      print('Error generating AI response: $e');
      await messageController.sendMessage(
        receiverData: {
          'userId': AuthService().currentUser?.uid ?? '',
          'name': AuthService().currentUser?.displayName ?? 'User',
          'imageUrl': AuthService().currentUser?.photoURL ?? '',
        },
        messageBody: 'Sorry, I encountered an error while generating a response.',
        isSentByAI: true,
      );
    }

    // Clear the selected file after sending
    messageController.clearSelectedFile();
  }

  Future<void> _sendUserMessage() async {
    if (messageController.selectedConnection.isEmpty) return;

    final receiverData = userController.allUsers.firstWhere(
          (user) => user["userId"] == messageController.selectedConnection[0].id,
    );

    await messageController.sendMessage(
      receiverData: receiverData,
      messageBody: messageController.messageText.value
    );
  }
}