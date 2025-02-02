import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webchat/AuthService/auth_dialogue.dart';
import 'package:webchat/AuthService/auth_service.dart';
import 'package:webchat/screens/chat_screen.dart';

class UserController extends GetxController {
  var userInfo = [].obs;  // Observable map to store user information
  User? currentUser;

  @override
  void onInit() {
    super.onInit();
   // checkUserAndGetUserInfo();
    //checkUserAndGetUserInfo();
    listenToUsers();
  }

  var allUsers=[].obs;
  var filteredUsers = [].obs;

  void listenToUsers() {
    FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      // Update userList with the latest data
      allUsers.value = snapshot.docs.map((DocumentSnapshot doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();

      // Optionally, you can print or perform any other action with the updated list
      print("allUsers "+allUsers.length.toString());
    });
  }

  void filterUsers(String query) {
    if (query.isEmpty) {
      filteredUsers.value = allUsers;
    } else {
      filteredUsers.value = allUsers.where((user) =>
      user['name'].toLowerCase().contains(query.toLowerCase()) ||
          user['email'].toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
  }

  Future<void> checkUserAndGetUserInfo() async {
    currentUser = AuthService().currentUser;

    if (currentUser != null) {
        String userId = currentUser!.uid;
      DocumentSnapshot userDoc = await getUserDoc(userId);
      if (userDoc.exists) {
        userInfo.clear();
        userInfo.value.add(userDoc.data() as Map<String, dynamic>) ;
        print("user info2312 :"+userInfo.value.length.toString());
      } else {
        print("User document not found");
      }
    } else {
       //Get.offAll(AuthDialog());
    }
  }

  Future<DocumentSnapshot> getUserDoc(String userId) {
    return FirebaseFirestore.instance.collection('users').doc(userId).get();
  }

  Future<void> createUserWithEmailAndPassword(
      String email, String password, String name, XFile imageFile) async {
    try {
      // Create user with email and password
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      User? newUser = userCredential.user;

      if (newUser != null) {
        // Upload image and get the image URL
        String imageUrl = await uploadImage(imageFile, newUser.uid);

        // Create a document in the 'users' collection
        await FirebaseFirestore.instance.collection('users').doc(newUser.uid).set({
          'email': email,
          'name': name,
          'imageUrl': imageUrl,
          'uid': newUser.uid,
        });

        // Assign the user info to userInfo observable map
        userInfo.clear();
        userInfo.value.add({
          'email': email,
          'name': name,
          'imageUrl': imageUrl,
          'uid': newUser.uid,
        }) ;

        print('User created and stored in Firestore');
      }
    } catch (e) {
      print('Error creating user: $e');
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> loginWithEmailAndPassword(
      String email, String password) async {
    try {
      // Attempt to login with email and password
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      User? loggedInUser = userCredential.user;

      if (loggedInUser != null) {
        String userId = loggedInUser!.uid;
        DocumentSnapshot userDoc = await getUserDoc(userId);
        userInfo.clear();
        userInfo.value.add(userDoc.data() as Map<String, dynamic>) ;
        Get.offAll(() => ChatScreen());
        print('Login successful');
      }
    } catch (e) {
      Get.snackbar(
        "Login Failed", // Title
        e.toString(),  // Error message
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: Duration(seconds: 3),  // Display time
      );
      print('Error during login: $e');
    }
  }

  // Helper method to upload the image to Firebase Storage
  Future<String> uploadImage(XFile imageFile, String uid) async {
    try {
      // Create a reference to Firebase Storage with the user UID
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('$uid.jpg');

      // Upload the file
      UploadTask uploadTask = storageRef.putFile(
        File(imageFile.path),
      );

      // Wait for the upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw e;
    }
  }
}
