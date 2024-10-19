import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:sample/appBars/bottomNavBar.dart'; // Assuming BottomNavBar is defined here
import 'package:sample/appBars/topNavBar.dart';
import 'package:sample/signUp/signUp.dart';

void main() {
  runApp(const MyApp()); // Entry point
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GearSwap',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'GearSwap'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isLoading = true;
  bool hasError = false;
  List<dynamic> posts = []; // To hold the fetched posts

  @override
  void initState() {
    super.initState();
    _GetPosts();
  }

  void _GetPosts() async {
    var url = Uri.parse(
        'https://hjsg6z4hj9.execute-api.us-east-2.amazonaws.com/Stage/posts');
    try {
      var response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print(data);

        setState(() {
          posts = data; // Assign the fetched data to the posts list
          hasError = false;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load items');
      }
    } catch (e) {
      print(e);
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavBar(), // TopNavBar here
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : hasError
                ? Center(child: Text("Failed to load"))
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Number of columns
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                      childAspectRatio: 0.7, // Adjust aspect ratio as needed
                    ),
                    itemCount: posts.length, // Number of posts
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          // Handle post click
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailPage(postId: posts[index]['id']), // Navigate to post detail
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
                                      posts[index]['title'], // Replace with actual post title
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  posts[index]['description'], // Replace with actual post description
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
      bottomNavigationBar: BottomNavBar(), // BottomNavBar here
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
        child: Text("Details for Post ID: $postId"), // Display post details
      ),
      bottomNavigationBar: BottomNavBar(), // Same BottomNavBar
    );
  }
}
