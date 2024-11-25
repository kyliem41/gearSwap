import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/cart/cart.dart';
import 'package:sample/profile/editPost.dart';
import 'package:sample/profile/profile.dart';
import 'package:sample/profile/sellerProfile.dart';
import 'package:sample/shared/config_utils.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class ProfilePostDetailPage extends StatefulWidget {
  final String postId;

  const ProfilePostDetailPage({
    Key? key,
    required this.postId,
  }) : super(key: key);

  @override
  State<ProfilePostDetailPage> createState() => _ProfilePostDetailPageState();
}

class _ProfilePostDetailPageState extends State<ProfilePostDetailPage> {
  bool isLoading = true;
  bool hasError = false;
  Map<String, dynamic>? post;
  bool isLiked = false;
  String? userId;
  String? baseUrl;
  bool _isCurrentUserPost = false;
  TextEditingController messageController = TextEditingController();
  int _currentImageIndex = 0;
  PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _initialize().then((_) {
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

  Future<void> _initialize() async {
    try {
      baseUrl = await ConfigUtils.getBaseUrl();
      await _loadUserData(); // Load user data first
      if (userId != null) {
        // Only load post details if we have a user
        await _loadPostDetails();
        await _verifyCurrentUser();
      } else {
        print('No user ID available');
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Initialization error: $e');
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

      print('Raw user string from prefs: $userString'); // Debug log

      if (userString != null) {
        final userData = json.decode(userString);
        setState(() {
          userId = userData['id'].toString();
        });
        print('User ID loaded: $userId');
      } else {
        print('No user data found in SharedPreferences');
      }
    } catch (e) {
      print('Error loading user data: $e');
      throw Exception('Failed to load user data: $e');
    }
  }

  Future<void> _verifyCurrentUser() async {
    try {
      if (post == null) {
        print('Post data not available for verification');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');

      if (userString != null) {
        final userData = json.decode(userString);
        final currentUserId = userData['id'].toString();
        final postUserId = post!['userid'].toString();

        print('Verifying user access:');
        print('Current user ID: $currentUserId');
        print('Post user ID: $postUserId');

        setState(() {
          _isCurrentUserPost = currentUserId == postUserId;
        });
      }
    } catch (e) {
      print('Error verifying current user: $e');
    }
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

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('Response decoded successfully');

        if (jsonResponse['post'] != null) {
          final postData = jsonResponse['post'];

          // Process images if they exist
          if (postData['images'] != null && postData['images'] is List) {
            List<Map<String, dynamic>> cleanedImages = [];

            for (var image in postData['images']) {
              try {
                if (image != null && image['data'] != null) {
                  String cleanedData =
                      cleanBase64String(image['data'].toString());
                  cleanedImages.add({
                    'data': cleanedData,
                    'content_type': image['content_type'] ?? 'image/jpeg'
                  });
                }
              } catch (e) {
                print('Error processing image: $e');
                // Skip invalid images
                continue;
              }
            }

            postData['images'] = cleanedImages;
          } else {
            postData['images'] = [];
          }

          setState(() {
            post = postData;
            isLoading = false;
          });
        } else {
          throw Exception('Post data not found in response');
        }
      } else {
        throw Exception('Failed to load post details');
      }
    } catch (e) {
      print('Error in _loadPostDetails: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _addToCart() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to add to cart')),
    );
  }

  Future<void> _checkIfPostLiked() async {
    if (baseUrl == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');

      if (idToken == null || userId == null) {
        throw Exception('No authentication token or user ID found');
      }

      final url = Uri.parse('$baseUrl/likedPosts/$userId/${widget.postId}');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          isLiked = true;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          isLiked = false;
        });
      } else {
        throw Exception('Failed to check like status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking like status: $e');
    }
  }

  Future<void> _toggleLike() async {
    if (baseUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Configuration error. Please try again later.')),
      );
      return;
    }

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
        final response = await http.post(
          Uri.parse('$baseUrl/likedPosts/$userId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: json.encode({
            'postId': widget.postId,
          }),
        );

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
        final response = await http.delete(
          Uri.parse('$baseUrl/likedPosts/$userId/${widget.postId}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            isLiked = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post unliked')),
          );
        } else {
          throw Exception('Failed to unlike post: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error toggling like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to ${isLiked ? 'unlike' : 'like'} post')),
      );
    }
  }

  Future<void> _markAsSold() async {
    if (baseUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Configuration error. Please try again later.')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');
      final userStr = prefs.getString('user');

      if (idToken == null || userStr == null) {
        throw Exception('No authentication data found');
      }

      final userData = json.decode(userStr);
      final userId = userData['id']?.toString();

      if (userId == null) {
        throw Exception('User ID not found in stored data');
      }

      final url = Uri.parse('$baseUrl/posts/update/$userId/${widget.postId}');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({
          'isSold': true,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          post!['isSold'] = true;
        });
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post marked as sold')),
        );
      } else {
        throw Exception('Failed to update post: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking post as sold: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark post as sold: ${e.toString()}')),
      );
    }
  }

  Future<void> _deletePost() async {
    if (baseUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Configuration error. Please try again later.')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');
      final userStr = prefs.getString('user');

      if (idToken == null) {
        throw Exception('No authentication token found');
      }
      if (userStr == null) {
        throw Exception('No user data found');
      }

      final userData = json.decode(userStr);
      final userId = userData['id']?.toString();

      if (userId == null) {
        throw Exception('User ID not found in stored data');
      }

      print('Attempting to delete post with ID: ${widget.postId}');
      print('User ID from stored data: $userId');
      print('Post user ID: ${post?['userid']}');

      // Make sure the userId matches before attempting to delete
      if (post?['userid'].toString() != userId) {
        throw Exception('Not authorized to delete this post');
      }

      final url = Uri.parse('$baseUrl/posts/delete/$userId/${widget.postId}');

      print('Delete URL: $url');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      print('Delete response status: ${response.statusCode}');
      print('Delete response body: ${response.body}');

      if (response.statusCode == 200) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
        Navigator.of(context).pop(); // Return to previous screen
      } else {
        final responseData = json.decode(response.body);
        throw Exception(responseData['error'] ??
            'Failed to delete post: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting post: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete post: ${e.toString()}')),
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

  String cleanBase64String(String input) {
    try {
      // Remove any logging or debugging information before the /9j prefix
      if (input.contains('/9j/')) {
        input = input.substring(input.indexOf('/9j/'));
      }

      // Remove any data URL prefix if present
      if (input.contains('data:image/')) {
        input = input.split('base64,').last;
      }

      // Remove all whitespace and newlines
      input = input.replaceAll(RegExp(r'\s+'), '');

      // Only keep valid base64 characters and the /9j/ prefix
      input = input.replaceAll(RegExp(r'[^A-Za-z0-9+/=\/]'), '');

      // Handle padding
      while (input.length % 4 != 0) {
        input += '=';
      }

      try {
        // Test decode just to validate
        base64Decode(input);
        return input;
      } catch (e) {
        print('Invalid base64 after cleaning: $e');

        // If the first attempt fails, try removing the /9j/ prefix
        if (input.startsWith('/9j/')) {
          final stripped = input.substring(4); // Remove /9j/
          try {
            base64Decode(stripped);
            return stripped;
          } catch (e2) {
            print('Failed to decode even without prefix: $e2');
            throw FormatException('Invalid base64 data');
          }
        } else {
          throw FormatException('Invalid base64 data');
        }
      }
    } catch (e) {
      print('Error cleaning base64 string: $e');
      throw FormatException('Failed to clean base64 data');
    }
  }

// Also let's add a debug print in _buildPostImage
  Widget _buildPostImage(Map<String, dynamic> image) {
    try {
      if (image == null || image['data'] == null) {
        print('No image data provided');
        return _buildPlaceholder();
      }

      try {
        String base64String = image['data'].toString();
        print(
            'Original base64 prefix: ${base64String.substring(0, min(50, base64String.length))}...');

        base64String = cleanBase64String(base64String);
        print(
            'Cleaned base64 prefix: ${base64String.substring(0, min(50, base64String.length))}...');

        try {
          final imageBytes = base64Decode(base64String);
          print('Successfully decoded ${imageBytes.length} bytes');

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
          print('Error decoding base64: $e');
          return _buildPlaceholder();
        }
      } catch (e) {
        print('Error cleaning base64 string: $e');
        return _buildPlaceholder();
      }
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

  bool canModifyPost() {
    return userId != null &&
        post != null &&
        post!['userid'].toString() == userId;
  }

  Widget _buildPostMenu() {
    if (!_isCurrentUserPost) return Container();

    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        color: Color.fromARGB(248, 255, 255, 255),
        size: 30,
      ),
      color: Color.fromARGB(248, 255, 255, 255),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _navigateToEditPost();
            break;
          case 'delete':
            _showDeleteConfirmation();
            break;
          case 'sold':
            _markAsSold();
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit Post'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'sold',
          child: ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text(
                post?['isSold'] == true ? 'Mark as Available' : 'Mark as Sold'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete),
            title: Text('Delete Post'),
            textColor: Colors.red,
            iconColor: Colors.red,
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
            'Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost();
            },
            child: Text('Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _navigateToEditPost() {
    // Log the original post details for debugging
    print('Original post details:');
    print('Size: ${post?['size']}');
    print('Category: ${post?['category']}');
    print('ClothingType: ${post?['clothingType']}');
    print('Tags: ${post?['tags']}');
    print('Photos: ${post?['photos']}');

    // Ensure tags and photos are properly formatted
    List<String> formattedTags = [];
    if (post?['tags'] != null) {
      if (post!['tags'] is String) {
        try {
          formattedTags = List<String>.from(json.decode(post!['tags']));
        } catch (e) {
          print('Error parsing tags: $e');
        }
      } else if (post!['tags'] is List) {
        formattedTags = List<String>.from(post!['tags']);
      }
    }

    List<String> formattedPhotos = [];
    if (post?['photos'] != null) {
      if (post!['photos'] is String) {
        try {
          formattedPhotos = List<String>.from(json.decode(post!['photos']));
        } catch (e) {
          print('Error parsing photos: $e');
        }
      } else if (post!['photos'] is List) {
        formattedPhotos = List<String>.from(post!['photos']);
      }
    }

    final sanitizedDetails = {
      'description': post?['description']?.toString() ?? '',
      'price': post?['price']?.toString() ?? '',
      'size': post?['size']?.toString(),
      'category': post?['category']?.toString(),
      'clothingType': post?['clothingType']?.toString(),
      'tags': formattedTags,
      'photos': formattedPhotos,
    };

    print('Sanitized post details for edit:');
    print(json.encode(sanitizedDetails));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPostPage(
          postId: widget.postId,
          postDetails: sanitizedDetails,
        ),
      ),
    ).then((_) {
      _loadPostDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(60.0),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.deepOrange,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                // Logo and title
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_calls_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'GearSwap',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                // Right side icons
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.shopping_bag_outlined,
                          color: Color.fromARGB(248, 255, 255, 255),
                          size: 30,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CartPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    _buildPostMenu(),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: BottomNavBar(),
      );
    }

    if (hasError || post == null) {
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(60.0),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.deepOrange,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                // Logo and title
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_calls_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'GearSwap',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                // Right side icons
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.shopping_bag_outlined,
                          color: Color.fromARGB(248, 255, 255, 255),
                          size: 30,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CartPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    _buildPostMenu(),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load post details',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  textStyle:
                      theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
                ),
                onPressed: _loadPostDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.deepOrange,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              // Logo and title
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_calls_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'GearSwap',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              // Right side icons
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: IconButton(
                      icon: Icon(
                        Icons.shopping_bag_outlined,
                        color: Color.fromARGB(248, 255, 255, 255),
                        size: 30,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CartPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildPostMenu(),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () async {
                if (baseUrl == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Configuration error. Please try again later.')),
                  );
                  return;
                }

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
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post!['description'] ?? 'No description provided',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (post!['size'] != null)
                    Text(
                      'Size: ${post!['size']}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 8),
                  if (post!['category'] != null)
                    Text(
                      'Category: ${post!['category']}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 8),
                  if (post!['clothingType'] != null)
                    Text(
                      'Type: ${post!['clothingType']}',
                      style: theme.textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Add to Cart button
                ElevatedButton.icon(
                  onPressed: post?['isSold'] == true ? null : _addToCart,
                  icon: Icon(Icons.shopping_cart,
                      color: theme.colorScheme.onPrimary),
                  label: Text(
                    post?['isSold'] == true ? 'Sold' : 'Add to Cart',
                    style: theme.textTheme.labelLarge,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                // Like count display
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite, color: Colors.red, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${post!['likecount'] ?? 0}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                // Message button
                ElevatedButton.icon(
                  onPressed: _messageUser,
                  icon: Icon(Icons.message, color: theme.colorScheme.onPrimary),
                  label: Text('Message', style: theme.textTheme.labelLarge),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            if (post?['isSold'] == true)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.red,
                child: Center(
                  child: Text(
                    'SOLD',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}
