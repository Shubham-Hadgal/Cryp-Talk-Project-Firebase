import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/color_constants.dart';

class Keys {
  static String _key = '';
  static String _mapKey = '';

  static setMapKey(String mk) {
    _mapKey = mk;
  }

  static String getKey() {
    _ChangeKeyState()._read(_mapKey);
    return _key;
  }

  static setKey(String key) {
    _ChangeKeyState()._save(_mapKey, key);
  }
}

class ChangeKey extends StatefulWidget {
  const ChangeKey({Key? key}) : super(key: key);

  @override
  State<ChangeKey> createState() => _ChangeKeyState();
}

class _ChangeKeyState extends State<ChangeKey> {

  TextEditingController textEditingController1 = TextEditingController();
  int charLength = 0;

  _onChanged(String value) {
    setState(() {
      charLength = value.length;
    });
  }

  _read(String mapKey) async {
    final prefs = await SharedPreferences.getInstance();
    String key = mapKey;
    final value = prefs.getString(key) ?? 'Please set the Key';
    Keys._key = value;
    Keys._mapKey = key;
  }

  _save(String mapKey, String secretKey) async {
    final prefs = await SharedPreferences.getInstance();
    String key = mapKey;
    final value = secretKey;
    prefs.setString(key, value);
    Keys._mapKey = key;
    Keys._key = value;
  }

  void _showToast(BuildContext context) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: const Text('Enter the valid key of size 16, 24, or 32'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    Widget getKeyTextField = Padding(
        padding: const EdgeInsets.only(top: 30.0, right: 8.0, left: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                    padding: EdgeInsets.only(left: 10.0),
                    child: Text('Enter the key',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70))),
                Spacer(),
                Container(
                    padding: EdgeInsets.only(right: 10.0),
                    child: Text('$charLength',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            SizedBox(height: 8.0),
            TextField(
              cursorHeight: 20,
              autofocus: false,
              style: TextStyle(color: Colors.white),
              controller: textEditingController1,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: "Must be in length of 16, 24, 32 characters..",
                hintStyle: TextStyle(color: Colors.white70),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  gapPadding: 0.0,
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.green, width: 1.5),
                ),
              ),
            ),
          ],
        ));
    Widget saveButton = Container(
      padding: EdgeInsets.only(top: 20.0, left: 10.0),
      child: SizedBox(
        height: 40,
        width: width / 2.5,
        child: TextButton.icon(
          onPressed: () async {
            if (textEditingController1.text.length == 16 ||
                textEditingController1.text.length == 24 ||
                textEditingController1.text.length == 32) {
              print(Keys._key);
              await _save(Keys._mapKey, textEditingController1.text);
              setState(() {});
              print(Keys._key);
            } else {
              _showToast(context);
            }
          },
          icon: Icon(Icons.save_outlined, color: Colors.white),
          label: Text(
            'Save',
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.white
            ),
          ),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(ColorConstants.primaryColor),
            shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0))),
            padding: MaterialStateProperty.all<EdgeInsets>(
              const EdgeInsets.fromLTRB(30, 10, 30, 10),
            ),
          ),
        ),
      ),
    );
    Widget shareButton = Container(
      padding: EdgeInsets.only(top: 10.0, left: 10.0),
      child: SizedBox(
        height: 40,
        width: width / 2.5,
        child: TextButton.icon(
          onPressed: () {
            if(Keys._key != 'Please set the Key') {
              Share.share(Keys._key);
            } else {
              Fluttertoast.showToast(msg: 'Please set the Key first');
            }
          },
          icon: Icon(Icons.share_rounded, color: Colors.white),
          label: Text(
            'Share',
            style: TextStyle(
                fontSize: 16.0,
                color: Colors.white
            ),
          ),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(ColorConstants.primaryColor),
            shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0))),
            padding: MaterialStateProperty.all<EdgeInsets>(
              const EdgeInsets.fromLTRB(30, 10, 30, 10),
            ),
          ),
        ),
      ),
    );
    Widget displayKey = Container(
      padding: EdgeInsets.all(10.0),
      child: Column(
        children: [
          Row(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                child: Text('Your Current Key :',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
              ),
            ],
          ),
          SizedBox(
            height: 90,
            width: width / 0.7,
            child: Container(
              decoration: BoxDecoration(
                  color: const Color(0xFF414141),
                  borderRadius: BorderRadius.all(Radius.circular(10.0))),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(Keys._key, style: TextStyle(fontSize: 18.0, color: Colors.white)),
              ),
            ),
          ),

        ],
      ),
    );
    return Scaffold(
      backgroundColor: Color(0xFF242424),
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: ColorConstants.primaryColor,
        ),
        title: Container(
          padding: const EdgeInsets.only(left: 10.0),
          child: const Text(
            'Change Key',
            style: TextStyle(
              fontSize: 22.0,
              color: ColorConstants.primaryColor,
            ),
          ),
        ),
        titleSpacing: 1.0,
        backgroundColor: Colors.grey[900],
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                getKeyTextField,
                saveButton,
                displayKey,
                shareButton,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
