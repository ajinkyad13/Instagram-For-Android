import 'package:assignment2/wallScreenResponse.dart';
import 'package:assignment2/wallScreenResponse.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io' as Io;
import 'package:hashtagable/hashtagable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class MyWallPage extends StatefulWidget {
  @override
  _MyWallPageState createState() => _MyWallPageState();
}

class _MyWallPageState extends State<MyWallPage> {
  Io.File imageFile;
  String userEmail;
  String userPassword;
  List<String> hashtags;
  String userText;
  String postImageData;

  TextEditingController descController = TextEditingController();

  // text field validator for hashtag and text check
  String checkForDesc() {
    String data = descController.text;
    if (data == "" || data == null) {
      return "noData";
    } else {
      hashtags = extractHashTags(userText ?? "");
      if (hashtags.length == 0) {
        return "noHashtag";
      } else {
        return hashtags.toString();
      }
    }
  }

  // save post locally when offline
  savePostLocal(post, userEmail) async {
    var pathToFile;
    // application doc directory path
    final Io.Directory _appDocDir = await getApplicationDocumentsDirectory();

    // folder path
    final Io.Directory _appDocDirFolder =
        Io.Directory('${_appDocDir.path}/$userEmail/');

    math.Random random = math.Random();
    String randomNumber = random.nextInt(10000).toString();

    // check if folder exists/ if not create one
    if (!await _appDocDirFolder.exists()) {
      final Io.Directory _appDocDirNewFolder =
          await _appDocDirFolder.create(recursive: true);
      pathToFile = _appDocDirNewFolder.path;
    } else {
      var appDir = Io.Directory('${_appDocDir.path}/$userEmail/');
      pathToFile = appDir.path;
    }

    var filePath = "$pathToFile/$randomNumber.json";

    final file = Io.File(filePath);
    await file.writeAsString(post.toString());
  }

  // post image for the current post
  postImage(newPostId) async {
    List<int> imageBytes = imageFile.readAsBytesSync();
    postImageData = base64Encode(imageBytes);
    try {
      final response = await http.post(
          'https://bismarck.sdsu.edu/api/instapost-upload/image',
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'email': userEmail,
            'password': userPassword,
            'image': postImageData,
            'post-id': newPostId
          }));
      var data = jsonDecode(response.body);
      if (data["result"] == "success") {
        return "success";
      } else {
        return data["errors"];
      }
    } catch (e) {
      return "error";
    }
  }

  // post user's current post
  postUserPost(userText, hashtags, imageFile) async {
    int newPostId;
    // get login credentials
    try {
      final loginDetailsPref = await SharedPreferences.getInstance();
      userEmail = loginDetailsPref.getString('email');
      userPassword = loginDetailsPref.getString('password');
    } catch (e) {
      log(e.toString());
    }

    // posting the post
    try {
      final response =
          await http.post('https://bismarck.sdsu.edu/api/instapost-upload/post',
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(<String, dynamic>{
                'email': userEmail,
                'password': userPassword,
                'text': userText,
                'hashtags': hashtags
              }));
      var data = jsonDecode(response.body);

      if (data["result"] == "success") {
        newPostId = data["id"];
      } else {
        return data["errors"];
      }

      if (imageFile != null) {
        var postImageResult = postImage(newPostId);
        if (postImageResult == "success") {
          return "success";
        } else if (postImageResult == "error") {
          return "error while posting image";
        } else {
          return postImageResult;
        }
      }
      return "posted without image";
    }
    // if not able to post, store to local
    catch (e) {
      log(e.toString());
      var tempImageData;
      if (imageFile != null) {
        List<int> imageBytes = imageFile.readAsBytesSync();
        tempImageData = base64Encode(imageBytes);
      }
      var post = jsonEncode(<String, dynamic>{
        'email': userEmail,
        'password': userPassword,
        'text': userText,
        'hashtags': hashtags,
        'imageData': tempImageData
      });
      savePostLocal(post, userEmail);
      return "saved locally";
    }
  }

  // post image selector from Camera/Gallery
  Future imageSelector(BuildContext context, String pickerType) async {
    var cameraImageFile;
    switch (pickerType) {
      case "gallery":
        cameraImageFile = await ImagePicker.pickImage(
            source: ImageSource.gallery, imageQuality: 90);
        break;
      case "camera":
        cameraImageFile = await ImagePicker.pickImage(
            source: ImageSource.camera, imageQuality: 90);
        break;
    }

    if (cameraImageFile != null) {
      print("You selected  image : " + cameraImageFile.path);
      setState(() {
        imageFile = cameraImageFile;
      });
    } else {
      print("Image not selected");
    }
  }

  // bottom pop up for image selection
  void _settingModalBottomSheet(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: new Wrap(
              children: <Widget>[
                new ListTile(
                    title: new Text('Gallery'),
                    onTap: () => {
                          imageSelector(context, "gallery"),
                          Navigator.pop(context),
                        }),
                new ListTile(
                  title: new Text('Camera'),
                  onTap: () => {
                    imageSelector(context, "camera"),
                    Navigator.pop(context)
                  },
                ),
              ],
            ),
          );
        });
  }

  Widget _cardBuilder() {
    return Card(
      elevation: 5,
      child: Container(
        height: 550,
        // padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <
            Widget>[
          Container(
            padding: EdgeInsets.all(0.5),
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              image: DecorationImage(
                  image: imageFile == null
                      ? AssetImage('assets/placeholder.png')
                      : FileImage(imageFile),
                  fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Container(
              alignment: Alignment.center,
              child: RaisedButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: Colors.red)),
                color: Colors.white,
                child: Text("Select an image",
                    style: TextStyle(color: Colors.red)),
                onPressed: () {
                  _settingModalBottomSheet(context);
                },
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 10, right: 10, top: 5),
            child: Divider(
              height: 1,
            ),
          ),
          Container(
            padding: EdgeInsets.all(10),
            child: HashTagTextField(
              controller: descController,
              onChanged: (v) {
                userText = descController.text;
              },
              inputFormatters: [LengthLimitingTextInputFormatter(42)],
              maxLines: 100,
              minLines: 5,
              // controller: commentTextFieldController,
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.black),
                ),
                hintText: 'Add description and hashtags',
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Container(
              alignment: Alignment.center,
              child: RaisedButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: Colors.red)),
                color: Colors.white,
                child: Text("Post", style: TextStyle(color: Colors.red)),
                onPressed: () {
                  var result = checkForDesc();
                  if (result == "noData") {
                    showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                              title: Text('Text missing !'),
                              content: Text('Please add text'),
                            ));
                  } else if (result == "noHashtag") {
                    showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                              title: Text('Hashtag missing !'),
                              content: Text('Please add at least one hashtag. '
                                  '(Hashtag is a keyword starting with #. e.g. #SampleHashtag'),
                              actions: [],
                            ));
                  } else {
                    postUserPost(userText, hashtags, imageFile).then((result) {
                      if (result == "success") {
                        final snackBar = SnackBar(
                          content: Text("Posted with image successfully !"),
                        );
                        Scaffold.of(context).showSnackBar(snackBar);
                      } else if (result == "error while posting image") {
                        final snackBar = SnackBar(
                          content: Text("Error while posting image"),
                        );
                        Scaffold.of(context).showSnackBar(snackBar);
                      } else if (result == "posted without image") {
                        final snackBar = SnackBar(
                          content: Text("Posted without image successfully !"),
                        );
                        Scaffold.of(context).showSnackBar(snackBar);
                      } else if (result == "saved locally") {
                        showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                                  title: Text('No internet connection!'),
                                  content: Text(
                                      'Your post is saved and will be posted when the app is restarted with internet connection !'),
                                ));
                      } else {
                        final snackBar = SnackBar(
                          content: Text(result),
                        );
                        Scaffold.of(context).showSnackBar(snackBar);
                      }
                    });
                  }
                },
              ),
            ),
          )
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (BuildContext context) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(children: <Widget>[
                Text(
                  "Make a post ",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                _cardBuilder()
              ]),
            ),
          );
        },
      ),
    );
  }
}
