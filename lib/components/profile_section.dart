import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webchat/Controller/message_controller.dart';
import 'package:webchat/Controller/user_controller.dart';
import '../common/common_components.dart';
import '../helpers/color_helper.dart';
import '../helpers/space_helper.dart';

class ProfileSection extends StatelessWidget {
   var userData;

   MessageController messageController=Get.find();

  ProfileSection({this.userData});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: SpaceHelper.large),
        CommonComponents.appAvatar(userData?.image ?? '', radius: 50),
        SizedBox(height: SpaceHelper.medium),
        CommonComponents.appText(userData?.name ?? 'User', fontSize: 20, fontWeight: FontWeight.bold),
        CommonComponents.appText('Active Now', color: Colors.green),
        SizedBox(height: SpaceHelper.large),
        CommonComponents.appText('Attachments', fontSize: 18, fontWeight: FontWeight.bold),
        SizedBox(height: SpaceHelper.medium),
        Expanded(
          child: Obx(()=>GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 8.h,
            ),
            itemCount: messageController.onGoingConversationFiles.length, // Replace with actual attachment count
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: (){
                  launchUrl(Uri.parse(messageController.onGoingConversationFiles[index]["file"]!));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: messageController.onGoingConversationFiles[index]["fileType"]=="image"?
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Image.network(messageController.onGoingConversationFiles[index]["file"]!,fit: BoxFit.cover,),
                      ):
                  Icon(Icons.attachment, color: ColorHelper.primaryColor),
                ),
              );
            },
          )),
        ),
      ],
    );
  }
}