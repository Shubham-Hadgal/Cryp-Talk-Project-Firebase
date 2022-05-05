import 'package:cryp_talk_firebase/constants/color_constants.dart';
import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 50,
      height: 50,
      child: CircularProgressIndicator(
        color: ColorConstants.primaryColor,
      ),
    );
  }
}