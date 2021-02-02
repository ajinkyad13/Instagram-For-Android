import 'package:assignment2/signInScreen.dart';
import 'package:assignment2/wallScreenResponse.dart';
import 'package:flutter/material.dart';
import 'package:assignment2/hashTagsScreen.dart';
import 'package:assignment2/usernamesScreen.dart';
import 'package:assignment2/myWallScreen.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        return showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("InstaPost"),
              content: Text("Really quit ?"),
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
                    child: Text("No")),
              ],
            ));
      },
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text("InstaPost"),
            backgroundColor: WallScreenResponses.PrimaryColor,
            actions: <Widget>[
              IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => SignInPage())))
            ],
            bottom: TabBar(
              tabs: [
                Tab(
                  text: "HashTags",
                ),
                Tab(text: "Users"),
                Tab(text: "Post"),
                // Tab(text: "My Posts")
              ],
            ),
          ),
          body: TabBarView(
            children: <Widget>[
              HashtagPage(),
              UsernamesPage(),
              MyWallPage(),
            ],
          ),
        ),
      ),
    );
  }
}
