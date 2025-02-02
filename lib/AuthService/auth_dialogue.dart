import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:webchat/screens/chat_screen.dart';
import '../helpers/color_helper.dart';
import '../helpers/space_helper.dart';
import '../common/common_components.dart';
import 'auth_service.dart';

class AuthDialog extends StatefulWidget {
  @override
  _AuthDialogState createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final AuthService _authService = Get.put(AuthService());
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _name = '';
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _getImage() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    input.onChange.listen((event) {
      final file = input.files!.first;
      _authService.imageFile.value = file;
      setState(() {}); // Trigger a rebuild to show the selected image
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });
      try {
        if (_isLogin) {
          await _authService.signInWithEmailAndPassword(_email, _password);
        } else {
          // if (_authService.imageFile.value == null) {
          //   throw Exception('Please select an image');
          // }
          await _authService.createUserWithEmailAndPassword(_email, _password, _name);
        }
        Get.offAll(ChatScreen());
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorHelper.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CommonComponents.appText(
                _isLogin ? 'Welcome Back' : 'Join Us',
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: ColorHelper.primaryColor,
              ),
              SizedBox(height: SpaceHelper.verticalLarge),
              if (!_isLogin) ...[
                GestureDetector(
                  onTap: _getImage,
                  child: Obx(() => CircleAvatar(
                    radius: 50.r,
                    backgroundColor: ColorHelper.accentColor.withOpacity(0.2),
                    backgroundImage: _authService.imageFile.value != null
                        ? NetworkImage(html.Url.createObjectUrlFromBlob(_authService.imageFile.value!))
                        : null,
                    child: _authService.imageFile.value == null
                        ? Icon(Icons.add_a_photo, size: 40.sp, color: ColorHelper.accentColor)
                        : null,
                  )),
                ),
                if (_authService.imageFile.value != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(
                      'Image selected',
                      style: TextStyle(color: ColorHelper.accentColor, fontSize: 14.sp),
                    ),
                  ),
                SizedBox(height: SpaceHelper.verticalLarge),
                _buildTextField('Name', Icons.person),
                SizedBox(height: SpaceHelper.verticalMedium),
              ],
              _buildTextField('Email', Icons.email),
              SizedBox(height: SpaceHelper.verticalMedium),
              _buildTextField('Password', Icons.lock, isPassword: true),
              SizedBox(height: SpaceHelper.verticalLarge),
              _isLoading
                  ? CircularProgressIndicator(color: ColorHelper.primaryColor)
                  : ElevatedButton(
                child: Text(_isLogin ? 'Login' : 'Register', style: TextStyle(fontSize: 18.sp, color: Colors.white)),
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorHelper.primaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                ),
              ),
              SizedBox(height: SpaceHelper.verticalMedium),
              TextButton(
                child: Text(
                  _isLogin ? 'Need an account? Register' : 'Have an account? Login',
                  style: TextStyle(color: ColorHelper.accentColor),
                ),
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                    _authService.imageFile.value = null;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, {bool isPassword = false}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: ColorHelper.accentColor),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white30),
          borderRadius: BorderRadius.circular(8.r),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: ColorHelper.primaryColor),
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
      style: TextStyle(color: Colors.white),
      obscureText: isPassword,
      validator: (value) => value!.isEmpty ? 'This field is required' : null,
      onSaved: (value) {
        if (label == 'Email') _email = value!;
        if (label == 'Password') _password = value!;
        if (label == 'Name') _name = value!;
      },
    );
  }
}