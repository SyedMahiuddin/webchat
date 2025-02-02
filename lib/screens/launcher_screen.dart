import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webchat/AuthService/auth_dialogue.dart';
import 'package:webchat/Controller/user_controller.dart';
import 'package:webchat/screens/chat_screen.dart';

class LauncherScreen extends StatefulWidget {
  const LauncherScreen({super.key});

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {
  UserController userController=Get.put(UserController());
  @override
  void initState() {
    checkUser();
    super.initState();
  }
  Future<void> checkUser() async{
    await userController.checkUserAndGetUserInfo();
    if(userController.userInfo.isNotEmpty)
      {
        await Future.delayed(Duration(seconds: 2));
        Get.offAll(ChatScreen());
      }
    else {
      Get.offAll(AuthDialog());
    }
  }
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: Image.asset("images/intro.gif")),
    );
  }
}
