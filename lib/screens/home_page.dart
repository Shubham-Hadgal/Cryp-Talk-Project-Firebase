import 'package:cryp_talk_firebase/constants/color_constants.dart';
import 'package:cryp_talk_firebase/main.dart';
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
  //late HomeProvider homeProvider;

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
  void initState() {
    super.initState();
    authProvider = context.read<AuthProvider>();
    //homeProvider = context.read<HomeProvider>();
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
    );
  }
}
