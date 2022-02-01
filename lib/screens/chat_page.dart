import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {

  final String peerId;
  final String peerAvatar;
  final String peerNickname;
  const ChatPage({Key? key, required this.peerId, required this.peerAvatar, required this.peerNickname}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
