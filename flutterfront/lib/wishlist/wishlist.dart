import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar.dart';
import 'package:sample/posts/postDetails.dart';
import 'package:sample/shared/config_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WishlistPage extends StatefulWidget {
  @override
  _WishlistPageState createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  String? _idToken;
  String? _userId;
  String? baseUrl;
  List<dynamic> likedPosts = [];
  bool isLoading = false;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    baseUrl = await ConfigUtils.getBaseUrl();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      final idToken = prefs.getString('idToken');

      if (userStr != null && idToken != null) {
        final userData = json.decode(userStr);
        setState(() {
          _userId = userData['id'].toString();
          _idToken = idToken;
        });
        _loadLikedPosts();
      } else {
        print('No user data or token found');
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Widget _buildPostImage(Map<String, dynamic> post) {
    try {
      print('Post ID: ${post['id']}');
      print('Images data: ${post['images']}');

      if (post['images'] != null &&
          post['images'] is List &&
          post['images'].isNotEmpty &&
          post['images'][0] != null &&
          post['images'][0]['data'] != null) {
        String base64String = post['images'][0]['data'];
        base64String = base64String.trim();
        base64String = base64String.replaceAll(RegExp(r'\s+'), '');

        while (base64String.length % 4 != 0) {
          base64String += '=';
        }

        try {
          final Uint8List imageBytes = base64Decode(base64String);
          return Container(
            width: double.infinity,
            height: double.infinity,
            child: Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error displaying image: $error');
                return _buildPlaceholder();
              },
            ),
          );
        } catch (e) {
          print('Error decoding base64 for post ${post['id']}: $e');
          return _buildPlaceholder();
        }
      } else {
        return FutureBuilder<Uint8List>(
          future: _loadImageData(post['id'].toString()),
          builder: (context, AsyncSnapshot<Uint8List> snapshot) {
            if (snapshot.hasData) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                child: Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error displaying loaded image: $error');
                    return _buildPlaceholder();
                  },
                ),
              );
            }
            return _buildPlaceholder();
          },
        );
      }
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
      child: Icon(
        Icons.image,
        size: 40,
        color: Colors.grey[400],
      ),
    );
  }

  Future<Uint8List> _loadImageData(String postId) async {
    if (baseUrl == null) {
      throw Exception('Base URL not initialized');
    }

    if (_idToken == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/posts/$postId/images'),
      headers: {
        'Authorization': 'Bearer $_idToken',
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

  Future<void> _loadLikedPosts() async {
    if (_idToken == null || _userId == null || baseUrl == null) {
      print('No authentication token, user ID, or base URL found');
      return;
    }

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final url = Uri.parse('$baseUrl/likedPosts/$_userId');
      print('Loading liked posts from: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_idToken',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          likedPosts = data['posts'] ?? [];
          isLoading = false;
          hasError = false;
        });
      } else {
        print('Failed to load liked posts: ${response.body}');
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading liked posts: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _unlikePost(String postId) async {
    try {
      if (_idToken == null || _userId == null) return;

      final url = Uri.parse('$baseUrl/likedPosts/$_userId/$postId');

      print('Unliking post at: $url');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $_idToken',
        },
      );

      print('Unlike response status: ${response.statusCode}');
      print('Unlike response body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          likedPosts.removeWhere((post) => post['id'].toString() == postId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post removed from wishlist')),
        );
      } else {
        throw Exception('Failed to unlike post: ${response.statusCode}');
      }
    } catch (e) {
      print('Error unliking post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove post from wishlist')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFBF5),
      appBar: TopNavBar(),
      body: RefreshIndicator(
        onRefresh: _loadLikedPosts,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : hasError
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Failed to load wishlist'),
                          ElevatedButton(
                            onPressed: _loadLikedPosts,
                            child: Text('Try Again'),
                          ),
                        ],
                      ),
                    )
                  : likedPosts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.favorite_border,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Your wishlist is empty',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Items you like will appear here',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10.0,
                            mainAxisSpacing: 10.0,
                            childAspectRatio: 0.7,
                          ),
                          itemCount: likedPosts.length,
                          itemBuilder: (context, index) {
                            final post = likedPosts[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PostDetailPage(
                                      postId: post['id'].toString(),
                                    ),
                                  ),
                                ).then((_) => _loadLikedPosts());
                              },
                              child: Card(
                                elevation: 4.0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            color: Colors.grey[200],
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    child:
                                                        _buildPostImage(post),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
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
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.favorite,
                                                color: Colors.red,
                                              ),
                                              onPressed: () => _unlikePost(
                                                  post['id'].toString()),
                                            ),
                                          ),
                                        ],
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
      bottomNavigationBar: BottomNavBar(currentIndex: 5,),
    );
  }
}
