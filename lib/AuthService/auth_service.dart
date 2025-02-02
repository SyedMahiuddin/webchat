import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'dart:html' as html;

import 'package:webchat/AuthService/auth_dialogue.dart';

class AuthService extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Rx<html.File?> imageFile = Rx<html.File?>(null);

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  void handleImageSelected(html.FileUploadInputElement uploadInput) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      imageFile.value = files.first;
    }
  }

  Future<String> uploadImageToStorage(html.File imageFile) async {
    final storagePath = 'user_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference storageRef = _storage.ref().child(storagePath);
    UploadTask uploadTask = storageRef.putBlob(imageFile);
    TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
    String imageUrl = await snapshot.ref.getDownloadURL();
    return imageUrl;
  }

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } catch (e) {
      print('Error in signInWithEmailAndPassword: $e');
      rethrow;
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      log("userId: ${userCredential.user!.uid}");

      String imageUrl = '';
      if (imageFile.value != null) {
        imageUrl = await uploadImageToStorage(imageFile.value!);
      }
      else{
        imageUrl = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRZqAAoo7Gog69U-B0Sa-2Fuvl_vNu4vaUDwA&s";
      }

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'userId': userCredential.user!.uid,
        'email': email,
        'name': name,
        'imageUrl': imageUrl,
      });

      await userCredential.user!.updateDisplayName(name);
      await userCredential.user!.updatePhotoURL(imageUrl);

      return userCredential;
    } catch (e) {
      print('Error in createUserWithEmailAndPassword: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    Get.offAll(AuthDialog());
  }

  Future<void> updateProfile({required String uid, String? name}) async {
    try {
      if (name != null && name.isNotEmpty) {
        await _auth.currentUser!.updateDisplayName(name);
        await _firestore.collection('users').doc(uid).update({'name': name});
      }

      if (imageFile.value != null) {
        String imageUrl = await uploadImageToStorage(imageFile.value!);
        await _auth.currentUser!.updatePhotoURL(imageUrl);
        await _firestore.collection('users').doc(uid).update({'imageUrl': imageUrl});
      }
    } catch (e) {
      print('Error in updateProfile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      print('Error in getUserData: $e');
      rethrow;
    }
  }
}