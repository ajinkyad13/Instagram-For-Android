import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:assignment2/homeScreen.dart';
import 'package:assignment2/signInScreen.dart';
import 'dart:developer';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  String firstName;
  String lastName;
  String nickName;
  String email;
  String password;
  bool nickNameAlreadyExists;

  final GlobalKey<FormState> _signUpKey = GlobalKey<FormState>();

  // check if the nickname already exists
  Future<bool> checkNickName(String nickName) async {
    final response = await http.get(
        'https://bismarck.sdsu.edu/api/instapost-query/nickname-exists?nickname=$nickName');

    var data = jsonDecode(response.body);
    if (data["result"].toString() == "true") {
      return true;
    } else {
      return false;
    }
  }

  // add a new user
  Future<String> addNewUser(String firstName, String lastName, String nickName,
      String email, String password) async {
    final response = await http.get(
        'https://bismarck.sdsu.edu/api/instapost-upload/newuser?firstname=$firstName&lastname=$lastName&nickname=$nickName&email=$email&password=$password');
    print(
        'https://bismarck.sdsu.edu/api/instapost-upload/newuser?firstname=$firstName&lastname=$lastName&nickname=$nickName&email=$email&password=$password');
    var data = jsonDecode(response.body);
    print(data);
    if (data["result"].toString() == "fail") {
      return data["errors"].toString();
    } else {
      return "success";
    }
  }

  // First name textField
  Widget _buildFirstNameField() {
    return TextFormField(
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(),
        border: OutlineInputBorder(),
        labelText: 'First Name',
        labelStyle: new TextStyle(
          fontSize: 14.0,
          color: new Color(0xFF18776A),
        ),
      ),
      validator: (String value) {
        if (value.isEmpty || value.trim() == "") {
          return "First name is required !";
        }
        return null;
      },
      onChanged: (String value) {
        firstName = value.trim();
      },
    );
  }

  // Last Name textField
  Widget _buildLastNameField() {
    return TextFormField(
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(),
        border: OutlineInputBorder(),
        labelText: 'Last Name',
        labelStyle: new TextStyle(
          fontSize: 14.0,
          color: new Color(0xFF18776A),
        ),
      ),
      validator: (String value) {
        if (value.isEmpty || value.trim() == "") {
          return "Last name is required !";
        }
        return null;
      },
      onChanged: (String value) {
        lastName = value.trim();
      },
    );
  }

  // nickname textField
  Widget _buildNickNameField() {
    return TextFormField(
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(),
        border: OutlineInputBorder(),
        labelText: 'Nickname',
        labelStyle: new TextStyle(
          fontSize: 14.0,
          color: new Color(0xFF18776A),
        ),
      ),
      validator: (String value) {
        if (value.isEmpty || value.trim() == "") {
          return "Nickname is required !";
        }
        return null;
      },
      onChanged: (String value) {
        nickName = value.trim();
      },
    );
  }

  // Email textField
  Widget _buildEmailField() {
    return TextFormField(
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(),
        border: OutlineInputBorder(),
        labelText: 'Email',
        labelStyle: new TextStyle(
          fontSize: 14,
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
      obscureText: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Password',
        labelStyle: new TextStyle(
          fontSize: 14.0,
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
        builder: (context) => (WillPopScope(
          onWillPop: () {
            return showDialog(
                context: context,
                builder: (context) => AlertDialog(
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
                          child: Text("No"),
                        )
                      ],
                    ));
          },
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _signUpKey,
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
                        child: _buildFirstNameField(),
                      ),
                      SizedBox(height: 10),
                      Container(
                        child: _buildLastNameField(),
                      ),
                      SizedBox(height: 10),
                      Container(
                        child: _buildNickNameField(),
                      ),
                      SizedBox(height: 10),
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
                          child: Text(
                            "Sign Up",
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            if (!_signUpKey.currentState.validate()) {
                              return;
                            }
                            ;
                            checkNickName(nickName).then((bool result) {
                              if (result == true) {
                                final snackBar = SnackBar(
                                  content: Text('Username already taken !'),
                                );
                                Scaffold.of(context).showSnackBar(snackBar);
                              } else {
                                addNewUser(firstName, lastName, nickName, email,
                                        password)
                                    .then((String result) {
                                  if (result != "success") {
                                    final snackBar =
                                        SnackBar(content: Text(result));
                                    Scaffold.of(context).showSnackBar(snackBar);
                                  } else {
                                    Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                            builder: (context) => HomePage()));
                                  }
                                });
                              }
                            });
                            _signUpKey.currentState.save();
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Already a user ?"),
                          TextButton(
                            child: Text("Sign in here"),
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (context) => SignInPage()));
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
    );
  }
}
