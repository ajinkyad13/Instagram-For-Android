import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:developer';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:hashtagable/hashtagable.dart';
import 'package:assignment2/wallScreenResponse.dart';

class ViewPostScreen extends StatefulWidget {
  final data;
  final index;
  final selectedType;
  final selectedValue;
  final placeHolderImageData;
  final postId;
  final userEmail;
  final userPassword;

  ViewPostScreen(
      {Key key,
      @required this.data,
      this.index,
      this.selectedType,
      this.selectedValue,
      this.placeHolderImageData,
      this.postId,
      this.userEmail,
      this.userPassword})
      : super(key: key);

  @override
  _ViewPostScreenState createState() => _ViewPostScreenState(
      data,
      index,
      selectedType,
      selectedValue,
      placeHolderImageData,
      postId,
      userEmail,
      userPassword);
}

class _ViewPostScreenState extends State<ViewPostScreen> {
  final data;
  final index;
  final selectedType;
  final selectedValue;
  final placeHolderImageData;
  final postId;
  final userEmail;
  final userPassword;

  _ViewPostScreenState(
      this.data,
      this.index,
      this.selectedType,
      this.selectedValue,
      this.placeHolderImageData,
      this.postId,
      this.userEmail,
      this.userPassword);
  int userRating;
  String hashTagsText;
  String fullText;

  final commentTextFieldController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  // widget to build comments
  Widget _buildComment(int commentIndex) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: ListTile(
          title: Text(
            data[index]["comments"][commentIndex],
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.favorite_border,
            ),
            color: Colors.grey,
            onPressed: () {
              _scaffoldKey.currentState
                  .showSnackBar(SnackBar(content: Text('Reply Liked !')));
              setState(() {});
            },
          )),
    );
  }

  // post card builder
  Widget _cardBuilder(dynamic data, int index, context) {
    var hashTags = data[index]["hashtags"].join(" ");
    hashTagsText = hashTags.replaceAll('##', '#');
    fullText = data[index]["text"];
    data[index]["hashtags"].forEach((hashtag) {
      fullText = fullText.replaceAll(hashtag, '');
    });
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
                  final imageData = snapshot.data;
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
                    WallScreenResponses.postRating(userEmail, userPassword,
                            postId, v.toInt() == 0 ? 1 : v.toInt(), index)
                        .then((result) {
                      final snackBar = SnackBar(
                        content: Text("Thanks for rating !"),
                        duration: Duration(seconds: 1),
                      );
                      setState(() {
                        data[index]["ratings-count"] += 1;
                      });
                      Scaffold.of(context).showSnackBar(snackBar);
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
      backgroundColor: Color(0xFFEDF0F6),
      body: Builder(
        builder: (BuildContext context) {
          return SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Container(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Padding(
                        padding: EdgeInsets.only(left: 10, right: 10, top: 10),
                        child: _cardBuilder(data, index, context)),
                    Padding(
                      padding: EdgeInsets.only(left: 10, right: 10, top: 10),
                      child: Card(
                        child: Container(
                          height:
                              data[index]["comments"].length.toDouble() * 80,
                          child: ListView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: data[index]["comments"].length,
                            itemBuilder: (context, commentIndex) {
                              return _buildComment(commentIndex);
                            },
                          ),
                        ),
                      ),
                    ),
                  ]),
            ),
          );
        },
      ),
      bottomNavigationBar: Transform.translate(
        offset: Offset(0.0, -1 * MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: EdgeInsets.only(bottom: 5, left: 5, right: 5),
          child: Container(
            height: 80.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(30.0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, -2),
                  blurRadius: 6.0,
                ),
              ],
              color: Colors.white,
            ),
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: HashTagTextField(
                controller: commentTextFieldController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  contentPadding: EdgeInsets.all(20.0),
                  hintText: 'Add a comment',
                  suffixIcon: Container(
                    margin: EdgeInsets.only(right: 4.0),
                    width: 70.0,
                    child: FlatButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      color: Color(0xFF23B66F),
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        var comment = commentTextFieldController.text;
                        WallScreenResponses.postComment(
                                userEmail, userPassword, comment, postId)
                            .then((result) {
                          if (result != "noComment") {
                            _scaffoldKey.currentState.showSnackBar(SnackBar(
                              content: Text('Thanks for the comment !'),
                              duration: Duration(seconds: 1),
                            ));
                            setState(() {
                              data[index]["comments"].add(comment);
                            });
                          } else {
                            log("No comment");
                          }
                        });
                      },
                      child: Icon(
                        Icons.send,
                        size: 25.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
