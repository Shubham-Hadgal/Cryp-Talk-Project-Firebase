import 'package:cryp_talk_firebase/providers/auth_provider.dart';
import 'package:cryp_talk_firebase/screens/home_page.dart';
import 'package:cryp_talk_firebase/widgets/loading_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {

    AuthProvider authProvider = Provider.of<AuthProvider>(context);
    switch(authProvider.status){
      case Status.authenticateError:
        Fluttertoast.showToast(msg: "Sign in fail");
        break;
      case Status.authenticateCanceled:
        Fluttertoast.showToast(msg: "Sign in canceled");
        break;
      case Status.authenticated:
        Fluttertoast.showToast(msg: "Signed in Successfully");
        break;
      default:
        break;
    }
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(),
            Padding(
              padding: EdgeInsets.all(10.0),
              child: Text(
                'CrypTalk',
                style: TextStyle(
                  fontSize: 26.0,
                    color: Color(0xffff1b5c)
                ),
              ),
            ),
            Image.asset(
              'assets/images/back.png',
              width: 300,
              height: 300,
            ),
            SizedBox(height: 20.0),
            Padding(
              padding: EdgeInsets.all(10.0),
              child: GestureDetector(
                onTap: () async{
                  bool isSuccess = await authProvider.handleSignIn();
                  if(isSuccess){
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
                  }
                },
                child: Image.asset(
                  'assets/images/google_login.jpeg',
                ),
              ),
            ),
            Stack(
              children: [
                Container(),
                Positioned(
                  child: authProvider.status == Status.authenticating ? Center(child: LoadingView()) : SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
