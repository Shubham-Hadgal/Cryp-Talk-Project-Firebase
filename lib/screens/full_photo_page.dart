import 'package:cryp_talk_firebase/constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import '../main.dart';

class FullPhotoPage extends StatelessWidget {
  final String url;
  final String name;

  const FullPhotoPage({Key? key, required this.url, required this.name}) : super(key: key);

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: isWhite ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white : Colors.grey[900],
        iconTheme: const IconThemeData(
          color: ColorConstants.primaryColor,
        ),
        title: Text(
          name,
          style: TextStyle(color: ColorConstants.primaryColor),
        ),
        centerTitle: true,
      ),
      body: PhotoView(
          imageProvider: NetworkImage(url),
        ),
      );
  }
}