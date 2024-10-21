import 'package:flutter/material.dart';
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar.dart';
import 'package:sample/outfits/outfits.dart';
import 'package:sample/wishlist/wishlist.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final String profileImageUrl = 'https://hjsg6z4hj9.execute-api.us-east-2.amazonaws.com/Stage/userProfile/{Id}';
  final String username = 'john_doe';
  final int followers = 120;
  final int following = 180;
  final String bio = 'Just a person who loves coding and photography.';
  final String location = 'New York, USA';

  @override
  void initState() {
    super.initState();
    // Set initialIndex to 1 to start on the "My Swap" tab
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
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
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.deepOrange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepOrange,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: "Wishlist"),  // Left tab
              Tab(text: "My Swap"),   // Center tab
              Tab(text: "Outfits"),   // Right tab
            ],
            onTap: (index) {
              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => WishlistPage(username: 'john',)),
                );
              } else if (index == 1) {
                // Already on "My Swap" page
              } else if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => OutfitsPage()),
                );
              }
            },
          ),
          Expanded(
            child: _buildMySwapContent(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }

  Widget _buildMySwapContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(profileImageUrl),
                ),
                const SizedBox(height: 10),
                Text(
                  username,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatColumn('Followers', followers),
                    const SizedBox(width: 20),
                    _buildStatColumn('Following', following),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  bio,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_pin, color: Colors.grey),
                    Text(location, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }
}
