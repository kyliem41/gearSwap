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
import 'dart:typed_data';
import 'dart:math';

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

      final url = Uri.parse('$baseUrl/posts?page=1&page_size=20');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        List<dynamic> postsData = data['posts'];

        // Debug first post data
        if (postsData.isNotEmpty) {
          final firstPost = postsData[0];
          print('First post data: ${json.encode(firstPost)}');
          if (firstPost['first_image'] != null) {
            print(
                'First post image data available: ${firstPost['first_image']['content_type']}');
          }
        }

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

  Widget _buildPostImage(Map<String, dynamic> post) {
    try {
      print('Building image for post ${post['id']}');
      final firstImage = post['first_image'];

      if (firstImage != null) {
        String? base64Data = firstImage['data'];
        if (base64Data != null) {
          // Extract the base64 part from the data URI
          if (base64Data.contains('base64,')) {
            base64Data = base64Data.split('base64,')[1];
          }

          try {
            final Uint8List imageBytes = base64Decode(base64Data);
            return Container(
              width: double.infinity,
              height: double.infinity,
              child: Image.memory(
                imageBytes,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print(
                      'Error displaying image for post ${post['id']}: $error');
                  print('Stack trace: $stackTrace');
                  return _buildPlaceholder();
                },
              ),
            );
          } catch (e) {
            print('Error decoding base64 for post ${post['id']}: $e');
            print(
                'Base64 data: ${base64Data.substring(0, min(100, base64Data.length))}...');
            return _buildPlaceholder();
          }
        }
      }

      print('No valid image data found for post ${post['id']}');
      return _buildPlaceholder();
    } catch (e) {
      print('Error in _buildPostImage for post ${post['id']}: $e');
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.image,
          size: 40,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Future<Uint8List> _loadImageData(String postId) async {
    if (baseUrl == null) {
      throw Exception('Base URL not initialized');
    }

    final prefs = await SharedPreferences.getInstance();
    final idToken = prefs.getString('idToken');

    if (idToken == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/posts/$postId/images'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['images'] != null &&
          data['images'] is List &&
          data['images'].isNotEmpty &&
          data['images'][0]['data'] != null) {
        return base64Decode(data['images'][0]['data']);
      }
    }
    throw Exception('Failed to load image: ${response.statusCode}');
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
                            if (index == 0) {
                              print(
                                  'First post data: ${json.encode(post['first_image'])}');
                            }
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
                                        width: double.infinity,
                                        color: Colors.grey[200],
                                        child: _buildPostImage(post),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '\$${post['price']}',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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
