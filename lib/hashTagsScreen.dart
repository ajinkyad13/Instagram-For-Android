import 'package:assignment2/wallScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'dart:developer';
import 'dart:convert';
import 'dart:io' as Io;
import 'package:assignment2/wallScreenResponse.dart';

class HashtagPage extends StatefulWidget {
  @override
  _HashtagPageState createState() => _HashtagPageState();
}

class _HashtagPageState extends State<HashtagPage> {
  List hashTagsList;
  String selectedHashTag;

  // get the hashtag list
  Future<dynamic> getLists() async {
    const Map<String, String> _headers = {
      'Accept': 'application/json',
    };

    // try fetching
    try {
      final response = await http.get(
          'https://bismarck.sdsu.edu/api/instapost-query/hashtags',
          headers: _headers);
      var data = jsonDecode(response.body);
      hashTagsList = data["hashtags"];
      var strList = jsonEncode(hashTagsList);
      await WallScreenResponses.storeToLocal("hashtaglist", strList);
    }
    // if not able to fetch, read from local
    catch (e) {
      var localListData =
          await WallScreenResponses.readFromLocal("hashtaglist");
      if (localListData == "noData") {
        // if no data in local, return
        return [];
      } else {
        hashTagsList = json.decode(localListData);
        return hashTagsList;
      }
    }
    return hashTagsList;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getLists(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            child: SpinKitDoubleBounce(color: Colors.green, size: 100),
          );
        } else if (snapshot.data.length == 0) {
          return Container(
            alignment: Alignment.center,
            child: Text(
              "Could not connect to the server. \n Please check your internet connection !",
              style: TextStyle(fontSize: 20),
            ),
          );
        } else {
          // log(snapshot.data.toString());
          var data = snapshot.data;
          return Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: ListView.separated(
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.black,
                    ),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(data[index],
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Icon(Icons.arrow_forward_ios_outlined),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => WallPage(
                                      selectedValue: data[index],
                                      selectedType: "hashTag")));
                        },
                      );
                    },
                  ),
                )
              ],
            ),
          );
        }
      },
    );
  }
}
