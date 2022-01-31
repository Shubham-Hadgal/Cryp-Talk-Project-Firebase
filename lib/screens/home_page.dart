import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cryp_talk_firebase/constants/color_constants.dart';
import 'package:cryp_talk_firebase/main.dart';
import 'package:cryp_talk_firebase/providers/home_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cryp_talk_firebase/models/popup_choices.dart';
import 'package:cryp_talk_firebase/providers/auth_provider.dart';
import 'package:cryp_talk_firebase/screens/login_page.dart';
import 'package:cryp_talk_firebase/screens/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ScrollController listScrollController = ScrollController();

  int _limit = 20;
  int _limitIncrement = 20;
  String _textSearch = "";
  bool isLoading = false;

  late AuthProvider authProvider;
  late String currentUserId;
  late HomeProvider homeProvider;
  //Debouncer searchDebouncer = Debouncer(milliseconds: 300);
  StreamController<bool> btnClearController = StreamController<bool>();
  TextEditingController searchBarTec = TextEditingController();

  List<PopupChoices> choices = <PopupChoices>[
    PopupChoices(title: 'Settings', icon: Icons.settings),
    PopupChoices(title: 'Sign out', icon: Icons.exit_to_app),
  ];

  Future<void> handleSignOut() async{
    authProvider.handleSignOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  void scrollListener() {
    if(listScrollController.offset >= listScrollController.position.maxScrollExtent && !listScrollController.position.outOfRange){
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void onItemMenuPress(PopupChoices choice){
    if(choice.title == "Sign Out"){
      handleSignOut();
    }
    else{
      Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
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
                padding: EdgeInsets.only(bottom: 10, top: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      child: Icon(Icons.exit_to_app, size: 30, color: Colors.white),
                      margin: EdgeInsets.only(bottom: 10),
                    ),
                    Text(
                      'Exit App',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
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
                      child: Icon(
                        Icons.cancel,
                        color: ColorConstants.primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10),
                    ),
                    Text(
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
                      child: Icon(
                        Icons.check_circle,
                        color: ColorConstants.primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10),
                    ),
                    Text(
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
      icon: Icon(Icons.more_vert, color: Colors.grey),
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

  @override
  void initState() {
    super.initState();
    authProvider = context.read<AuthProvider>();
    homeProvider = context.read<HomeProvider>();
    if(authProvider.getUserIdFirebaseId()?.isNotEmpty == true){
      currentUserId = authProvider.getUserIdFirebaseId()!;
    }else {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => LoginPage()),
              (Route<dynamic> route) => false,
      );
    }
    listScrollController.addListener(scrollListener);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWhite ? Colors.white: Colors.black,
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white38: Colors.grey[900],
        title: Text(
          'CrypTalk',
          style: TextStyle(
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: Switch(
            value: isWhite,
            onChanged: (value){
              setState(() {
                isWhite = value;
                print(isWhite);
              });
            },
            activeTrackColor: Colors.grey,
            activeColor: Colors.white,
            inactiveTrackColor: Colors.grey,
            inactiveThumbColor: Colors.black45,
          ),
          onPressed: ()=>"",
        ),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    return Container(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.search, color: ColorConstants.greyColor, size: 20),
          SizedBox(width: 5),
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
              decoration: InputDecoration.collapsed(hintText: "Search here...", hintStyle: TextStyle(fontSize: 13, color: ColorConstants.greyColor),),
              style: TextStyle(fontSize: 13),
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
                    child: Icon(Icons.clear_rounded, color: ColorConstants.greyColor, size: 20),
                    )
                : SizedBox.shrink();
            },
          ),
        ],
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: ColorConstants.greyColor2,
      ),
      padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
      margin: EdgeInsets.fromLTRB(10, 8, 10, 8),
    );
  }
}
