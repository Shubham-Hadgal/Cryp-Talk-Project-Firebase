import 'dart:io';
import 'package:cryp_talk_firebase/constants/app_constants.dart';
import 'package:cryp_talk_firebase/constants/constants.dart';
import 'package:cryp_talk_firebase/main.dart';
import 'package:cryp_talk_firebase/models/user_chat.dart';
import 'package:cryp_talk_firebase/widgets/loading_view.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cryp_talk_firebase/providers/setting_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
// ignore: implementation_imports
import 'package:provider/src/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    // EncryptionDecryption.loadKey();

    return Scaffold(
      backgroundColor: isWhite ? Colors.white: Colors.black,
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: ColorConstants.primaryColor,
        ),
        title: const Text(
          AppConstants.settingsTitle,
          style: TextStyle(color: ColorConstants.primaryColor),
        ),
        backgroundColor: isWhite ? Colors.white38: Colors.grey[900],
      ),
      body: const SettingsPageState(),
    );
  }
}

class SettingsPageState extends StatefulWidget {
  const SettingsPageState({Key? key}) : super(key: key);

  @override
  _SettingsPageStateState createState() => _SettingsPageStateState();
}

class _SettingsPageStateState extends State<SettingsPageState> {

  TextEditingController? controllerNickname;
  TextEditingController? controllerAboutMe;

  String dialCodeDigits = "+00";
  final TextEditingController _controller = TextEditingController();

  String id = "";
  String nickname = "";
  String aboutMe = "";
  String photoUrl = "";
  String phoneNumber = "";

  bool isLoading = false;
  File? avatarImageFile;
  late SettingProvider settingProvider;

  final FocusNode focusNodeNickname = FocusNode();
  final FocusNode focusNodeAboutMe = FocusNode();

  @override
  void initState() {
    super.initState();
    settingProvider = context.read<SettingProvider>();
    readLocal();
  }

  void readLocal(){
    setState(() {
      id = settingProvider.getPref(FirestoreConstants.id) ?? "";
      nickname = settingProvider.getPref(FirestoreConstants.nickname) ?? "";
      aboutMe = settingProvider.getPref(FirestoreConstants.aboutMe) ?? "";
      photoUrl = settingProvider.getPref(FirestoreConstants.photoUrl) ?? "";
      phoneNumber = settingProvider.getPref(FirestoreConstants.phoneNumber) ?? "";
    });

    controllerNickname = TextEditingController(text: nickname);
    controllerAboutMe = TextEditingController(text: aboutMe);
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.gallery).catchError((err){
      Fluttertoast.showToast(msg: err.toString());
    });
    File? image;
    if(pickedFile != null){
      image = File(pickedFile.path);
    }
    if(image != null){
      setState(() {
        avatarImageFile = image;
        isLoading = true;
      });
      uploadFile();
      isLoading = false;
    }
  }

  Future uploadFile() async {
    String fileName = id;
    UploadTask uploadTask = settingProvider.uploadFile(avatarImageFile!, fileName);
    try{
      TaskSnapshot snapshot = await uploadTask;
      photoUrl = await snapshot.ref.getDownloadURL();

      UserChat updateInfo = UserChat(
        id: id,
        photoUrl: photoUrl,
        nickname: nickname,
        aboutMe: aboutMe,
        phoneNumber: phoneNumber,
      );
      settingProvider.updateDataFirestore(FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
      .then((data) async{
        await settingProvider.setPref(FirestoreConstants.photoUrl, photoUrl);
        setState(() {
          //isLoading = true;
        });
      }).catchError((err){
        setState(() {
          //isLoading = true;
        });
        Fluttertoast.showToast(msg: err.toString());
      });
    } on FirebaseException catch (e){
      setState(() {
        //isLoading = true;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  void handleUpdateData(){
    focusNodeNickname.unfocus();
    focusNodeAboutMe.unfocus();

    setState(() {
      isLoading = true;

      if(dialCodeDigits != "+00" && _controller.text != ""){
        phoneNumber = dialCodeDigits + _controller.text.toString();
      }
    });
    UserChat updateInfo = UserChat(
      id: id,
      photoUrl: photoUrl,
      nickname: nickname,
      aboutMe: aboutMe,
      phoneNumber: phoneNumber,
    );
    settingProvider.updateDataFirestore(FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
    .then((data) async {
      await settingProvider.setPref(FirestoreConstants.nickname, nickname);
      await settingProvider.setPref(FirestoreConstants.aboutMe, aboutMe);
      await settingProvider.setPref(FirestoreConstants.photoUrl, photoUrl);
      await settingProvider.setPref(FirestoreConstants.phoneNumber, phoneNumber);

      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: "Updated Successfully");
    }).catchError((err){
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: err.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    // double width = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoButton(
                  onPressed: getImage,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  child: avatarImageFile == null
                      ? photoUrl.isNotEmpty
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(70),
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      width: 130,
                      height: 130,
                      errorBuilder: (context, object, stackTrace){
                        return const Icon(
                          Icons.account_circle,
                          size: 130,
                          color: ColorConstants.greyColor,
                        );
                      },
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress){
                        if(loadingProgress == null) return child;
                        return SizedBox(
                          width: 90,
                          height: 90,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: ColorConstants.primaryColor,
                              value: loadingProgress.expectedTotalBytes != null &&
                                  loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ) : const Icon(
                    Icons.account_circle,
                    size: 90,
                    color: ColorConstants.greyColor,
                  )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(45),
                          child: Image.file(
                            avatarImageFile!,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                    ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    child: const Text(
                      "Name",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,fontWeight: FontWeight.bold, color: ColorConstants.primaryColor
                      ),
                    ),
                    margin: const EdgeInsets.only(left: 10, bottom: 5, top: 10),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(primaryColor: ColorConstants.primaryColor),
                    child: TextField(
                      style: const TextStyle(color: Colors.grey),
                      decoration: const InputDecoration(
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: ColorConstants.greyColor2),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: ColorConstants.primaryColor),
                        ),
                        hintText: 'Enter your name',
                        contentPadding: EdgeInsets.all(5),
                        hintStyle: TextStyle(color: ColorConstants.greyColor),
                      ),
                      controller: controllerNickname,
                      onChanged: (value){
                        nickname = value;
                      },
                      focusNode: focusNodeNickname,
                    ),
                  ),
                  Container(
                    child: const Text(
                      'About Me',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,fontWeight: FontWeight.bold, color: ColorConstants.primaryColor
                      ),
                    ),
                    margin: const EdgeInsets.only(left: 10,top: 30, bottom: 5),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(primaryColor: ColorConstants.primaryColor),
                    child: TextField(
                      style: const TextStyle(color: Colors.grey),
                      decoration: const InputDecoration(
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: ColorConstants.greyColor2),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: ColorConstants.primaryColor),
                        ),
                        hintText: 'Enter about yourself',
                        contentPadding: EdgeInsets.all(5),
                        hintStyle: TextStyle(color: ColorConstants.greyColor),
                      ),
                      controller: controllerAboutMe,
                      onChanged: (value){
                        aboutMe = value;
                      },
                      focusNode: focusNodeAboutMe,
                    ),
                  ),
                  /*Container(
                    padding: EdgeInsets.only(top: 40.0, left: 10.0),
                    child: SizedBox(
                      height: 40,
                      width: width / 2.5,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChangeKey(),
                              )
                          );
                        },
                        icon: Icon(Icons.vpn_key_outlined),
                        label: Text(
                          'Change Key',
                          style: TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                        style: ButtonStyle(
                          foregroundColor: MaterialStateProperty.all<Color>(
                            const Color(0xFFFFFFFF),
                          ),
                          backgroundColor: MaterialStateProperty.all<Color>(
                            const Color(0xFF4F4F4F),
                          ),
                        ),
                      ),
                    ),
                  ),*/
                  /*Container(
                    child: const Text(
                      'Phone Number',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,fontWeight: FontWeight.bold, color: ColorConstants.primaryColor
                      ),
                    ),
                    margin: const EdgeInsets.only(left: 10,top: 30, bottom: 5),
                  ),*/
                  /*Theme(
                    data: Theme.of(context).copyWith(primaryColor: ColorConstants.primaryColor),
                    child: TextField(
                      style: const TextStyle(color: Colors.grey),
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: phoneNumber,
                        contentPadding: const EdgeInsets.all(7),
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),*/
                  /*Container(
                    margin: const EdgeInsets.only(left: 10, top: 30, bottom: 5),
                    child: SizedBox(
                      width: 400,
                      height: 60,
                      child: CountryCodePicker(
                        onChanged: (country){
                          setState(() {
                            dialCodeDigits = country.dialCode!;
                          });
                        },
                        initialSelection: "IT",
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: false,
                        favorite: const ["+1", "US", "+91", "IN"],
                      ),
                    ),
                  ),*/

                  /*Container(
                    margin: const EdgeInsets.only(left: 30,right: 30),
                    child: TextField(
                      style: const TextStyle(color: Colors.grey),
                      decoration: InputDecoration(
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: ColorConstants.greyColor2),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: ColorConstants.primaryColor),
                        ),
                        hintText: "Phone Number",
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefix: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(dialCodeDigits, style: const TextStyle(color: Colors.grey)),
                        ),
                      ),
                      maxLength: 12,
                      keyboardType: TextInputType.number,
                      controller: _controller,
                    ),
                  ),*/

                ],
              ),
              Container(
                margin: const EdgeInsets.only(top: 50, bottom: 50),
                child: OutlinedButton(
                  onPressed: handleUpdateData,
                  child: const Text(
                    'Update',
                    style: TextStyle(fontSize: 16, color: Colors.white),
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
            ],
          ),
        ),
        Container(),
        Positioned(
          child: isLoading ? const Center(child: LoadingView()) : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

