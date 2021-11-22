import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      child: CircularProgressIndicator(
        color: Color(0xffff1b5c),
      ),
    );
  }
}