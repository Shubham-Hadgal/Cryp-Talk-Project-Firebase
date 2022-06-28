import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryp_talk_firebase/constants/color_constants.dart';
import 'package:cryp_talk_firebase/constants/firestore_constants.dart';
import 'package:cryp_talk_firebase/main.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:cryp_talk_firebase/models/message_chat.dart';
import 'package:cryp_talk_firebase/providers/auth_provider.dart';
import 'package:cryp_talk_firebase/providers/chat_provider.dart';
import 'package:cryp_talk_firebase/widgets/loading_view.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'change_key.dart';
import '../utilities/encrypt_decrypt.dart';
import 'full_photo_page.dart';
import 'login_page.dart';

class ChatPage extends StatefulWidget {

  final String peerId;
  final String peerAvatar;
  final String peerNickname;
  const ChatPage({Key? key, required this.peerId, required this.peerAvatar, required this.peerNickname}) : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  State createState() => ChatPageState(
    peerId: peerId,
    peerAvatar: peerAvatar,
    peerNickname: peerNickname,
  );
}

class ChatPageState extends State<ChatPage> {

  ChatPageState(
      {Key? key, required this.peerId, required this.peerAvatar, required this.peerNickname});

  String peerId;
  String peerAvatar;
  String peerNickname;
  late String currentUserId;

  List<QueryDocumentSnapshot> listMessage = List.from([]);

  int _limit = 20;
  final int _limitIncrement = 20;
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
    Keys.setMapKey(peerId);
    EncryptionDecryption.loadKey();

    focusNode.addListener(onFocusChange);
    listScrollController.addListener(_scrollListener);
    readLocal();
  }

  _scrollListener() {
    if (listScrollController.offset >=
        listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      setState(() {
        isShowSticker = false;
      });
    }
  }

  void readLocal() {
    if (authProvider
        .getUserIdFirebaseId()
        ?.isNotEmpty == true) {
      currentUserId = authProvider.getUserIdFirebaseId()!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (Route<dynamic> route) => false);
    }
    if (currentUserId.hashCode <= peerId.hashCode) {
      groupChatId = '$currentUserId-$peerId';
    } else {
      groupChatId = '$peerId-$currentUserId';
    }

    chatProvider.updateDataFirestore(
        FirestoreConstants.pathUserCollection, currentUserId,
        {FirestoreConstants.chattingWith: peerId});
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? pickedFile;

    pickedFile = (await imagePicker.pickImage(source: ImageSource.gallery));
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      if (imageFile != null) {
        setState(() {
          isLoading = true;
        });
        uploadFile();
      }
    }
  }

  void getSticker() {
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  Future uploadFile() async {
    String fileName = DateTime
        .now()
        .millisecondsSinceEpoch
        .toString();
    UploadTask uploadTask = chatProvider.uploadFile(imageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, TypeMessage.image);
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  void onSendMessage(String content, int type) {
    if (content.trim().isNotEmpty) {
      String encryptedMessage =
      EncryptionDecryption.encryptAES(content);

      textEditingController.clear();
      chatProvider.sendMessage(
          encryptedMessage, type, groupChatId, currentUserId, peerId);
      listScrollController.animateTo(
          0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(
          msg: 'Nothing to send', backgroundColor: ColorConstants.greyColor);
    }
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 && listMessage[index - 1].get(FirestoreConstants.idFrom) ==
        currentUserId) || index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 && listMessage[index - 1].get(FirestoreConstants.idFrom) !=
        currentUserId) || index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> onBackPress() {
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
      chatProvider.updateDataFirestore(
        FirestoreConstants.pathUserCollection,
        currentUserId,
        {FirestoreConstants.chattingWith: null},
      );
      Navigator.pop(context);
    }
    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    EncryptionDecryption.loadKey();

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: isWhite ? Colors.white : Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isWhite ? Colors.white : Colors.grey[900],
        iconTheme: const IconThemeData(
          color: ColorConstants.primaryColor,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              onPressed: (){
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_ios),
              constraints: const BoxConstraints(),
            ),
            Container(
              padding: const EdgeInsets.only(right: 15, left: 10),
              child: TextButton(
                onPressed: (){
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullPhotoPage(url: peerAvatar, name: peerNickname),
                      )
                  );
                },
                child: Material(
                  child: Image.network(
                    peerAvatar,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(40),
                  ),
                  clipBehavior: Clip.hardEdge,
                ),
              ),
            ),
            Text(
              peerNickname,
              style: const TextStyle(color: ColorConstants.primaryColor),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              child: Icon(Icons.vpn_key),
              padding: EdgeInsets.only(right: 10.0),
            ),
            onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ChangeKey(),
                ),
              );
            },
          ),
        ],
        // centerTitle: true,
      ),
      body: WillPopScope(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                buildListMessage(),

                isShowSticker ? buildSticker() : const SizedBox.shrink(),

                buildInput(),
              ],
            ),
            Positioned(
              child: isLoading ? const LoadingView() : const SizedBox.shrink(),
              left: width/2.2,
              top: height/2.7,
            ),
          ],
        ),
        onWillPop: onBackPress,
      ),
    );
  }

  Widget buildSticker() {
    return Expanded(
      child: Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                TextButton(
                  onPressed: () => onSendMessage('mimi4', TypeMessage.sticker),
                  child: Image.asset(
                    'assets/images/mimi4.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi5', TypeMessage.sticker),
                  child: Image.asset(
                    'assets/images/mimi5.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi6', TypeMessage.sticker),
                  child: Image.asset(
                    'assets/images/mimi6.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            ),

            Row(
              children: <Widget>[
                TextButton(
                  onPressed: () => onSendMessage('mimi7', TypeMessage.sticker),
                  child: Image.asset(
                    'assets/images/mimi7.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi8', TypeMessage.sticker),
                  child: Image.asset(
                    'assets/images/mimi8.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi9', TypeMessage.sticker),
                  child: Image.asset(
                    'assets/images/mimi9.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            ),
          ],
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        ),
        decoration: const BoxDecoration(
            border: Border(
                top: BorderSide(color: ColorConstants.greyColor2, width: 0.5)),
            color: Colors.grey
        ),
        padding: const EdgeInsets.all(5),
        height: 180,
      ),
    );
  }

  Widget buildLoading(){
    return Positioned(
      child: isLoading ? const LoadingView() : const SizedBox.shrink(),
    );
  }

  Widget buildInput() {
    return Container(
      child: Row(
        children: <Widget>[
          // Image Button
          Material(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: IconButton(
                icon: const Icon(Icons.camera_enhance),
                onPressed: getImage,
                color: ColorConstants.primaryColor,
              ),
            ),
            color: Colors.white,
          ),

          // Stickers button

         /* Material(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: IconButton(
                icon: const Icon(Icons.face_retouching_natural),
                onPressed: getSticker,
                color: ColorConstants.primaryColor,
              ),
            ),
            color: Colors.white,
          ),*/
          Flexible(
            child: TextField(
              onSubmitted: (value) {
                onSendMessage(textEditingController.text, TypeMessage.text);
              },
              style: const TextStyle(
                  color: ColorConstants.primaryColor, fontSize: 15),
              controller: textEditingController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Type your message...',
                hintStyle: TextStyle(color: ColorConstants.greyColor),
              ),
              focusNode: focusNode,
            ),
          ),
          Material(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () =>
                    onSendMessage(textEditingController.text, TypeMessage.text),
                color: ColorConstants.primaryColor,
              ),
            ),
            color: Colors.white,
          ),
        ],
      ),
      width: double.infinity,
      height: 50,
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: ColorConstants.greyColor2, width: 0.5)),
          color: Colors.white,
      ),
    );
  }

  Widget buildItem(int index, DocumentSnapshot? document){
    if(document != null){
      MessageChat messageChat = MessageChat.fromDocument(document);
      String msg;
      String img;
      try {
        msg = EncryptionDecryption.decryptAES(encrypt.Encrypted.fromBase64(messageChat.content));
      } catch(e) {
        msg = 'Encrypted Messages';
      }
      try {
        img = EncryptionDecryption.decryptAES(encrypt.Encrypted.fromBase64(messageChat.content));
      } catch (e) {
        img = 'Encrypted image';
      }
      if(messageChat.idFrom == currentUserId){
        return Column(
          // Right Side ((Sending Side))
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: <Widget>[
                messageChat.type == TypeMessage.text
                ? Container(
                  constraints: const BoxConstraints(
                    maxWidth: 200,
                  ),
                  child: Text(
                    msg,
                    style: msg != 'Encrypted Messages' ? TextStyle(color: Colors.white, fontSize: 14.5) : TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14.5, fontStyle: FontStyle.italic),
                  ),
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                  decoration: const BoxDecoration(
                      color: ColorConstants.primaryColor,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15), bottomLeft: Radius.circular(15))
                  ),
                  margin: const EdgeInsets.only(right: 5),
                  // margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20 : 10, right: 10),
                ): messageChat.type == TypeMessage.image
                ? OutlinedButton(
                  child: Material(
                    child: Image.network(
                      img,
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress){
                        if(loadingProgress == null) return child;
                        return Container(
                          decoration: const BoxDecoration(
                            color: ColorConstants.greyColor2,
                            borderRadius: BorderRadius.all(
                              Radius.circular(8),
                            )
                          ),
                          width: 200,
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: ColorConstants.themeColor,
                              value: loadingProgress.expectedTotalBytes != null &&
                                  loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, object, stackTrace){
                        return Material(
                          child: Image.asset(
                            'assets/images/img_not_available.jpeg',
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(8),
                          ),
                          clipBehavior: Clip.hardEdge,
                        );
                      },
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                    clipBehavior: Clip.hardEdge,
                  ),
                  onPressed: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => FullPhotoPage(
                            url: img,
                            name: peerNickname,
                          ),
                      ),
                    );
                  },
                  style: ButtonStyle(padding: MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.all(0))),
                ) : Container(
                  child: Image.asset(
                    'assets/images/${EncryptionDecryption.decryptAES(encrypt.Encrypted.fromBase64(messageChat.content))}.gif',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20 : 10, right: 10),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.end,
            ),
            Container(
              child: Text(
                DateFormat('dd MMM yyyy, hh: mm a')
                    .format(DateTime.fromMillisecondsSinceEpoch(int.parse(messageChat.timestamp))),
                style: const TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
              ),
              margin: const EdgeInsets.only(top: 5, bottom: 5, right: 5),
            ),
          ],
        );
      }else{
        return Container(
          // Left Side ((Receiving side))
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  /*isLastMessageLeft(index)
                  ? Material(
                    child: Image.network(
                      peerAvatar,
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress){
                          if(loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              color: ColorConstants.themeColor,
                              value: loadingProgress.expectedTotalBytes != null &&
                                  loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, object, stackTrace){
                          return const Icon(
                            Icons.account_circle,
                            size: 35,
                            color: ColorConstants.greyColor,
                          );
                        },
                        width: 35,
                        height: 35,
                        fit: BoxFit.cover,
                    ),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(18),
                    ),
                    clipBehavior: Clip.hardEdge,
                  ) : */
                  // Container(width: 35),
                  messageChat.type == TypeMessage.text
                  ? Container(
                    constraints: const BoxConstraints(
                      maxWidth: 200,
                    ),
                    child: Text(
                      msg,
                      style: msg != 'Encrypted Messages' ? TextStyle(color: Colors.white, fontSize: 14.5) : TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14.5, fontStyle: FontStyle.italic),
                    ),
                    padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                    decoration: const BoxDecoration(color: ColorConstants.dark, borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15), bottomRight: Radius.circular(15))),
                    margin: const EdgeInsets.only(left: 5),
                  ) : messageChat.type == TypeMessage.image
                  ? Container(
                    child: TextButton(
                      child: Material(
                        child: Image.network(
                          img,
                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress){
                            if(loadingProgress == null) return child;
                            return Container(
                              decoration: const BoxDecoration(
                                  color: ColorConstants.greyColor2,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  )
                              ),
                              width: 200,
                              height: 200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: ColorConstants.themeColor,
                                  value: loadingProgress.expectedTotalBytes != null &&
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, object, stackTrace) => Material(
                            child: Image.asset(
                              'assets/images/img_not_available.jpeg',
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
                            clipBehavior: Clip.hardEdge,
                          ),
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                        clipBehavior: Clip.hardEdge,
                      ),
                      onPressed: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullPhotoPage(url: img, name: peerNickname),
                          )
                        );
                      },
                      style: ButtonStyle(padding: MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.all(0))),
                    ),
                    margin: const EdgeInsets.only(left: 10),
                  ) : Container(
                    child: Image.asset(
                      'assets/images/${EncryptionDecryption.decryptAES(encrypt.Encrypted.fromBase64(messageChat.content))}.gif',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                    margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20 : 10, right: 10),
                  ),
                ],
              ),

              isLastMessageLeft(index)
              ? Container(
                child: Text(
                  DateFormat('dd MMM yyyy, hh: mm a')
                      .format(DateTime.fromMillisecondsSinceEpoch(int.parse(messageChat.timestamp))),
                  style: const TextStyle(color: ColorConstants.greyColor, fontSize: 11, fontStyle: FontStyle.italic),
                ),
                margin: const EdgeInsets.only(left: 5, top: 5, bottom: 5),
              ) : const SizedBox.shrink()
            ],
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
          margin: const EdgeInsets.only(bottom: 10),
        );
      }
    }else{
      return const SizedBox.shrink();
    }
  }

  Widget buildListMessage(){
    return Flexible(
      child: groupChatId.isNotEmpty
          ? StreamBuilder<QuerySnapshot>(
          stream: chatProvider.getChatStream(groupChatId, _limit),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
            if(snapshot.hasData){
              listMessage.addAll(snapshot.data!.docs);
              return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemBuilder: (context, index) => buildItem(index, snapshot.data?.docs[index]),
                  itemCount: snapshot.data?.docs.length,
                  reverse: true,
                  controller: listScrollController,
              );
            }else{
              return const Center(
                child: CircularProgressIndicator(
                  color: ColorConstants.themeColor,
                ),
              );
            }
          }
      ) : const Center(
        child: CircularProgressIndicator(
          color: ColorConstants.themeColor,
        ),
      ),
    );
  }
}