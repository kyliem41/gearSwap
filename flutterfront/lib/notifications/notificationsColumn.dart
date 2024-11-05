import 'package:flutter/material.dart';
import 'package:sample/notifications/notification.dart';

class NotificationColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Notifications', style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color.fromRGBO(0, 121, 107, 1))),
          backgroundColor: Theme.of(context).cardColor,
          actions: <Widget>[
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.arrow_forward_ios_rounded),
              tooltip: 'Hide Notifications',
              color: Color.fromRGBO(0, 121, 107, 1),
            ),
          ],
        ),
        SizedBox(height: 20),
        Container(
          margin: EdgeInsets.only(top: 40),
          padding: EdgeInsets.all(12),
          child: ListView.builder(
            itemBuilder: (_, int index) => Notifications(),
            itemCount: 10,
            reverse: false,
          ),
        ),
      ],
    );
  }
}
