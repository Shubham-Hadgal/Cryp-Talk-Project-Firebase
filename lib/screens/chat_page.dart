import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryp_talk_firebase/constants/firestore_constants.dart';
import 'package:cryp_talk_firebase/providers/auth_provider.dart';
import 'package:cryp_talk_firebase/providers/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';

class ChatPage extends StatefulWidget {

  final String peerId;
  final String peerAvatar;
  final String peerNickname;
  const ChatPage({Key? key, required this.peerId, required this.peerAvatar, required this.peerNickname}) : super(key: key);

  @override
  State createState() => ChatPageState(
    peerId: this.peerId,
    peerAvatar: this.peerAvatar,
    peerNickname: this.peerNickname,
  );
}

class ChatPageState extends State<ChatPage> {

  ChatPageState({Key? key, required this.peerId, required this.peerAvatar, required this.peerNickname});

  String peerId;
  String peerAvatar;
  String peerNickname;
  late String currentUserId;

  List<QueryDocumentSnapshot> listMessage = new List.from([]);

  int _limit = 20;
  int _limitIncrement = 20;
  String groupChatId = "";

  File? imageFile;
  bool isLoading = false;
  bool isShowSticker = false;
  String imageUrl = "";

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  late ChatProvider chatProvider;
  late AuthProvider authProvider;

  @override
  void initState() {
    super.initState();
    chatProvider = context.read<ChatProvider>();
    authProvider = context.read<AuthProvider>();

    focusNode.addListener(onFocusChange);
    listScrollController.addListener(_scrollListener);
    readLocal();
  }

  _scrollListener() {
    if(listScrollController.offset >= listScrollController.position.maxScrollExtent && !listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void onFocusChange() {
    if(focusNode.hasFocus) {
      setState(() {
        isShowSticker = false;
      });
    }
  }

  void readLocal() {
    if(authProvider.getUserIdFirebaseId()?.isNotEmpty == true) {
      currentUserId = authProvider.getUserIdFirebaseId()!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => LoginPage()),
              (Route<dynamic> route) => false);
    }
    if(currentUserId.hashCode <= peerId.hashCode) {
      groupChatId = '$currentUserId-$peerId';
    } else {
      groupChatId = '$peerId-$currentUserId';
    }

    chatProvider.updateDataFirestore(FirestoreConstants.pathUserCollection, currentUserId, {FirestoreConstants.chattingWith: peerId});
  }


  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
