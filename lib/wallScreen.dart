import 'dart:convert';
import 'dart:typed_data';
import 'dart:developer';
import 'package:assignment2/wallScreenResponse.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:assignment2/viewPostScreen.dart';
import 'dart:io' as Io;
import 'package:flutter/services.dart';
import 'package:hashtagable/hashtagable.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class WallPage extends StatefulWidget {
  final String selectedType;
  final String selectedValue;

  WallPage({Key key, @required this.selectedType, this.selectedValue})
      : super(key: key);

  @override
  _WallPageState createState() => _WallPageState(selectedType, selectedValue);
}

class _WallPageState extends State<WallPage> {
  final String selectedType;
  final String selectedValue;
  _WallPageState(this.selectedType, this.selectedValue);

  List<dynamic> postIds;
  String userEmail;
  String userPassword;
  int userRating;
  var placeHolderImageData;
  String hashTagsText;
  String fullText;
  String imageData;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  void updateValues() {
    setState(() {});
  }

  Future<dynamic> getPosts() async {
    print(postIds);
    // get login credentials
    try {
      WallScreenResponses.getUserLoginDetails()
          .then((value) => {userEmail = value[0], userPassword = value[1]});
    } catch (e) {
      log(e.toString());
    }
    // reading Placeholder image
    try {
      ByteData bytes = await rootBundle.load('assets/placeholder.png');
      var buffer = bytes.buffer;
      placeHolderImageData = base64.encode(Uint8List.view(buffer));
    } catch (e) {
      log("B" + e.toString());
    }

    if (selectedType == "user") {
      // get post ids for the selected nickname
      try {
        var response = await http.get(
            'https://bismarck.sdsu.edu/api/instapost-query/nickname-post-ids?nickname=$selectedValue');
        var data = jsonDecode(response.body);
        postIds = data["ids"];
      } catch (e) {
        log("error in getting ids " + e.toString());
        var localListData =
            await WallScreenResponses.readFromLocal(selectedValue);
        if (localListData == "noData") {
          return 'noConnectivity';
        } else {
          List posts = json.decode(localListData);
          return posts;
        }
      }
    } else {
      // get post ids for selected hashtag
      try {
        var updatedSelectedValue = selectedValue.replaceAll('#', '%23');
        var response = await http.get(
            'https://bismarck.sdsu.edu/api/instapost-query/hashtags-post-ids?hashtag=$updatedSelectedValue');

        var data = jsonDecode(response.body);
        postIds = data["ids"];
      } catch (e) {
        log("error in getting ids " + e.toString());
        var localListData =
            await WallScreenResponses.readFromLocal(selectedValue);
        if (localListData == "noData") {
          return [];
        } else {
          List posts = json.decode(localListData);
          return posts;
        }
      }
    }
    List<Map<String, dynamic>> posts = List(postIds.length);
    print(postIds);
    print(postIds.length);
    if (postIds.length != 0) {
      // get posts for the ids
      try {
        for (int i = 0; i < postIds.length; i++) {
          var response = await http.get(
              'https://bismarck.sdsu.edu/api/instapost-query/post?post-id=' +
                  postIds[i].toString());
          var data = jsonDecode(response.body);
          posts[i] = data["post"];
          // store locally
          var strList = jsonEncode(posts);
          await WallScreenResponses.storeToLocal(selectedValue, strList);
        }
        return posts;
      } catch (e) {
        log("Error while fetching the posts");
      }
    } else {
      return 'noData';
    }
  }

  // post card builder for Wall screen
  Widget _cardBuilder(dynamic data, int index) {
    return Card(
      elevation: 5,
      child: Container(
        // padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <
            Widget>[
          ListTile(
            leading: Container(
              width: 50.0,
              height: 50.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    offset: Offset(0, 2),
                    blurRadius: 6.0,
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: WallScreenResponses().getImageForDp(selectedType),
              ),
            ),
            title: Text(
              selectedValue,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(""),
          ),
          Padding(
            padding: EdgeInsets.only(left: 10, right: 10),
            child: Divider(
              height: 1,
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 0, bottom: 5),
            child: FutureBuilder(
              future: WallScreenResponses.getImage(
                  placeHolderImageData, data[index]["image"]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    height: 250,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(),
                  );
                } else {
                  Uint8List imageBytes = base64Decode(placeHolderImageData);
                  imageData = snapshot.data;
                  try {
                    imageBytes = base64Decode(imageData);
                  } catch (e) {
                    log(e.toString());
                  }
                  return Container(
                    padding: EdgeInsets.all(0.5),
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Image.memory(
                      imageBytes,
                      height: 300,
                      width: 100,
                      fit: BoxFit.fill,
                    ),
                  );
                }
              },
            ),
          ),
          Container(
            alignment: Alignment.center,
            child: Card(
              elevation: 2,
              child: SmoothStarRating(
                  allowHalfRating: true,
                  onRated: (v) {
                    userRating = v.toInt();
                    WallScreenResponses.postRating(
                            userEmail,
                            userPassword,
                            postIds == null ? 0 : postIds[index],
                            v.toInt() == 0 ? 1 : v.toInt(),
                            index)
                        .then((result) {
                      _scaffoldKey.currentState.showSnackBar(SnackBar(
                        content: Text('Thanks for rating !'),
                        duration: Duration(seconds: 1),
                      ));
                      setState(() {
                        data[index]["ratings-count"] += 1;
                      });
                    });
                  },
                  starCount: 5,
                  rating: data[index]["ratings-average"] == -1
                      ? 0.0
                      : data[index]["ratings-average"],
                  size: 30.0,
                  isReadOnly: false,
                  color: Colors.black,
                  borderColor: Colors.grey,
                  spacing: 0.0),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.favorite_border_outlined,
                          color: Colors.black,
                          size: 20,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          data[index]["ratings-count"].toString(),
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Icon(
                          Icons.comment_outlined,
                          color: Colors.black,
                          size: 25,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          data[index]["comments"].length.toString(),
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(children: <Widget>[
                      Icon(
                        Icons.star_outlined,
                        color: Colors.black,
                        size: 20,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        data[index]["ratings-average"].toString() == "-1"
                            ? 0.toString()
                            : double.parse(
                                    data[index]["ratings-average"].toString())
                                .toStringAsFixed(1),
                        style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                    ]),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Divider(
                  height: 1,
                ),
                Container(
                    padding: EdgeInsets.only(top: 10),
                    child: HashTagText(
                      text: "$fullText $hashTagsText",
                      decoratedStyle:
                          TextStyle(fontSize: 14, color: Colors.blueAccent),
                      basicStyle: TextStyle(fontSize: 14, color: Colors.black),
                      decorateAtSign: true,
                    )),
                SizedBox(
                  height: 5,
                ),
              ],
            ),
          )
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("InstaPost"),
        backgroundColor: WallScreenResponses.PrimaryColor,
      ),
      body: FutureBuilder(
          future: getPosts(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                child: SpinKitDoubleBounce(color: Colors.green, size: 100),
              );
            } else if (snapshot.data == "noConnectivity") {
              return Container(
                alignment: Alignment.center,
                child: Text(
                  "Could not connect to the server. \nPlease check your internet connection !",
                  style: TextStyle(fontSize: 20),
                ),
              );
            } else {
              var data = snapshot.data;
              if (data != "noData") {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          var hashTags = data[index]["hashtags"].join(" ");
                          hashTagsText = hashTags.replaceAll('##', '#');
                          fullText = data[index]["text"];
                          data[index]["hashtags"].forEach((hashtag) {
                            fullText = fullText.replaceAll(hashtag, '');
                          });
                          return Container(
                            padding: EdgeInsets.all(10),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ViewPostScreen(
                                              data: data,
                                              index: index,
                                              selectedType: selectedType,
                                              selectedValue: selectedValue,
                                              placeHolderImageData:
                                                  placeHolderImageData,
                                              postId: postIds == null
                                                  ? 0
                                                  : postIds[index],
                                              userEmail: userEmail,
                                              userPassword: userPassword,
                                            ))).then((val) => getPosts());
                              },
                              child: _cardBuilder(data, index),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                );
              } else {
                return Container(
                  alignment: Alignment.center,
                  child: Text(
                    "No posts for this ${selectedType.toLowerCase()}..",
                    style: TextStyle(fontSize: 20),
                  ),
                );
              }
            }
          }),
    );
  }
}
