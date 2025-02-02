import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:webchat/Controller/message_controller.dart';
import '../common/common_components.dart';
import '../helpers/color_helper.dart';
import '../helpers/space_helper.dart';
import '../models/connections.dart';

class ChatList extends StatelessWidget {
  final MessageController messageController = Get.put(MessageController());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Gemini AI chat option
        ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage('https://cdn-wp.bulksignature.com/wp-content/uploads/2024/02/Frame-876-1024x569.png'),
            radius: 25.r,
          ),
          title: CommonComponents.appText('Gemini AI', fontWeight: FontWeight.bold),
          onTap: () {
            messageController.selectedConnection.clear();
            messageController.selectedConnection.add(Connection(
              id: 'gemini_ai',
              name: 'Gemini AI',
              image: 'https://cdn-wp.bulksignature.com/wp-content/uploads/2024/02/Frame-876-1024x569.png',
              lastMessage: '',
              lastMessageTime: DateTime.now(),
            ));
            messageController.getConversation();
          },
        ),
        Divider(color: Colors.white24),
        Padding(
          padding: EdgeInsets.all(SpaceHelper.medium),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: TextStyle(color: Colors.white),
              prefixIcon: Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: Colors.white12,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: Obx(() => ListView.builder(
            itemCount: messageController.myConnections.length,
            itemBuilder: (context, index) {
              var user = messageController.myConnections[index];
              return  user.name=="Gemini AI"?SizedBox():
                GestureDetector(
                onTap: () {
                  messageController.selectedConnection.clear();
                  messageController.selectedConnection.add(user);
                  messageController.getConversation();
                },
                child: ListTile(
                  leading: CommonComponents.appAvatar("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRZqAAoo7Gog69U-B0Sa-2Fuvl_vNu4vaUDwA&s"),
                  title: CommonComponents.appText(user.name),
                  subtitle: SizedBox(
                    width: 120.w,
                    child: CommonComponents.appText('${user.lastMessage}...', color: ColorHelper.secondaryTextColor),
                  ),
                  trailing: CommonComponents.appText(user.lastMessageTime.toString().substring(11, 16), fontSize: 12),
                ),
              );
            },
          )),
        ),
      ],
    );
  }
}