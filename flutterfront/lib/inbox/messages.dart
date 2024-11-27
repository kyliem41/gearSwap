import 'package:flutter/material.dart';
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar2.dart';

class MessagePage extends StatelessWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavBar2(),
      body: Column(
        children: [
          // Recipient's Profile Picture and Username at the top right
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    'JD', // This is where the profile picture initials or image would go
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'john_doe', // Username of the recipient
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8.0),
              children: const [
                MessageBubble(
                  text: "Hi! I'm your AI stylist. How can I help you today?",
                  isAI: true,
                ),
                MessageBubble(
                  text: "I need help choosing an outfit for a party.",
                  isAI: false,
                ),
                // Add more MessageBubbles as needed
              ],
            ),
          ),
          const MessageInput(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 4,),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isAI;

  const MessageBubble({
    required this.text,
    required this.isAI,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isAI ? Alignment.topLeft : Alignment.topRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: isAI ? Colors.grey[200] : Colors.deepOrange,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isAI ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}

class MessageInput extends StatelessWidget {
  const MessageInput({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController messageController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: "Type your message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: const BorderSide(color: Colors.deepOrange),
                ),
                filled: true,
                fillColor: Colors.deepOrange[100],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.lightBlueAccent),
            onPressed: () {
              // Handle sending the message
              // You can add logic to update the message list here
              messageController.clear();
            },
          ),
        ],
      ),
    );
  }
}
