import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryp_talk_firebase/constants/constants.dart';
import 'package:cryp_talk_firebase/main.dart';
import 'package:cryp_talk_firebase/models/user_chat.dart';
import 'package:cryp_talk_firebase/providers/home_provider.dart';
import 'package:cryp_talk_firebase/screens/settings_page.dart';
import 'package:cryp_talk_firebase/utilities/debouncer.dart';
import 'package:cryp_talk_firebase/utilities/utilities.dart';
import 'package:cryp_talk_firebase/widgets/loading_view.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cryp_talk_firebase/models/popup_choices.dart';
import 'package:cryp_talk_firebase/providers/auth_provider.dart';
import 'package:cryp_talk_firebase/screens/login_page.dart';
import 'package:flutter/material.dart';
// ignore: implementation_imports
import 'package:provider/src/provider.dart';

import 'change_key.dart';
import '../utilities/encrypt_decrypt.dart';
import 'chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ScrollController listScrollController = ScrollController();

  int _limit = 20;
  final int _limitIncrement = 20;
  String _textSearch = "";
  bool isLoading = false;

  late AuthProvider authProvider;
  late String currentUserId;
  late HomeProvider homeProvider;
  Debouncer searchDebouncer = Debouncer(milliseconds: 300);
  StreamController<bool> btnClearController = StreamController<bool>();
  TextEditingController searchBarTec = TextEditingController();

  List<PopupChoices> choices = <PopupChoices>[
    PopupChoices(title: 'Settings', icon: Icons.settings),
    PopupChoices(title: 'Sign out', icon: Icons.exit_to_app),
  ];

  Future<void> handleSignOut() async{
    authProvider.handleSignOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  void scrollListener() {
    if(listScrollController.offset >= listScrollController.position.maxScrollExtent && !listScrollController.position.outOfRange){
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void onItemMenuPress(PopupChoices choice){
    if(choice.title == "Sign out"){
      handleSignOut();
    }
    else{
      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
    }
  }

  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }

  Future<void> openDialog() async {
    switch(await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            clipBehavior: Clip.hardEdge,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.zero,
            children: [
              Container(
                color: ColorConstants.themeColor,
                padding: const EdgeInsets.only(bottom: 10, top: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      child: const Icon(Icons.exit_to_app, size: 30, color: Colors.white),
                      margin: const EdgeInsets.only(bottom: 10),
                    ),
                    const Text(
                      'Exit App',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Are you sure to Exit App ?',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: (){
                  Navigator.pop(context,0);
                },
                child: Row(
                  children: [
                    Container(
                      child: const Icon(
                        Icons.cancel,
                        color: ColorConstants.primaryColor,
                      ),
                      margin: const EdgeInsets.only(right: 10),
                    ),
                    const Text(
                      'Cancel',
                      style: TextStyle(color: ColorConstants.primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: (){
                  Navigator.pop(context,1);
                },
                child: Row(
                  children: [
                    Container(
                      child: const Icon(
                        Icons.check_circle,
                        color: ColorConstants.primaryColor,
                      ),
                      margin: const EdgeInsets.only(right: 10),
                    ),
                    const Text(
                      'Yes',
                      style: TextStyle(color: ColorConstants.primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
    )){
      case 0:
        break;
      case 1:
        exit(0);
    }
  }

  Widget buildPopupMenu(){
    return PopupMenuButton<PopupChoices>(
      icon: const Icon(Icons.more_vert, color: Colors.grey),
        onSelected: onItemMenuPress,
        itemBuilder: (BuildContext context) {
          return choices.map((PopupChoices choice){
            return PopupMenuItem<PopupChoices>(
              value: choice,
              child: Row(
                children: [
                  Icon(
                    choice.icon,
                    color: Colors.grey[900]
                  ),
                  Container(
                    width: 10,
                  ),
                  Text(
                    choice.title,
                    style: TextStyle(
                      color: Colors.grey[900]
                    ),
                  ),
                ],
              ),
            );
          }).toList();
        }
    );
  }

  @override
  void dispose() {
    super.dispose();
    btnClearController.close();
  }

  void registerNotification()
  {
    firebaseMessaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if(message.notification != null)
        {
          //show notification
          showNotification(message.notification!);
        }
        return;
    });

    firebaseMessaging.getToken().then((token){
      if(token != null)
        {
          homeProvider.updateDataFirestore(FirestoreConstants.pathUserCollection, currentUserId, {'pushToken': token});
        }
    }).catchError((error){
      Fluttertoast.showToast(msg: error.message.toString());
    });
  }

  @override
  void initState() {
    super.initState();
    authProvider = context.read<AuthProvider>();
    homeProvider = context.read<HomeProvider>();

    if(authProvider.getUserIdFirebaseId()?.isNotEmpty == true){
      currentUserId = authProvider.getUserIdFirebaseId()!;
    }else {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginPage()),
              (Route<dynamic> route) => false,
      );
    }

    registerNotification();
    configureLocalNotification();
    listScrollController.addListener(scrollListener);
  }

  void configureLocalNotification(){
    AndroidInitializationSettings initializationAndroidSettings = const AndroidInitializationSettings("app_icon.png");
    IOSInitializationSettings initializationIOsSettings = const IOSInitializationSettings();
    InitializationSettings initializationSettings = InitializationSettings(
        android: initializationAndroidSettings,
        iOS: initializationIOsSettings,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void showNotification(RemoteNotification remoteNotification) async
  {
    AndroidNotificationDetails androidNotificationDetails = const AndroidNotificationDetails(
      "com.example.cryp_talk_firebase",
      "Cryp Talk",
      playSound: true,
      enableVibration: true,
      importance: Importance.max,
      priority: Priority.high,
    );

    IOSNotificationDetails iosNotificationDetails = const IOSNotificationDetails();

    NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      remoteNotification.title,
      remoteNotification.body,
      notificationDetails,
      payload: null,
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: isWhite ? Colors.white: Colors.black,
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white38: Colors.grey[900],
        title: Container(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            'CrypTalk',
            style: TextStyle(
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        // AppBar action menu
        actions: [
          buildPopupMenu(),
        ],
      ),
      body: WillPopScope(
        onWillPop: onBackPress,
        child: Stack(
          children: [
            Column(
              children: [
                buildSearchBar(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: homeProvider.getStreamFireStore(FirestoreConstants.pathUserCollection, _limit, _textSearch),
                    builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if(snapshot.hasData) {
                        if((snapshot.data?.docs.length ?? 0) > 0) {
                          return ListView.builder(
                            padding: const EdgeInsets.all(10),
                            itemBuilder: (context, index) => buildItem(context, snapshot.data?.docs[index]),
                            itemCount: snapshot.data?.docs.length,
                            controller: listScrollController,
                          );
                        } else {
                          return const Center(
                            child: Text('No Users found...', style: TextStyle(color: Colors.grey)),
                          );
                        }
                      } else {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.grey,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              child: isLoading ? const LoadingView(): const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    return Container(
      height: 50,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.search, color: Colors.grey[800], size: 20),
          const SizedBox(width: 5),
          Expanded(
            child: TextFormField(
              textInputAction: TextInputAction.search,
              controller: searchBarTec,
              onChanged: (value) {
                if(value.isNotEmpty) {
                  btnClearController.add(true);
                  setState(() {
                    _textSearch = value;
                  });
                } else {
                  btnClearController.add(false);
                  setState(() {
                    _textSearch = "";
                  });
                }
              },
              decoration: InputDecoration.collapsed(hintText: "Search here...", hintStyle: TextStyle(fontSize: 15, color: Colors.grey[800]),),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          StreamBuilder(
            stream: btnClearController.stream,
            builder: (context, snapshot) {
              return snapshot.data == true
              ? GestureDetector(
                    onTap: (){
                      searchBarTec.clear();
                      btnClearController.add(false);
                      setState(() {
                        _textSearch = "";
                      });
                    },
                    child: const Icon(Icons.clear_rounded, color: ColorConstants.greyColor, size: 20),
                    )
                : const SizedBox.shrink();
            },
          ),
        ],
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.grey,
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 10, 8),
      margin: const EdgeInsets.fromLTRB(10, 12, 10, 6),
    );
  }

  Widget buildItem(BuildContext context, DocumentSnapshot? document) {
    if(document != null) {
      UserChat userChat = UserChat.fromDocument(document);
      if(userChat.id == currentUserId) {
        return const SizedBox.shrink();
      } else {
        return Container(
          child: TextButton(
            child: Row(
              children: [
                Material(
                  child: userChat.photoUrl.isNotEmpty
                      ? Image.network(
                          userChat.photoUrl,
                          fit: BoxFit.cover,
                          width: 50,
                          height: 50,
                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress){
                            if(loadingProgress == null) return child;
                            return SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                color: Colors.grey,
                                value: loadingProgress.expectedTotalBytes != null && loadingProgress.expectedTotalBytes != null
                                       ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                       : null,
                              ),
                            );
                          },
                          errorBuilder: (context, object, stackTrace) {
                            return const Icon(
                              Icons.account_circle,
                              size: 50,
                              color: ColorConstants.greyColor,
                            );
                          }
                        )
                      :const Icon(
                        Icons.account_circle,
                        size: 50,
                        color: ColorConstants.greyColor,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(25)),
                      clipBehavior: Clip.hardEdge,
                  ),
                Flexible(
                  child: Container(
                    child: Column(
                      children: [
                        Container(
                          child: Text(
                            userChat.nickname,
                            maxLines: 1,
                            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                            alignment: Alignment.centerLeft,
                            margin: const EdgeInsets.fromLTRB(5, 7, 0, 7),
                          ),
                          Container(
                            child: Text(
                              userChat.aboutMe,
                              maxLines: 1,
                              style: TextStyle(color: Colors.grey[700], fontSize: 15),
                            ),
                            alignment: Alignment.centerLeft,
                            margin: const EdgeInsets.fromLTRB(5, 0, 0, 7),
                          ),
                      ],
                    ),
                    margin: const EdgeInsets.only(left: 20),
                  ),
                ),
              ],
            ),
            onPressed: () {
              if(Utilities.isKeyboardShowing()) {
                  Utilities.closeKeyboard(context);
              }
              // setting the key with respect to the user id
              Keys.setMapKey(userChat.id);
              // loading the key with respect to the user id
              EncryptionDecryption.loadKey();

              Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(
                    peerId: userChat.id,
                    peerAvatar: userChat.photoUrl,
                    peerNickname: userChat.nickname,
                  ),
                ),
              );
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.grey.withOpacity(0.2)),
              shape: MaterialStateProperty.all(
                const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15),),
                ),
              )
            ),
          ),
          margin: const EdgeInsets.only(bottom: 10, left: 5, right: 5),
        );
      }
    } else {
      return  const SizedBox.shrink();
    }
  }

  Widget handleDarkMode() {
    return IconButton(
      icon: Switch(
        value: isWhite,
        onChanged: (value){
          setState(() {
            isWhite = value;
            // print(isWhite);
          });
        },
        activeTrackColor: Colors.grey,
        activeColor: Colors.white,
        inactiveTrackColor: Colors.grey,
        inactiveThumbColor: Colors.black45,
      ),
      onPressed: ()=>"",
    );
  }
}
