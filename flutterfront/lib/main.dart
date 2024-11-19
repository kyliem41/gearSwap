import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar.dart';
import 'package:sample/logIn/logIn.dart';
import 'package:sample/logIn/updatePass.dart';
import 'package:sample/posts/postDetails.dart';
import 'package:sample/shared/config_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

void main() {
  GoRouter.optionURLReflectsImperativeAPIs = true;
  runApp(const loginUser());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      debugLogDiagnostics: true,
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const loginUser(),
        ),
        GoRoute(
          path: '/update-password',
          builder: (context, state) => const UpdatePasswordPage(),
        ),
        // Add a catch-all route for the update-password with query parameters
        GoRoute(
          path: '/update-password/:token/:userId',
          builder: (context, state) {
            final token = state.pathParameters['token'];
            final userId = state.pathParameters['userId'];
            print('Token: $token, UserId: $userId');
            return UpdatePasswordPage();
          },
        ),
      ],
    );

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
  String? baseUrl;

  @override
  void initState() {
    super.initState();
    _initializeBaseUrl();
  }

  Future<void> _initializeBaseUrl() async {
    baseUrl = await ConfigUtils.getBaseUrl();
    _getPosts();
  }

  Future<void> _getPosts() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      if (baseUrl == null) {
        throw Exception('Configuration not initialized');
      }

      // Get the stored tokens
      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');

      if (idToken == null) {
        print('No authentication token found');
        setState(() {
          hasError = true;
          isLoading = false;
        });
        return;
      }

      var url = Uri.parse('$baseUrl/posts');

      print('Fetching posts with token...');
      var response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        // Extract the posts array from the response
        List<dynamic> postsData = data['posts'];

        print('Fetched ${postsData.length} posts');

        setState(() {
          posts = postsData;
          hasError = false;
          isLoading = false;
        });
      } else {
        print('Failed to load posts: ${response.body}');
        throw Exception('Failed to load posts');
      }
    } catch (e) {
      print('Error fetching posts: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _refreshPosts() async {
    await _getPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavBar(),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : hasError
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Failed to load posts"),
                          ElevatedButton(
                            onPressed: _refreshPosts,
                            child: Text("Try Again"),
                          ),
                        ],
                      ),
                    )
                  : posts.isEmpty
                      ? Center(child: Text("No posts available"))
                      : GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10.0,
                            mainAxisSpacing: 10.0,
                            childAspectRatio: 0.7,
                          ),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PostDetailPage(
                                      postId: post['id'].toString(),
                                    ),
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
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              if (post['photos'] != null &&
                                                  post['photos'].isNotEmpty)
                                                Image.network(
                                                  post['photos'][0],
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      Icon(
                                                    Icons.image,
                                                    size: 40,
                                                    color: Colors.grey[400],
                                                  ),
                                                )
                                              else
                                                Icon(
                                                  Icons.image,
                                                  size: 40,
                                                  color: Colors.grey[400],
                                                ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '\$${post['price']}',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            post['description'] ??
                                                'No description',
                                            style: TextStyle(fontSize: 14),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (post['size'] != null)
                                            Text(
                                              'Size: ${post['size']}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}
