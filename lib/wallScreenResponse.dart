import 'dart:core';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';
import 'dart:io' as Io;
import 'package:path_provider/path_provider.dart';

class WallScreenResponses {
  // primary theme color
  static final PrimaryColor = const Color(0xFF151026);

  // post user ratings
  static postRating(String userEmail, String userPassword, int postId,
      int rating, int index) async {
    try {
      final response = await http.post(
          'https://bismarck.sdsu.edu/api/instapost-upload/rating',
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'email': userEmail,
            'password': userPassword,
            'rating': rating,
            'post-id': postId,
          }));
      var data = jsonDecode(response.body);
      log(data.toString());
    } catch (e) {
      log(e.toString());
    }
  }

  // Get Image for DP
  Widget getImageForDp(selectedType) {
    if (selectedType == "user") {
      return ClipOval(
        child: Image(
          color: Colors.black12,
          height: 50.0,
          width: 50.0,
          image: AssetImage('assets/userImage.png'),
          fit: BoxFit.cover,
        ),
      );
    } else {
      return ClipOval(
        child: Text(
          "#",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
        ),
      );
    }
  }

  // get post image
  static getImage(String placeHolderImageData, int imageId) async {
    try {
      final response = await http.get(
          'https://bismarck.sdsu.edu/api/instapost-query/image?id=${imageId.toString()}');
      final imageData = jsonDecode(response.body)["image"];
      await WallScreenResponses.storeToLocal("imageData$imageId", imageData);
      if (imageData != "none") {
        return imageData.toString();
      } else {
        return placeHolderImageData;
      }
    } catch (e) {
      try {
        var localImageData =
            await WallScreenResponses.readFromLocal("imageData$imageId");
        if (localImageData == "none") {
          return placeHolderImageData;
        } else {
          return localImageData;
        }
      } catch (e) {
        log("Error while fetching the images !");
      }
    }
  }

  // get user login details
  static getUserLoginDetails() async {
    try {
      final loginDetailsPref = await SharedPreferences.getInstance();
      var userEmail = loginDetailsPref.getString('email');
      var userPassword = loginDetailsPref.getString('password');
      return [userEmail, userPassword];
    } catch (e) {
      log(e.toString());
    }
  }

  static postComment(
      String userEmail, String userPassword, String comment, int postId) async {
    // post comment
    if (comment.length > 0 && comment != " ") {
      try {
        var response = await http.post(
          'https://bismarck.sdsu.edu/api/instapost-upload/comment',
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            "email": userEmail,
            "password": userPassword,
            "comment": comment,
            "post-id": postId,
          }),
        );
        var data = jsonDecode(response.body);
        if (data["result"] == "success") {
          return "Comment Posted Successfully";
        } else {
          return "Error while posting comment";
        }
      } catch (e) {
        log(e.toString());
      }
    } else {
      return "noComment";
    }
  }

  // read from local
  static readFromLocal(value) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final tempDirPath = directory.path;
      var filePath = "$tempDirPath" + "/$value.json}";
      final file = Io.File(filePath);
      var data = await file.readAsString();
      return data;
    } catch (e) {
      log("Could not read data for $value" + e.toString());
      return "noData";
    }
  }

  // store locally
  static storeToLocal(filename, value) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final tempDirPath = directory.path;
      var filePath = "$tempDirPath" + "/$filename.json}";
      final file = Io.File(filePath);
      file.writeAsString(value.toString());
    } catch (e) {
      log("Could not save data for $filename" + e.toString());
    }
  }
}
