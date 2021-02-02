import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:developer';
import 'package:assignment2/homeScreen.dart';
import 'package:assignment2/signUpScreen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as Io;

class SignInPage extends StatefulWidget {
  @override
  SignInPageState createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  String email;
  String password;

  final GlobalKey<FormState> _signInKey = GlobalKey<FormState>();
  TextEditingController emailFieldController = TextEditingController();
  TextEditingController passwordFieldController = TextEditingController();

  // save login details on successful sign in
  Future<void> saveLoginDetails(String savedEmail, String savedPassword) async {
    try {
      final loginDetails = await SharedPreferences.getInstance();
      loginDetails.setString('email', savedEmail);
      loginDetails.setString('password', savedPassword);
    } catch (e) {
      log(e.toString());
    }
  }

  // get login details when the page loads
  Future<void> getLoginDetails() async {
    try {
      final loginDetails = await SharedPreferences.getInstance();
      email = loginDetails.getString('email');
      password = loginDetails.getString('password');

      emailFieldController.text = email == null ? '' : email;
      passwordFieldController.text = password == null ? '' : password;
    } catch (e) {
      log(e.toString());
    }
  }

  // sign in to the server
  Future<String> signIn(String email, String password) async {
    var result = await checkForConnectivity();
    if (result == "success") {
      final response = await http.get(
          'https://bismarck.sdsu.edu/api/instapost-query/authenticate?email=$email&password=$password');
      var data = jsonDecode(response.body);
      if (data["result"] == true) {
        return "true";
      } else {
        return "false";
      }
    } else {
      return "noConnectivity";
    }
  }

  // check for internet connectivity
  checkForConnectivity() async {
    try {
      final result = await Io.InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return "success";
      }
    } on Io.SocketException catch (_) {
      return "error";
    }
  }

  // send saved posts
  sendSavedPosts() async {
    // get app directory
    final Io.Directory _appDocDir = await getApplicationDocumentsDirectory();
    final Io.Directory _appDocDirFolder =
        Io.Directory('${_appDocDir.path}/$email/');

    // check for saved post of the current user
    if (await _appDocDirFolder.exists()) {
      var postResultData;
      // get list of all the posts
      var listOfPosts = Io.Directory('${_appDocDir.path}/$email/').listSync();
      print(listOfPosts);
      if (listOfPosts.length < 1) {
        return 'noPosts';
      }
      for (int i = 0; i < listOfPosts.length; i++) {
        var temp = listOfPosts[i].path;
        final file = Io.File(temp);
        var postData = jsonDecode(await file.readAsString());

        // check for connectivity
        var result = await checkForConnectivity();

        if (result == "success") {
          // post the post
          final response = await http.post(
              'https://bismarck.sdsu.edu/api/instapost-upload/post',
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(<String, dynamic>{
                'email': email,
                'password': password,
                'text': postData["text"],
                'hashtags': postData["hashtags"]
              }));

          postResultData = jsonDecode(response.body);
          if (postResultData["errors"] == "none") {
            if (postData["imageData"] != null) {
              try {
                final response = await http.post(
                    'https://bismarck.sdsu.edu/api/instapost-upload/image',
                    headers: <String, String>{
                      'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: jsonEncode(<String, dynamic>{
                      'email': email,
                      'password': password,
                      'image': postData["imageData"],
                      'post-id': postResultData["id"]
                    }));
                var data = jsonDecode(response.body);
                if (data["result"] == "success") {
                  await file.delete();
                  return "posted with image";
                }
              } catch (e) {
                log(e.toString());
                return "could not send image";
              }
            } else {
              await file.delete();
              log("posted without image");
            }
            return 1;
          } else {
            return "couldNoSendPost";
          }
          // return "success";
        } else {
          log("Not connected to internet. Delaying sending saved posts!");
          return 'noConnectivity';
        }
      }
    } else {
      return -1;
    }
  }

  // Email textField
  Widget _buildEmailField() {
    return TextFormField(
      controller: emailFieldController,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Email',
        labelStyle: new TextStyle(
          fontSize: 16.0,
          color: new Color(0xFF18776A),
        ),
      ),
      validator: (String value) {
        if (value.isEmpty || value.trim() == "") {
          return "Email is required !";
        }
        if (!value.contains('@')) {
          return "Not a valid email !";
        }
        ;
        return null;
      },
      onChanged: (String value) {
        email = value.trim();
      },
    );
  }

  // password textField
  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordFieldController,
      obscureText: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Password',
        labelStyle: new TextStyle(
          fontSize: 16.0,
          color: new Color(0xFF18776A),
        ),
      ),
      validator: (String value) {
        if (value.isEmpty || value.trim() == "") {
          return "Password is required !";
        }
        return null;
      },
      onChanged: (String value) {
        password = value.trim();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => FutureBuilder(
          future: getLoginDetails(),
          builder: (context, snapshot) => (WillPopScope(
            onWillPop: () {
              return showDialog(
                  context: context,
                  builder: (context) => (AlertDialog(
                        title: Text("InstaPost"),
                        content: Text("Really Quit ?"),
                        actions: [
                          FlatButton(
                              onPressed: () {
                                SystemNavigator.pop();
                              },
                              child: Text("Yes")),
                          FlatButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text("No"))
                        ],
                      )));
            },
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _signInKey,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(height: 30),
                        Container(
                          alignment: Alignment.center,
                          child: Text(
                            "InstaPost",
                            style: TextStyle(fontSize: 40),
                          ),
                        ),
                        SizedBox(height: 30),
                        Container(
                          child: _buildEmailField(),
                        ),
                        SizedBox(height: 10),
                        Container(
                          child: _buildPasswordField(),
                        ),
                        SizedBox(height: 10),
                        Container(
                          child: RaisedButton(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.0),
                                side: BorderSide(color: Colors.red)),
                            color: Colors.white,
                            child: Text("Sign In",
                                style: TextStyle(color: Colors.red)),
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              if (!_signInKey.currentState.validate()) {
                                return;
                              }
                              ;
                              signIn(email, password).then((String result) {
                                if (result == "false") {
                                  final snackBar = SnackBar(
                                      content:
                                          Text("Invalid email or password !"));
                                  Scaffold.of(context).showSnackBar(snackBar);
                                } else if (result == "noConnectivity") {
                                  showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                            title: Text(
                                                'No internet connection! Please make sure that your device is connected to internet !'),
                                            content: Text(''),
                                          ));
                                } else if (result == "true") {
                                  saveLoginDetails(email, password);
                                  ////
                                  sendSavedPosts().then((val) {
                                    print("A");
                                    if (val == "posted without image" ||
                                        val == "posted with image") {
                                      showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                                title: Text(
                                                    'Saved posts posted successfully !'),
                                                content: Text(''),
                                              ));
                                      Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  HomePage()));
                                    } else if (val == "noConnectivity") {
                                      showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                                title: Text(
                                                    'No internet connection! Please make sure that your device is connected to internet !'),
                                                content: Text(''),
                                              ));
                                    } else if (val == "noPosts") {
                                      Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  HomePage()));
                                    }
                                  });
                                }
                              });
                              _signInKey.currentState.save();
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("New user ?"),
                            TextButton(
                              child: Text(" Create an account"),
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                        builder: (context) => SignUpPage()));
                              },
                            ),
                          ],
                        ),
                      ]),
                ),
              ),
            ),
          )),
        ),
      ),
    );
  }
}
