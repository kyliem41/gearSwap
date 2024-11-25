import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar2.dart';
import 'package:sample/cart/cart.dart';
import 'package:sample/profile/profile.dart';
import 'package:sample/profile/sellerProfile.dart';
import 'package:sample/shared/config_utils.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class PostDetailPage extends StatefulWidget {
  final String postId;

  const PostDetailPage({
    Key? key,
    required this.postId,
  }) : super(key: key);

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  bool isLoading = true;
  bool hasError = false;
  Map<String, dynamic>? post;
  bool isLiked = false;
  String? userId;
  bool isInCart = false;
  TextEditingController messageController = TextEditingController();
  String? baseUrl;
  int _currentImageIndex = 0;
  PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _initializeBaseUrl().then((_) {
      _loadPostDetails().then((_) {
        if (mounted) {
          _debugPrintImageData();
        }
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeBaseUrl() async {
    baseUrl = await ConfigUtils.getBaseUrl();
    _loadUserData();
  }

  Future<void> _loadPostDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');

      if (idToken == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('$baseUrl/posts/${widget.postId}');
      print('Loading post details from: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);
          print('JSON decoded successfully');

          if (jsonResponse.containsKey('post')) {
            final postData = jsonResponse['post'];
            print('Post data extracted: ${json.encode(postData)}');

            // Ensure images is properly structured
            if (postData['images'] != null) {
              print(
                  'Images data before processing: ${json.encode(postData['images'])}');

              // If images is a string, try to parse it as JSON
              if (postData['images'] is String) {
                try {
                  postData['images'] = json.decode(postData['images']);
                } catch (e) {
                  print('Error parsing images string: $e');
                  // If parsing fails, wrap it in a list
                  postData['images'] = [
                    {'data': postData['images'], 'content_type': 'image/jpeg'}
                  ];
                }
              }

              // Ensure images is a List
              if (postData['images'] is! List) {
                postData['images'] = [];
              }

              // Clean up each image's data
              for (var image in postData['images']) {
                if (image != null && image['data'] != null) {
                  String base64String = image['data'].toString();
                  if (base64String.contains(',')) {
                    base64String = base64String.split(',').last;
                  }
                  base64String = base64String.replaceAll(RegExp(r'\s+'), '');
                  base64String =
                      base64String.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');

                  // Add padding if needed
                  while (base64String.length % 4 != 0) {
                    base64String += '=';
                  }

                  image['data'] = base64String;
                }
              }

              print(
                  'Images data after processing: ${json.encode(postData['images'])}');
            } else {
              postData['images'] = [];
            }

            setState(() {
              post = postData;
              isLoading = false;
            });

            print('Post state updated successfully');
          } else {
            print('Response missing post key: ${jsonResponse.keys.toList()}');
            throw Exception('Invalid response format: missing post data');
          }
        } catch (e) {
          print('JSON processing error: $e');
          throw Exception('Failed to process response: $e');
        }
      } else {
        print('Error response body: ${response.body}');
        throw Exception('Failed to load post details: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error loading post details: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      final idToken = prefs.getString('idToken');

      if (userString != null && idToken != null) {
        final userJson = jsonDecode(userString);
        setState(() {
          userId = userJson['id'].toString();
        });
        print('Loaded userId from user data: $userId');
        await Future.wait([
          _loadPostDetails(),
          _checkIfLiked(), // Add this to check liked status
        ]);
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _checkCartStatus() async {
    try {
      if (userId == null) return;

      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');

      if (idToken == null) return;

      final url = Uri.parse('$baseUrl/cart/$userId');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['cart'] != null) {
          final cartItems = data['cart'] as List;
          final isItemInCart = cartItems
              .any((item) => item['postid'].toString() == widget.postId);

          if (mounted) {
            setState(() {
              isInCart = isItemInCart;
            });
          }
          print('Item in cart status: $isInCart');
        }
      }
    } catch (e) {
      print('Error checking cart status: $e');
    }
  }

  Future<void> _addToCart() async {
    try {
      if (userId == null) {
        final prefs = await SharedPreferences.getInstance();
        final userString = prefs.getString('user');

        if (userString == null) {
          print('No user data found');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to add items to cart')),
          );
          return;
        }

        final userJson = jsonDecode(userString);
        setState(() {
          userId = userJson['id'].toString();
        });
      }

      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');

      if (idToken == null) {
        print('No authentication token found');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to add items to cart')),
        );
        return;
      }

      print('Adding to cart for userId: $userId');
      final url = Uri.parse('$baseUrl/cart/$userId');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({
          'postId': widget.postId,
        }),
      );

      print('Add to cart response status: ${response.statusCode}');
      print('Add to cart response body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          isInCart = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to cart successfully')),
        );
      } else {
        throw Exception('Failed to add to cart: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add to cart')),
      );
    }
  }

  Future<void> _checkIfInCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      final idToken = prefs.getString('idToken');

      if (userString == null || idToken == null) return;

      final userJson = jsonDecode(userString);
      final userId = userJson['id'].toString();

      final url = Uri.parse('$baseUrl/cart/$userId');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['cart'] != null) {
          final items = data['cart'] as List;
          setState(() {
            isInCart = items.any((item) =>
                item['post'] != null &&
                item['post']['id'].toString() == widget.postId);
          });
        }
      }
    } catch (e) {
      print('Error checking cart status: $e');
    }
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CartPage()),
    ).then((_) {
      _checkCartStatus();
    });
  }

  Future<void> _checkIfLiked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');

      if (idToken == null || userId == null) {
        throw Exception('No authentication token or user ID found');
      }

      final url = Uri.parse('$baseUrl/likedPosts/$userId/${widget.postId}');
      print('Checking like status at: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      print('Like check response status: ${response.statusCode}');
      print('Like check response body: ${response.body}');

      setState(() {
        isLiked = response.statusCode == 200;
      });
    } catch (e) {
      print('Error checking like status: $e');
      setState(() {
        isLiked = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save posts')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');

      if (idToken == null) {
        throw Exception('No authentication token found');
      }

      if (!isLiked) {
        // Add like
        final url = Uri.parse('$baseUrl/likedPosts/$userId');

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: json.encode({
            'postId': widget.postId,
          }),
        );

        print('Like response status: ${response.statusCode}');
        print('Like response body: ${response.body}');

        if (response.statusCode == 201) {
          setState(() {
            isLiked = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post saved to wishlist')),
          );
        } else {
          throw Exception('Failed to save post: ${response.statusCode}');
        }
      } else {
        // Remove like
        final url = Uri.parse('$baseUrl/likedPosts/$userId/${widget.postId}');

        final response = await http.delete(
          url,
          headers: {
            'Authorization': 'Bearer $idToken',
          },
        );

        print('Unlike response status: ${response.statusCode}');
        print('Unlike response body: ${response.body}');

        if (response.statusCode == 200) {
          setState(() {
            isLiked = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post removed from wishlist')),
          );
        } else {
          throw Exception('Failed to remove post: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error toggling like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to ${isLiked ? 'remove from' : 'add to'} wishlist'),
        ),
      );
    }
  }

  Future<void> _reportPost() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Why are you reporting this post?'),
            ListTile(
              title: const Text('Inappropriate content'),
              onTap: () {
                Navigator.pop(context);
                // Implement report functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post reported')),
                );
              },
            ),
            // Add more report reasons as needed
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _messageUser() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message Seller'),
        content: TextField(
          controller: messageController,
          decoration: const InputDecoration(
            hintText: 'Type your message...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement message sending functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message sent')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostImage(Map<String, dynamic> image) {
    try {
      if (image != null && image['data'] != null) {
        try {
          String base64String = image['data'].toString();
          // Clean up base64 string
          base64String = base64String.replaceAll(RegExp(r'\s+'), '');
          base64String =
              base64String.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');

          if (base64String.contains(',')) {
            base64String = base64String.split(',').last;
          }

          // Add padding if needed
          int padLength = base64String.length % 4;
          if (padLength > 0) {
            base64String = base64String.padRight(
              base64String.length + (4 - padLength),
              '=',
            );
          }

          try {
            final imageBytes = base64Decode(base64String);
            return Container(
              width: MediaQuery.of(context).size.width,
              height: 300,
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print('Error displaying image: $error');
                  print('Stack trace: $stackTrace');
                  return _buildPlaceholder();
                },
              ),
            );
          } catch (e) {
            print('Primary decode failed, trying alternative method: $e');
            try {
              final codec = const Base64Codec();
              final imageBytes = codec.decode(base64String);
              return Container(
                width: MediaQuery.of(context).size.width,
                height: 300,
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error displaying image: $error');
                    return _buildPlaceholder();
                  },
                ),
              );
            } catch (e2) {
              print('Alternative decode failed: $e2');
              return _buildPlaceholder();
            }
          }
        } catch (e) {
          print('Error processing base64: $e');
          return _buildPlaceholder();
        }
      }
      return _buildPlaceholder();
    } catch (e) {
      print('Error in _buildPostImage: $e');
      return _buildPlaceholder();
    }
  }

  Widget _buildPhotoSection() {
    if (post == null || post!['images'] == null || post!['images'].isEmpty) {
      print('No images available');
      return _buildPlaceholder();
    }

    List<dynamic> images = post!['images'];
    print('Number of images: ${images.length}');

    return StatefulBuilder(
      builder: (context, setState) {
        bool showArrows = false;

        return MouseRegion(
          onEnter: (_) => setState(() => showArrows = true),
          onExit: (_) => setState(() => showArrows = false),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  Container(
                    height: 300,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentImageIndex = index);
                      },
                      itemCount: images.length,
                      itemBuilder: (context, index) =>
                          _buildPostImage(images[index]),
                    ),
                  ),
                  if (images.length > 1) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                        (index) => Container(
                          width: 8.0,
                          height: 8.0,
                          margin: EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == index
                                ? Colors.deepOrange
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (showArrows && images.length > 1) ...[
                // Navigation arrows remain the same
                Positioned(
                  left: 16,
                  child: AnimatedOpacity(
                    opacity: showArrows ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 200),
                    child: IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_back_ios, color: Colors.white),
                      ),
                      onPressed: _currentImageIndex > 0
                          ? () {
                              _pageController.previousPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  child: AnimatedOpacity(
                    opacity: showArrows ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 200),
                    child: IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child:
                            Icon(Icons.arrow_forward_ios, color: Colors.white),
                      ),
                      onPressed: _currentImageIndex < images.length - 1
                          ? () {
                              _pageController.nextPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 300,
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 100, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No image available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _debugPrintImageData() {
    if (post != null && post!['images'] != null) {
      print('Number of images: ${post!['images'].length}');
      post!['images'].asMap().forEach((index, image) {
        print('Image $index:');
        print('  Content type: ${image['content_type']}');
        if (image['data'] != null) {
          String data = image['data'].toString();
          print('  Data prefix: ${data.substring(0, min(50, data.length))}...');
          print('  Data length: ${data.length}');
        } else {
          print('  Data: null');
        }
      });
    } else {
      print('No images data available');
    }
  }

  Widget _buildErrorDisplay(String message) {
    return Container(
      height: 300,
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 50, color: Colors.red),
            SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.red[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartButton() {
    return ElevatedButton.icon(
      onPressed: isInCart ? _navigateToCart : _addToCart,
      icon: Icon(
        isInCart ? Icons.shopping_bag : Icons.shopping_cart,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
      label: Text(
        isInCart ? 'View Cart' : 'Add to Cart',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavBar2(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError || post == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Failed to load post details',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadPostDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            final userStr = prefs.getString('user');
                            final idToken = prefs.getString('idToken');

                            if (userStr != null && idToken != null) {
                              final userData = jsonDecode(userStr);
                              final currentUserId = userData['id'].toString();
                              final postUserId = post!['userid'].toString();

                              if (currentUserId == postUserId) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ProfilePage()),
                                );
                              } else {
                                final url =
                                    Uri.parse('$baseUrl/users/$postUserId');

                                final response = await http.get(
                                  url,
                                  headers: {
                                    'Authorization': 'Bearer $idToken',
                                  },
                                );

                                if (response.statusCode == 200) {
                                  final data = jsonDecode(response.body);
                                  final sellerUserData = data['user'];

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SellerProfilePage(
                                        sellerId: postUserId,
                                      ),
                                    ),
                                  );
                                } else {
                                  throw Exception(
                                      'Failed to fetch seller data');
                                }
                              }
                            }
                          } catch (e) {
                            print('Error navigating to profile: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to load profile')),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                child: Text(
                                  post!['firstname'][0].toUpperCase(),
                                  style: TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.deepOrange,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '@${post!['username']}',
                                style: TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildPhotoSection(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\$${post!['price']}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              post!['description'] ?? 'No description provided',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (post!['size'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Size: ${post!['size']}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                            if (post!['category'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Category: ${post!['category']}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                            if (post!['clothingtype'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Type: ${post!['clothingtype']}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCartButton(),
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey,
                              size: 28,
                            ),
                            onPressed: () => _toggleLike().then((_) {
                              _checkIfLiked();
                            }),
                          ),
                          ElevatedButton.icon(
                            onPressed: _messageUser,
                            icon: Icon(Icons.message,
                                color: Theme.of(context).colorScheme.onPrimary),
                            label: Text('Message',
                                style: Theme.of(context).textTheme.labelLarge),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}
