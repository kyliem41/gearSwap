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
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print('Full response data: $data'); // Debug full response

        List<dynamic> postsData = data['posts'];
        print(
            'First post full data: ${postsData.isNotEmpty ? postsData[0] : 'No posts'}'); // Debug first post

        if (postsData.isNotEmpty) {
          var firstPost = postsData[0];
          print(
              'First post images field type: ${firstPost['images'].runtimeType}'); // Debug images field type
          print(
              'First post images content: ${firstPost['images']}'); // Debug images content

          if (firstPost['images'] != null &&
              firstPost['images'] is List &&
              firstPost['images'].isNotEmpty) {
            print(
                'First image data: ${firstPost['images'][0]}'); // Debug first image data
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
      final images = post['images'];

      if (images != null &&
          images is List &&
          images.isNotEmpty &&
          images[0] != null &&
          images[0]['data'] != null) {
        String base64String = images[0]['data'];

        // Clean up the base64 string
        base64String = base64String.trim();
        // Remove any data URL prefix if present
        if (base64String.contains(',')) {
          base64String = base64String.split(',').last;
        }
        // Remove any whitespace or newlines
        base64String = base64String.replaceAll(RegExp(r'\s+'), '');

        try {
          final Uint8List imageBytes = base64Decode(base64String);

          return Container(
            width: double.infinity,
            height: double.infinity,
            clipBehavior: Clip.hardEdge, // Add this to ensure proper clipping
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            child: Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (frame == null) {
                  return Center(child: CircularProgressIndicator());
                }
                return child;
              },
              errorBuilder: (context, error, stackTrace) {
                print('Error displaying image: $error');
                print('Stack trace: $stackTrace');
                return _buildPlaceholder();
              },
            ),
          );

          if (posts.isNotEmpty) {
            children.add(_buildTestImage(posts[0]));
          }
        } catch (e) {
          print('Error decoding base64 for post ${post['id']}: $e');
          return _buildPlaceholder();
        }
      } else {
        return _buildPlaceholder();
      }
    } catch (e) {
      print('Error in _buildPostImage for post ${post['id']}: $e');
      return _buildPlaceholder();
    }
  }

  Widget _buildTestImage(Map<String, dynamic> post) {
    try {
      final images = post['images'];
      if (images != null && images is List && images.isNotEmpty) {
        String base64String = images[0]['data'];
        base64String = base64String.trim().replaceAll(RegExp(r'\s+'), '');

        print(
            'Testing image decode with string length: ${base64String.length}');
        print('First 50 chars: ${base64String.substring(0, 50)}');

        return Container(
          width: 200,
          height: 200,
          color: Colors.grey[200],
          child: Image.memory(
            base64Decode(base64String),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Test image error: $error');
              return Icon(Icons.error);
            },
          ),
        );
      }
    } catch (e) {
      print('Test image error: $e');
    }
    return Container(
      width: 200,
      height: 200,
      color: Colors.red,
      child: Center(child: Text('Failed to load test image')),
    );
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Expanded(
                                        child: Container(
                                          width: double.infinity,
                                          color: Colors.grey[200],
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: _buildPostImage(post),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    '\$${post['price']}',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
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
                          )),
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}
