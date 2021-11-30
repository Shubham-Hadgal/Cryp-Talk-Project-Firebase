import 'package:cryp_talk_firebase/constants/color_constants.dart';
import 'package:cryp_talk_firebase/providers/auth_provider.dart';
import 'package:cryp_talk_firebase/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 5),(){
      checkSignedIn();
    });
  }

  void checkSignedIn() async {
    AuthProvider authProvider = context.read<AuthProvider>();
    bool isLoggedIn = await authProvider.isLoggedIn();
    if(isLoggedIn){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
      return;
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(10.0),
              child: Text(
                'CrypTalk',
                style: TextStyle(
                  fontSize: 26.0,
                  color: ColorConstants.primaryColor,
                ),
              ),
            ),
            Image.asset(
              'assets/images/splash.png',
              width: 300,
              height: 300,
            ),
            SizedBox(height: 20),
            Container(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: ColorConstants.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
