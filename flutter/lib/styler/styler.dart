import 'package:flutter/material.dart';
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar.dart';

void main() {
  runApp(const StylistPage());
}

class StylistPage extends StatelessWidget {
  const StylistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: TopNavBar(),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8.0),
                children: [
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
        bottomNavigationBar: BottomNavBar(),
      ),
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
                  borderSide: BorderSide(color: Colors.deepOrange),
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
