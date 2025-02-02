import 'dart:io';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webchat/Controller/message_controller.dart';
import 'package:webchat/Controller/user_controller.dart';
import 'package:webchat/components/add_connection.dart';
import 'package:webchat/helpers/space_helper.dart';
import '../AuthService/auth_service.dart';
import '../components/chat_list.dart';
import '../components/conversation.dart';
import '../components/profile_section.dart';
import '../helpers/color_helper.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //final AuthService _authService = AuthService();
  UserController userController=Get.put(UserController());
  MessageController messageController=Get.put(MessageController());
  Map<String, dynamic>? userData;

  @override
  void initState() {
_loadUserData();
    super.initState();
    //_loadUserData();
  }

  Future<void> _loadUserData() async {
    while(AuthService().currentUser==null)
      {
        await Future.delayed(Duration(seconds: 1));
      }
      userController.checkUserAndGetUserInfo();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorHelper.backgroundColor,
              ColorHelper.primaryColor.withOpacity(0.8)
            ],
          ),
        ),
        child: Column(
          children: [
            Obx(()=>userController.userInfo.isEmpty?SizedBox():
            _buildUserProfileBar(context)),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ChatList(),
                  ),
                  VerticalDivider(color: Colors.white24, width: 1),
                  Expanded(
                    flex: 4,
                    child: ConversationScreen(),
                  ),
                  VerticalDivider(color: Colors.white24, width: 1),
                  Expanded(
                    flex: 2,
                    child: Obx(()=>Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: messageController.selectedConnection.isEmpty?
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28.0),
                        child: Center(
                          child: Image.asset("images/nofile.png"),
                        ),
                      ):
                      ProfileSection(userData: messageController.selectedConnection[0]),
                    ),)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileBar(BuildContext context) {
    UserController userController=Get.find();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      color: Colors.black.withOpacity(0.3),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundImage: userController.userInfo[0]?['imageUrl'] != null ? NetworkImage(
                userController.userInfo[0]!['imageUrl']) : null,
            child: userController.userInfo[0]?['imageUrl'] == null ? Icon(
                Icons.person, size: 24.r) : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              userController.userInfo[0]?['name'] ?? 'User',
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
            ),
          ),
          Row(
            children: [
              AddConnectionWidget(),
              SizedBox(width: 10.w,),
              IconButton(
                icon: Icon(Icons.settings, color: Colors.white),
                onPressed: () => _showSettingsDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
    }
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final TextEditingController nameController = TextEditingController(text: AuthService().currentUser!.displayName ?? '');
            File? selectedImage;
            bool isUpdating = false;

            return AlertDialog(
              backgroundColor: ColorHelper.backgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              contentPadding: EdgeInsets.zero,
              content: Stack(
                clipBehavior: Clip.none,
                children: [
                  SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(SpaceHelper.medium),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: ColorHelper.textColor,
                            ),
                          ),
                          SizedBox(height: SpaceHelper.medium),
                          GestureDetector(
                            onTap: _getImage,
                            child: Obx(()=>CircleAvatar(
                              radius: 50.r,
                              backgroundColor: ColorHelper.primaryColor,
                              backgroundImage: AuthService().imageFile.value != null
                                  ? NetworkImage(html.Url.createObjectUrlFromBlob(AuthService().imageFile.value!))
                                  : null,
                              child: AuthService().imageFile.value == null
                                  ? Icon(Icons.add_a_photo, size: 40.sp, color: ColorHelper.backgroundColor)
                                  : null,
                            )),
                          ),
                          SizedBox(height: SpaceHelper.medium),
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelStyle: TextStyle(color: ColorHelper.textColor),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: ColorHelper.primaryColor),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: ColorHelper.primaryColor),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            style: TextStyle(color: ColorHelper.textColor),
                          ),
                          SizedBox(height: SpaceHelper.small),
                          Text(
                            'Email:${AuthService().currentUser!.email}',
                            style: TextStyle(color: ColorHelper.secondaryTextColor),
                          ),
                          SizedBox(height: SpaceHelper.large),
                          ElevatedButton(
                            child: isUpdating
                                ? CircularProgressIndicator(color: ColorHelper.textColor)
                                : Text('Update Profile'),
                            onPressed: isUpdating ? null : () async {
                              AuthService().updateProfile(uid: AuthService().currentUser!.uid, name: nameController.text);
                              setState(() {
                                isUpdating = true;
                              });
                              try {
                                // Implement update logic here
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Profile updated successfully')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to update profile: $e')),
                                );
                              } finally {
                                setState(() {
                                  isUpdating = false;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorHelper.primaryColor,
                              foregroundColor: ColorHelper.textColor,
                              padding: EdgeInsets.symmetric(horizontal: SpaceHelper.large, vertical: SpaceHelper.small),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            ),
                          ),
                          SizedBox(height: SpaceHelper.medium),
                          TextButton(
                            child: Text('Logout'),
                            onPressed: () async {
                              await AuthService().signOut();
                              Navigator.of(context).pushReplacementNamed('/login');
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: ColorHelper.primaryColor,
                              padding: EdgeInsets.symmetric(horizontal: SpaceHelper.large, vertical: SpaceHelper.small),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -10,
                    top: -10,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: CircleAvatar(
                        backgroundColor: ColorHelper.accentColor,
                        radius: 16.r,
                        child: Icon(Icons.close, color: ColorHelper.textColor, size: 20.r),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _getImage() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    input.onChange.listen((event) {
      final file = input.files!.first;
      AuthService().imageFile.value = file;
      setState(() {}); // Trigger a rebuild to show the selected image
    });
  }
  }
