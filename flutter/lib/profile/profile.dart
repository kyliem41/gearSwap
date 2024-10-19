import 'package:flutter/material.dart';
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar.dart';

class ProfilePage extends StatelessWidget {
  final String profileImageUrl = 'https://hjsg6z4hj9.execute-api.us-east-2.amazonaws.com/Stage/userProfile/{Id}'; // Replace
  final String username = 'john_doe';
  final int followers = 120;
  final int following = 180;
  final String bio = 'Just a person who loves coding and photography.';
  final String location = 'New York, USA';
  final List<String> posts = List.generate(20, (index) => 'https://via.placeholder.com/150');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top half: Profile info
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
            
            // Bottom half: Posts grid
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: posts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Number of columns in grid
                  crossAxisSpacing: 5.0,
                  mainAxisSpacing: 5.0,
                ),
                itemBuilder: (context, index) {
                  return Image.network(posts[index], fit: BoxFit.cover);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(), 
    );
  }

  // Helper method to build followers/following columns
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
