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

        // Debug info for first post with image
        if (postsData.isNotEmpty) {
          var firstPost = postsData[0];
          print('First post ID: ${firstPost['id']}');

          if (firstPost['first_image'] != null) {
            var imageData = firstPost['first_image']['data'];
            print(
                'Image content type: ${firstPost['first_image']['content_type']}');
            print(
                'First 100 chars of image data: ${imageData.substring(0, min<int>(100, imageData.length as int))}');

            if (imageData.contains('base64,')) {
              print('Base64 prefix found');
            } else {
              print('No base64 prefix found');
            }
          } else {
            print('No first_image found for first post');
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
    // First try to get the first_image (used in grid view/list)
    if (post['images'] != null && post['images'] is List && post['images'].isNotEmpty) {
      final firstImage = post['images'][0];
      if (firstImage != null && firstImage['data'] != null) {
        try {
          return _buildImageFromData(firstImage['data']);
        } catch (e) {
          print('Error building image from images array: $e');
          return _buildPlaceholder();
        }
      }
    }
    
    // Fallback to first_image if images array is empty
    if (post['first_image'] != null && post['first_image']['data'] != null) {
      try {
        return _buildImageFromData(post['first_image']['data']);
      } catch (e) {
        print('Error building image from first_image: $e');
        return _buildPlaceholder();
      }
    }
    
    return _buildPlaceholder();
  }

  Widget _buildImageFromData(String imageData) {
    try {
      final Uint8List bytes = _base64ToImage(imageData);
      return Container(
        width: double.infinity,
        height: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(4.0)),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading image: $error');
              return _buildPlaceholder();
            },
          ),
        ),
      );
    } catch (e) {
      print('Error processing image data: $e');
      return _buildPlaceholder();
    }
  }

  Uint8List _base64ToImage(String base64String) {
    try {
      // Handle both formats: with and without data URI scheme
      String pureBase64;
      if (base64String.contains(';base64,')) {
        pureBase64 = base64String.split(';base64,')[1].trim();
      } else if (base64String.contains(',')) {
        pureBase64 = base64String.split(',')[1].trim();
      } else {
        pureBase64 = base64String.trim();
      }
      
      // Remove any whitespace
      pureBase64 = pureBase64.replaceAll(RegExp(r'\s+'), '');
      
      // Add padding if needed
      while (pureBase64.length % 4 != 0) {
        pureBase64 += '=';
      }
      
      final bytes = base64Decode(pureBase64);
      if (bytes.isEmpty) {
        throw Exception('Decoded base64 is empty');
      }
      
      print('Successfully decoded image, byte length: ${bytes.length}');
      return bytes;
    } catch (e) {
      print('Error decoding base64: $e');
      print('Base64 string preview: ${base64String.substring(0, min<int>(100, base64String.length))}');
      rethrow;
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