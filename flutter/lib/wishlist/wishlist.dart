import 'package:flutter/material.dart';
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar.dart';
import 'package:sample/profile/profile.dart';
import 'package:sample/outfits/outfits.dart';

class WishlistPage extends StatefulWidget {
  final String username;

  WishlistPage({Key? key, required this.username}) : super(key: key);

  @override
  _WishlistPageState createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0); // Wishlist as the selected tab
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavBar(),
      body: Column(
        children: <Widget>[
          TabBar(
            controller: _tabController,
            labelColor: Colors.deepOrange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepOrange,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: "Wishlist"),
              Tab(text: "My Swap"),
              Tab(text: "Outfits"),
            ],
            onTap: (index) {
              if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              } else if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => OutfitsPage()),
                );
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "${widget.username}'s Wishlist",
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
              itemCount: 10, // item count
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailPage(postId: index),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
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

class PostDetailPage extends StatelessWidget {
  final int postId;

  PostDetailPage({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavBar(),
      body: Center(
        child: Text("Details for Post $postId"),
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}