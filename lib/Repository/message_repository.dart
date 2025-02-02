import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/message_model.dart';

class MessageRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> saveMessage(Message message, {File? imageFile, File? file, File? audioFile}) async {
    // Upload files if any
    String? imageUrl;
    String? fileUrl;
    String? audioUrl;

    if (imageFile != null) {
      imageUrl = await _uploadFile(imageFile, 'images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    }
    if (file != null) {
      fileUrl = await _uploadFile(file, 'files/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}');
    }
    if (audioFile != null) {
      audioUrl = await _uploadFile(audioFile, 'audio/${DateTime.now().millisecondsSinceEpoch}.mp3');
    }

    // Update message with file URLs
    final updatedMessage = message.copyWith(
      imageUrl: imageUrl,
      fileUrl: fileUrl,
      audioUrl: audioUrl,
    );

    // Save message to Firestore
    await _firestore.collection('AllMessages').doc(updatedMessage.id).set(updatedMessage.toJson());
  }

  Future<String> _uploadFile(File file, String path) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }
}