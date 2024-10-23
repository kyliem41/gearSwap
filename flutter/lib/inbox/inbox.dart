import 'package:flutter/material.dart';
import 'package:sample/inbox/messages.dart';

class InboxPage extends StatelessWidget {
  // Sample data for messages
  final List<Map<String, String>> messages = [
    {
      'username': 'john_doe',
      'profilePic': 'JD',
      'lastMessage': 'Hey, how are you doing?'
    },
    {
      'username': 'jane_smith',
      'profilePic': 'JS',
      'lastMessage': 'Let me know when you are free to chat.'
    },
    {
      'username': 'mike_tyson',
      'profilePic': 'MT',
      'lastMessage': 'I will be there in a few minutes, thanks!'
    },
    {
      'username': 'linda_parker',
      'profilePic': 'LP',
      'lastMessage': 'Meeting is at 3 PM. Don’t forget to bring the documents.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inbox'),
        backgroundColor: Colors.deepOrange,
      ),
      body: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final String profilePic = message['profilePic']!;
          final String username = message['username']!;
          final String lastMessage = message['lastMessage']!;
          final String messagePreview = lastMessage.length > 20
              ? '${lastMessage.substring(0, 20)}...'
              : lastMessage;

          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: Text(
                  profilePic,
                  style: TextStyle(color: Colors.white),
                ),
              ),
              title: Text(username),
              subtitle: Text(
                messagePreview,
                style: TextStyle(color: Colors.grey),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                // Navigate to full message view (implement later)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessagePage(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: InboxPage(),
  ));
}
