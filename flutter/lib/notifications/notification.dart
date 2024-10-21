import 'package:flutter/material.dart';

class Notifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 150),
      padding: EdgeInsets.all(5),
      margin: EdgeInsets.only(top: 10, right: 10, left: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            child: Text("U"),
          ),
          SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              child: _notificationContent("User", "Handle", "Text"),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _notificationContent(String user, String userHandle, String text) {
  //final DateTime time = new DateTime(2024);
  String time = "01/05/05";
  String location = "im right here";

  return Flexible(
    child: ListView(
      children: [
        Container(
          margin: EdgeInsets.only(left: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(user,
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                  Container(
                    margin: EdgeInsets.only(left: 5),
                    child: Text(" " + userHandle + " " + location + " " + time,
                        style: TextStyle(
                            color: Color.fromARGB(197, 189, 189, 189))),
                  ),
                ],
              ),
              Container(
                  margin: EdgeInsets.only(top: 15),
                  child: Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ultrices vitae auctor eu augue ut lectus. Purus non enim praesent elementum facilisis leo vel. Dictum fusce ut placerat orci nulla pellentesque dignissim. Mattis enim ut tellus elementum sagittis vitae. Tristique senectus et netus et malesuada fames ac turpis egestas. Malesuada fames ac turpis egestas integer eget aliquet nibh praesent. Non odio euismod lacinia at quis risus. Porta lorem mollis aliquam ut. Proin fermentum leo vel orci porta. Elementum nisi quis eleifend quam adipiscing vitae. Ut venenatis tellus in metus vulputate eu scelerisque felis imperdiet. Lectus urna duis convallis convallis tellus id interdum velit.',
                      style: TextStyle(color: Colors.black))), //text
              SizedBox(height: 10),
              Container(
                margin:
                    EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
  
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
