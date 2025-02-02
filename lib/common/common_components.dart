import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../helpers/color_helper.dart';

class CommonComponents {
  static Text appText(String text, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    TextStyle? textStyle,
    TextAlign? textAlign,
  }) {
    return Text(
      text,
      style:textStyle?? TextStyle(
        fontSize: fontSize?.sp ?? 14.sp,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? ColorHelper.textColor,
      ),
      textAlign: textAlign,
    );
  }

  static Container appContainer({
    required Widget child,
    Color? color,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.transparent,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }

  static ElevatedButton appButton({
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:  backgroundColor ?? ColorHelper.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
      child: appText(text, color: textColor ?? Colors.white),
    );
  }

  static CircleAvatar appAvatar(String imageUrl, {double? radius}) {
    return CircleAvatar(
      backgroundImage: NetworkImage(imageUrl),
      radius: radius?.r ?? 20.r,
    );
  }
}