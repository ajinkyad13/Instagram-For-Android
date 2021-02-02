import 'package:assignment2/wallScreenResponse.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:assignment2/wallScreen.dart';
import 'dart:developer';

class UsernamesPage extends StatefulWidget {
  @override
  _UsernamesPageState createState() => _UsernamesPageState();
}

class _UsernamesPageState extends State<UsernamesPage> {
  List userNamesList;

  // fetch username list
  Future<dynamic> getLists() async {
    const Map<String, String> _headers = {
      'Accept': 'application/json',
    };
    var response;
    // try fetching
    try {
      response = await http.get(
          'https://bismarck.sdsu.edu/api/instapost-query/nicknames',
          headers: _headers);
      var data = jsonDecode(response.body);
      userNamesList = data["nicknames"];
      var strList = jsonEncode(userNamesList);
      await WallScreenResponses.storeToLocal("userNamesList", strList);
    }
    // if not able to fetch from server, read from local
    catch (e) {
      var localListData =
          await WallScreenResponses.readFromLocal("userNamesList");
      if (localListData == "noData") {
        // if no data in local, return
        return [];
      } else {
        userNamesList = json.decode(localListData);
        return userNamesList;
      }
    }
    return userNamesList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: () {},
        child: FutureBuilder(
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
                          // return Container(
                          //   height: 40,
                          //   // padding: EdgeInsets.only(left: 10),
                          //   child:
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
                                          selectedType: "user")));
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
        ),
      ),
    );
  }
}
