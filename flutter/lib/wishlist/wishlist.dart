import 'package:flutter/material.dart';
import 'package:sample/appBars/bottomNavBar.dart'; // Import your BottomNavBar
import 'package:sample/appBars/topNavBar.dart'; // Import your TopNavBar

class WishlistPage extends StatelessWidget {
  final String username; // Pass the username to display

  WishlistPage({Key? key, required this.username}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavBar(), // Your top navigation bar
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "${username}'s Wishlist",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Number of columns
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.7, // Adjust aspect ratio as needed
              ),
              itemCount: 10, // Replace with your item count
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Handle post click
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailPage(postId: index), // Navigate to post detail
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Replace with your image
                        Expanded(
                          child: Container(
                            color: Colors.grey[300], // Placeholder for image
                            child: Center(
                              child: Text(
                                "Post $index", // Replace with post title or image
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Description for Post $index", // Replace with post description
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}

// Placeholder for PostDetailPage
class PostDetailPage extends StatelessWidget {
  final int postId;

  PostDetailPage({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavBar(), // You can use the same TopNavBar here
      body: Center(
        child: Text("Details for Post $postId"),
      ),
      bottomNavigationBar: BottomNavBar(), // Same BottomNavBar
    );
  }
}
