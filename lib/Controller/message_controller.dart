import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import 'package:webchat/AuthService/auth_service.dart';
import 'package:webchat/Controller/user_controller.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/connections.dart';
import '../models/message_model.dart';


class MessageController extends GetxController {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GenerativeModel aiModel = GenerativeModel(model: 'gemini-pro', apiKey: 'AIzaSyCXAZx3pjfbHYWeMKUH05ntaY6dm6cWol8');

  RxList<Message> messages = <Message>[].obs;
  TextEditingController messgTextController= TextEditingController();
  RxString messageText = ''.obs;
  Rx<dynamic> selectedFile = Rx<dynamic>(null);
  RxString selectedFileName = ''.obs;
  RxBool isImage = false.obs;
  Rx<User?> currentUser = Rx<User?>(null);
  UserController userController = Get.find();

  var myConnections = <Connection>[].obs;
  var onGoingConversation = <Message>[].obs;
  var onGoingConversationFiles = <Map<String, String>>[].obs;

  var selectedConnection = <Connection>[].obs;

  var sending = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMessages();
  }

  void fetchMessages() {
    _firestore.collection('AllMessages')
        .orderBy('sendTime', descending: true)
        .snapshots()
        .listen((snapshot) {
      messages.value = snapshot.docs
          .where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['receiverId'] == AuthService().currentUser?.uid || data['senderId'] == AuthService().currentUser?.uid;
      })
          .map((doc) => Message.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      updateConnections();
      if(selectedConnection.isNotEmpty) {
        getConversation();
      }
    });
  }

  void updateConnections() {
    myConnections.clear();
    myConnections.add(Connection(
      id: 'gemini_ai',
      name: 'Gemini AI',
      image: 'https://cdn-wp.bulksignature.com/wp-content/uploads/2024/02/Frame-876-1024x569.png',
      lastMessage: '',
      lastMessageTime: DateTime.now(),
    ));
    myConnections.addAll(getConnections(AuthService().currentUser?.uid ?? ''));
  }

  void getConversation({bool isAI = false}) {
    onGoingConversation.clear();
    onGoingConversationFiles.clear();
    String userId1 = AuthService().currentUser?.uid ?? '';
    String userId2 = selectedConnection.isNotEmpty ? selectedConnection[0].id : '';

    if (isAI) {
      // For AI, filter messages where receiverId or senderId is 'gemini_ai'
      onGoingConversation.value = messages.where((message) =>
      message.senderId == 'gemini_ai' || message.receiverId == 'gemini_ai'
      ).toList();
    } else {
      onGoingConversation.value = messages.where((message) =>
      (message.senderId == userId1 && message.receiverId == userId2) ||
          (message.senderId == userId2 && message.receiverId == userId1)
      ).toList();
    }

    onGoingConversation.sort((b, a) => a.sendTime.compareTo(b.sendTime));

    onGoingConversationFiles.value = onGoingConversation
        .where((message) => message.imageUrl != null || message.fileUrl != null)
        .map((message) => {
      'fileType': message.imageUrl != null ? 'image' : 'file',
      'file': message.imageUrl ?? message.fileUrl ?? '',
    })
        .toList();
  }

  List<Connection> getConnections(String myId) {
    Map<String, Connection> connectionsMap = {};

    for (var message in messages) {
      if (message.senderId == 'gemini_ai' || message.receiverId == 'gemini_ai') continue;

      String connectionId, connectionName, connectionImage;
      if (message.senderId == myId) {
        connectionId = message.receiverId;
        connectionName = message.receiverName;
        connectionImage = message.receiverImage;
      } else {
        connectionId = message.senderId;
        connectionName = message.senderName;
        connectionImage = message.senderImage;
      }

      if (!connectionsMap.containsKey(connectionId) ||
          message.sendTime.isAfter(connectionsMap[connectionId]!.lastMessageTime)) {
        connectionsMap[connectionId] = Connection(
          id: connectionId,
          name: connectionName,
          image: connectionImage,
          lastMessage: message.messageBody,
          lastMessageTime: message.sendTime,
        );
      }
    }

    List<Connection> connections = connectionsMap.values.toList();
    connections.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

    return connections;
  }

  Future<void> pickFile(bool pickImage) async {
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: pickImage ? FileType.image : FileType.any,
      );
      if (result != null) {
        selectedFile.value = result.files.first.bytes;
        selectedFileName.value = result.files.first.name;
        isImage.value = pickImage;
      }
    } else {
      if (pickImage) {
        final ImagePicker _picker = ImagePicker();
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          selectedFile.value = File(image.path);
          selectedFileName.value = path.basename(image.path);
          isImage.value = true;
        }
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles();
        if (result != null) {
          selectedFile.value = File(result.files.single.path!);
          selectedFileName.value = result.files.single.name;
          isImage.value = false;
        }
      }
    }
  }

  void clearSelectedFile() {
    selectedFile.value = null;
    selectedFileName.value = '';
    isImage.value = false;
  }

  Future<void> sendMessage({required Map<String, dynamic> receiverData, required String messageBody, bool isSentByAI = false}) async {
    sending.value = true;
    if (AuthService().currentUser == null && !isSentByAI) {
      print('User not authenticated');
      sending.value = false;
      return;
    }

    if (messageText.value.isEmpty && selectedFile.value == null && messageBody == null) {
      sending.value = false;
      return;
    }

    String? fileUrl;
    if (selectedFile.value != null) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString() + '_' + selectedFileName.value;
      String firebasePath = isImage.value ? 'images/$fileName' : 'files/$fileName';

      try {
        TaskSnapshot uploadTask;
        if (kIsWeb) {
          uploadTask = await _storage.ref(firebasePath).putData(selectedFile.value);
        } else {
          uploadTask = await _storage.ref(firebasePath).putFile(selectedFile.value);
        }
        fileUrl = await uploadTask.ref.getDownloadURL();
      } catch (e) {
        print('Error uploading file: $e');
        Get.snackbar('Error', 'Failed to upload file. Please try again.');
        sending.value = false;
        return;
      }
    }

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      messageBody: messageBody,
      senderId: isSentByAI ? 'gemini_ai' : AuthService().currentUser!.uid,
      receiverId: receiverData["userId"],
      senderName: isSentByAI ? "Gemini AI" : AuthService().currentUser!.displayName ?? "Anonymous",
      receiverName: receiverData["name"],
      senderImage: isSentByAI ? "https://cdn-wp.bulksignature.com/wp-content/uploads/2024/02/Frame-876-1024x569.png" : AuthService().currentUser!.photoURL ?? "",
      receiverImage: receiverData["imageUrl"],
      imageUrl: isImage.value ? fileUrl : null,
      fileUrl: !isImage.value ? fileUrl : null,
      sendTime: DateTime.now(),
    );

    try {
      await _firestore.collection('AllMessages').doc(message.id).set(message.toJson());
      messageText.value = '';
      clearSelectedFile();
    } catch (e) {
      print('Error saving message: $e');
      Get.snackbar('Error', 'Failed to send message. Please try again.');
    }
    sending.value = false;
  }

  String getMimeType(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
  Future<void> sendAIMessage(String userMessage) async {
    // Send user message
    await sendMessage(
      receiverData: {
        "userId": "gemini_ai",
        "name": "Gemini AI",
        "imageUrl": "https://cdn-wp.bulksignature.com/wp-content/uploads/2024/02/Frame-876-1024x569.png",
      },
      messageBody: userMessage,
    );

    // Generate AI response
    try {
      final content = [Content.text(userMessage)];
      final response = await aiModel.generateContent(content);

      // Send AI response
      await sendMessage(
        receiverData: {
          "userId": AuthService().currentUser?.uid ?? "",
          "name": AuthService().currentUser?.displayName ?? "User",
          "imageUrl": AuthService().currentUser?.photoURL ?? "",
        },
        messageBody: response.text ?? "Sorry, I couldn't generate a response.",
        isSentByAI: true,
      );
    } catch (e) {
      print('Error generating AI response: $e');
      await sendMessage(
        receiverData: {
          "userId": AuthService().currentUser?.uid ?? "",
          "name": AuthService().currentUser?.displayName ?? "User",
          "imageUrl": AuthService().currentUser?.photoURL ?? "",
        },
        messageBody: "Sorry, I encountered an error while generating a response.",
        isSentByAI: true,
      );
    }
  }

void updateMessageText(String text)
{
  messageText.value=text;
}

  @override
  void onClose() {
    super.onClose();
  }
}