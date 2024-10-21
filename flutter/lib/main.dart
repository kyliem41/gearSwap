import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar.dart';

void main() {
  runApp(const MyApp());
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
  List<dynamic> posts = [];

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
          posts = data;
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
      appBar: TopNavBar(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : hasError
                ? Center(child: Text("Failed to load"))
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: posts.length, // Number of posts
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailPage(
                                  postId: posts[index]
                                      ['id']),
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
                                  color:
                                      Colors.grey[300],
                                  child: Center(
                                    child: Text(
                                      posts[index][
                                          'price'],
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  posts[index][
                                      'description'],
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
        child: Text("Details for Post ID: $postId"),
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}
