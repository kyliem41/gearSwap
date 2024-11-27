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
  bool _mounted = true;
  List<Map<String, dynamic>> processedImages = [];

  @override
  void initState() {
    super.initState();
    _mounted = true;
    _initializeBaseUrl().then((_) {
      if (_mounted) {
        _loadPostDetails().then((_) {
          if (_mounted) {
            _debugPrintImageData();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _mounted = false;
    _pageController.dispose();
    super.dispose();
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

  Future<void> _initializeBaseUrl() async {
    baseUrl = await ConfigUtils.getBaseUrl();
    _loadUserData();
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
          // _checkIfLiked(),
        ]);
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadPostDetails() async {
    if (!_mounted) return;

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

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final Map<String, dynamic> postData = jsonResponse['post'];

        // Process images
        processedImages = [];
        if (postData['images'] != null && postData['images'] is List) {
          List<dynamic> images = postData['images'];
          for (var img in images) {
            if (img is Map<String, dynamic> &&
                img.containsKey('data') &&
                img.containsKey('content_type')) {
              processedImages.add(img);
              print('Added image with content type: ${img['content_type']}');
            }
          }
          print('Processed ${processedImages.length} images');
        }

        if (_mounted) {
          setState(() {
            post = postData;
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load post details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading post details: $e');
      if (_mounted) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
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

  Widget _buildImageFromData(String imageData) {
    try {
      final Uint8List bytes = _base64ToImage(imageData);
      return Image.memory(
        bytes,
        fit: BoxFit.contain, // Changed from cover to contain
        errorBuilder: (context, error, stackTrace) {
          print('Error rendering image: $error');
          return _buildPlaceholder();
        },
      );
    } catch (e) {
      print('Error processing image data: $e');
      return _buildPlaceholder();
    }
  }

  Uint8List _base64ToImage(String base64String) {
    try {
      String cleanBase64 = base64String;

      if (base64String.contains(';base64,')) {
        cleanBase64 = base64String.split(';base64,')[1];
      }

      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
      while (cleanBase64.length % 4 != 0) {
        cleanBase64 += '=';
      }

      return base64Decode(cleanBase64);
    } catch (e) {
      print('Error decoding base64: $e');
      print('Base64 preview: ${base64String.substring(0, 50)}...');
      rethrow;
    }
  }

  Widget _buildPostImage(Map<String, dynamic> imageData) {
    if (imageData['data'] == null || imageData['data'].isEmpty) {
      print('Image data is empty or null');
      return _buildPlaceholder();
    }

    try {
      return Container(
        width: double.infinity,
        child: _buildImageFromData(imageData['data']),
      );
    } catch (e) {
      print('Error building post image: $e');
      return _buildPlaceholder();
    }
  }

  Widget _buildPhotoSection() {
    if (processedImages.isEmpty) {
      print('No processed images to display');
      return _buildPlaceholder();
    }

    return Column(
      children: [
        ConstrainedBox(
          // Add this constraint
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height *
                0.4, // 40% of screen height
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9, // Wider ratio to make image more compact
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                if (_mounted) {
                  setState(() => _currentImageIndex = index);
                }
              },
              itemCount: processedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  width: double.infinity,
                  child: _buildPostImage(processedImages[index]),
                );
              },
            ),
          ),
        ),
        if (processedImages.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                processedImages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Colors.deepOrange
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported,
                  size: 50, color: Colors.grey[400]),
              SizedBox(height: 8),
              Text(
                'Image not available',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
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
    if (isLoading) {
      return Scaffold(
        appBar: TopNavBar2(),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: BottomNavBar(currentIndex: 0,),
      );
    }

    if (hasError || post == null) {
      return Scaffold(
        appBar: TopNavBar2(),
        body: Center(
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
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: 0,),
      );
    }

    String firstLetter = (post!['firstname'] as String?)?.isNotEmpty == true
        ? post!['firstname'][0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: Color(0xFFFFFBF5),
      appBar: TopNavBar2(),
      body: SingleChildScrollView(
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
                        MaterialPageRoute(builder: (context) => ProfilePage()),
                      );
                    } else {
                      final url = Uri.parse('$baseUrl/users/$postUserId');

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
                        throw Exception('Failed to fetch seller data');
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
                        firstLetter,
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.deepOrange,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '@${post!['username'] ?? 'unknown'}',
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
                    '\$${post!['price'] ?? '0.00'}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary),
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
                  onPressed: _toggleLike,
                ),
                ElevatedButton.icon(
                  onPressed: _messageUser,
                  icon: Icon(Icons.message,
                      color: Theme.of(context).colorScheme.onPrimary),
                  label: Text('Message',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0,),
    );
  }
}
