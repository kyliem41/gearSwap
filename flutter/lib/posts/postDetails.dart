import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar2.dart';
import 'package:sample/cart/cart.dart';
import 'package:sample/profile/profile.dart';
import 'package:sample/profile/sellerProfile.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadPostDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');

      if (idToken == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse(
        'https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/posts/${widget.postId}',
      );

      print('Loading post details from: $url');

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
      } else {
        throw Exception('Failed to load post details');
      }
    } catch (e) {
      print('Error loading post details: $e');
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

      if (userString != null) {
        final userJson = jsonDecode(userString);
        setState(() {
          userId = userJson['id'].toString();
        });
        print('Loaded userId from user data: $userId');
        await Future.wait([
          _loadPostDetails(),
          _checkCartStatus(),
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

      final url = Uri.parse(
        'https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/cart/$userId',
      );

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
      final url = Uri.parse(
        'https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/cart/$userId',
      );

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

      final url = Uri.parse(
        'https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/cart/$userId',
      );

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
            const SnackBar(content: Text('Post saved to wishlist')),
          );
        } else {
          throw Exception('Failed to save post: ${response.statusCode}');
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
                                '@${post!['username']}', // This will now use the joined username from users table
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
                              color: isLiked
                                  ? Colors.red
                                  : Theme.of(context).colorScheme.onBackground,
                            ),
                            onPressed: _toggleLike,
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
