import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:webchat/Controller/message_controller.dart';

import '../Controller/user_controller.dart';
import '../helpers/color_helper.dart';
import '../helpers/space_helper.dart';

class AddConnectionWidget extends StatelessWidget {
  final UserController userController = Get.find<UserController>();
  final MessageController messageController = Get.put(MessageController());
  final RxBool isUserSelected = false.obs;
  final Rx<Map<String, dynamic>> selectedUser = Rx<Map<String, dynamic>>({});
  final TextEditingController chatController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorHelper.primaryColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: TextButton(
        onPressed: () => _showSearchDialog(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add, color: ColorHelper.textColor, size: 24.sp),
            SizedBox(width: SpaceHelper.small),
            Text(
              'Add Connection',
              style: TextStyle(color: ColorHelper.textColor, fontSize: 16.sp),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: ColorHelper.backgroundColor,
          child: Container(
            padding: EdgeInsets.all(SpaceHelper.medium),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Connection',
                      style: TextStyle(
                        color: ColorHelper.textColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: ColorHelper.textColor, size: 24.sp),
                      onPressed: () {
                        isUserSelected.value = false;
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                SizedBox(height: SpaceHelper.verticalMedium),
                Obx(() => isUserSelected.value
                    ? _buildSelectedUserProfile()
                    : _buildUserSearch()),
                SizedBox(height: SpaceHelper.verticalMedium),
                Obx(() => isUserSelected.value
                    ? _buildMessageInput(context)
                    : SizedBox()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserSearch() {
    return SizedBox(
      height: 300.h,
      child: Column(
        children: [
          TextField(
            style: TextStyle(color: ColorHelper.textColor, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: 'Search by email or name',
              hintStyle: TextStyle(color: ColorHelper.secondaryTextColor, fontSize: 14.sp),
              prefixIcon: Icon(Icons.search, color: ColorHelper.accentColor, size: 24.sp),
              filled: true,
              fillColor: ColorHelper.backgroundColor.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) => userController.filterUsers(value),
          ),
          SizedBox(height: SpaceHelper.verticalMedium),
          Expanded(
            child: Obx(() => ListView.builder(
              itemCount: userController.filteredUsers.length,
              itemBuilder: (context, index) {
                final user = userController.filteredUsers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user['imageUrl']),
                    radius: 24.r,
                  ),
                  title: Text(
                    user['name'],
                    style: TextStyle(color: ColorHelper.textColor, fontSize: 16.sp),
                  ),
                  subtitle: Text(
                    user['email'],
                    style: TextStyle(color: ColorHelper.secondaryTextColor, fontSize: 14.sp),
                  ),
                  onTap: () {
                    selectedUser.value = user;
                    isUserSelected.value = true;
                  },
                );
              },
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedUserProfile() {
    return Column(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(selectedUser.value['imageUrl']),
          radius: 48.r,
        ),
        SizedBox(height: SpaceHelper.verticalMedium),
        Text(
          selectedUser.value['name'],
          style: TextStyle(color: ColorHelper.textColor, fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: SpaceHelper.verticalSmall),
        Text(
          selectedUser.value['email'],
          style: TextStyle(color: ColorHelper.secondaryTextColor, fontSize: 14.sp),
        ),
      ],
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 40.h,
          child: TextField(
            controller: chatController,
            style: TextStyle(color: ColorHelper.textColor, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: "Hi, I'm ${userController.userInfo[0]["name"]}, let's start a conversation",
              hintStyle: TextStyle(color: ColorHelper.secondaryTextColor, fontSize: 14.sp),
              filled: true,
              fillColor: ColorHelper.backgroundColor.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        SizedBox(height: 10.h,),
        _buildStartConversationButton(context)
      ],
    );
  }

  Widget _buildStartConversationButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorHelper.accentColor,
        padding: EdgeInsets.symmetric(horizontal: SpaceHelper.medium, vertical: SpaceHelper.small),
      ),
      onPressed: () async {
       await messageController.sendMessage(receiverData: selectedUser.value,
           messageBody: "Hi, I'm ${userController.userInfo[0]["name"]}, let's start a conversation");
        Navigator.of(context).pop();
      },
      child: Text('Start new Conversation', style: TextStyle(color: Colors.white, fontSize: 16.sp)),
    );
  }
}