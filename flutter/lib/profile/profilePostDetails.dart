import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/cart/cart.dart';
import 'package:sample/profile/editPost.dart';
import 'package:sample/profile/profile.dart';
import 'package:sample/profile/sellerProfile.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart';

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
  TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPostDetails();
    _loadUserId();
    _verifyCurrentUser();
  }

  Future<void> _verifyCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getString('userId');
    print('Current user ID from storage: $storedUserId');
    if (post != null) {
      print('Post user ID: ${post!['userId']}');
    }
  }

  Future<void> _loadPostDetails() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');

      if (idToken == null) {
        throw Exception('No authentication token found');
      }

      print('Loading details for post ${widget.postId}');

      final url = Uri.parse(
        'https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/posts/${widget.postId}',
      );

      print('Requesting URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          post = data['post'];
          isLoading = false;
        });
        print(
            'Post loaded. Post user ID: ${post!['userid']}, Current user ID: $userId');
      } else {
        throw Exception('Failed to load post details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading post details: $e');
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

  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      final idToken = prefs.getString('idToken');

      print('User string: $userStr');
      print('ID token available: ${idToken != null}');

      if (userStr == null || idToken == null) {
        throw Exception('No authentication data found');
      }

      final userData = json.decode(userStr);
      final loadedUserId = userData['id']?.toString();

      print('Loaded user ID from preferences: $loadedUserId');

      setState(() {
        userId = loadedUserId;
      });
    } catch (e) {
      print('Error loading user ID: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data')),
      );
    }
  }

  Future<void> _checkIfPostLiked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');

      if (idToken == null || userId == null) {
        throw Exception('No authentication token or user ID found');
      }

      final url = Uri.parse(
        'https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/likedPosts/$userId/${widget.postId}',
      );

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
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to like posts')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');

      if (idToken == null) {
        throw Exception('No authentication token found');
      }

      final baseUrl =
          'https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/likedPosts';

      if (!isLiked) {
        // Add like
        final response = await http.post(
          Uri.parse('$baseUrl/$userId'),
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
            const SnackBar(content: Text('Post liked')),
          );
        } else {
          throw Exception('Failed to like post: ${response.statusCode}');
        }
      } else {
        // Remove like
        final response = await http.delete(
          Uri.parse('$baseUrl/$userId/${widget.postId}'),
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

  Widget _buildPhotoSection() {
    // Check if photos exist and are in a valid format
    if (post?['photos'] == null || post!['photos'].isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image, size: 100, color: Colors.grey),
        ),
      );
    }

    // Handle both string and list formats for photos
    List<dynamic> photoList = [];
    if (post!['photos'] is String) {
      // If photos is a single string
      photoList.add(post!['photos']);
    } else if (post!['photos'] is List) {
      photoList = post!['photos'];
    }

    if (photoList.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image, size: 100, color: Colors.grey),
        ),
      );
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 300,
        viewportFraction: 1.0,
        enableInfiniteScroll: false,
      ),
      items: photoList.map((photo) {
        return Builder(
          builder: (BuildContext context) {
            // If photos are not yet implemented as URLs, show placeholder
            if (photo is! String || !Uri.tryParse(photo)!.hasScheme ?? true) {
              return Container(
                width: MediaQuery.of(context).size.width,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.image, size: 100, color: Colors.grey),
                ),
              );
            }

            // If it's a valid URL, try to load the image
            return Image.network(
              photo,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: MediaQuery.of(context).size.width,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.image, size: 100, color: Colors.grey),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Future<void> _markAsSold() async {
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

      final url = Uri.parse(
        'https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/posts/update/$userId/${widget.postId}',
      );

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

      final url = Uri.parse(
        'https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/posts/delete/$userId/${widget.postId}',
      );

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

  bool _canModifyPost() {
    if (post == null || userId == null) return false;
    return post!['userid'].toString() == userId.toString();
  }

  Widget _buildPostMenu() {
    if (!_canModifyPost()) return Container();

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
    print(
        'ClothingType: ${post?['clothingType']}'); // Fixed to match database column
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
                      final url = Uri.parse(
                        'https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/users/$postUserId',
                      );

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
