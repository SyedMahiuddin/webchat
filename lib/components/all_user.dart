// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import '../Controller/message_controller.dart';
// import 'conversation.dart';
//
// class AllUsersTab extends StatelessWidget {
//   final MessageController messageController = Get.find<MessageController>();
//
//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       List<DocumentSnapshot> users = messageController.searchQuery.isEmpty
//           ? messageController.allUsers
//           : messageController.searchAllUsers(messageController.searchQuery.value);
//
//       return ListView.builder(
//         itemCount: users.length,
//         itemBuilder: (context, index) {
//           Map<String, dynamic> userData = users[index].data() as Map<String, dynamic>;
//           String userId = users[index].id;
//
//           return ListTile(
//             leading: CircleAvatar(
//               backgroundImage: NetworkImage(userData['imageUrl'] ?? ''),
//             ),
//             title: Text(userData['name'] ?? ''),
//             onTap: () {
//               messageController.fetchConversationMessages(userId);
//               Get.to(() => ConversationScreen());
//             },
//           );
//         },
//       );
//     });
//   }
// }