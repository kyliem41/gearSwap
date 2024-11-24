import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/cartNavBar.dart';
import 'package:sample/posts/postDetails.dart';
import 'package:sample/shared/config_utils.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool isLoading = true;
  String? error;
  Map<String, Map<String, dynamic>> sellerInfo = {};
  Map<String, List<Map<String, dynamic>>> cartItems = {};
  String? userId;
  String? baseUrl;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      baseUrl = await ConfigUtils.getBaseUrl();
      print('Initialized with baseUrl: $baseUrl');

      if (baseUrl == null || baseUrl!.isEmpty) {
        throw Exception('Failed to load base URL configuration');
      }

      await _loadUserIdAndCart();
    } catch (e) {
      print('Initialization error: $e');
      if (mounted) {
        setState(() {
          error = 'Failed to initialize: ${e.toString()}';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserIdAndCart() async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');

      if (userString == null) {
        print('No user data found');
        setState(() {
          userId = null;
          isLoading = false;
        });
        return;
      }

      final userJson = jsonDecode(userString);
      final newUserId = userJson['id']?.toString();

      if (newUserId == null) {
        throw Exception('Invalid user data: missing ID');
      }

      print('Loaded userId: $newUserId');

      if (mounted) {
        setState(() {
          userId = newUserId;
        });
      }

      await _loadCartItems();
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          error = 'Failed to load user data: ${e.toString()}';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchSellerInfo(String sellerId) async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Authentication token not found');
      }

      if (baseUrl == null) {
        throw Exception('Base URL not initialized');
      }

      final url = Uri.parse('$baseUrl/userProfile/$sellerId');
      print('Fetching seller info from: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      print('Seller info response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['userProfile'] != null) {
          if (mounted) {
            setState(() {
              sellerInfo[sellerId] = data['userProfile'];
            });
          }
        } else {
          print('No user profile data found for seller: $sellerId');
        }
      } else {
        throw Exception('Failed to fetch seller info: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching seller info: $e');
      // Don't set error state here as this is not critical for the cart functionality
    }
  }

  Future<void> _loadCartItems() async {
    if (!mounted) return;

    try {
      if (baseUrl == null) {
        throw Exception('Base URL not initialized');
      }

      if (userId == null) {
        throw Exception('User ID not available');
      }

      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Authentication token not found');
      }

      print('Loading cart items for user: $userId');
      final cartUrl = Uri.parse('$baseUrl/cart/$userId');

      final cartResponse = await http.get(
        cartUrl,
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      print('Cart response status: ${cartResponse.statusCode}');

      if (cartResponse.statusCode == 200) {
        final cartData = json.decode(cartResponse.body);

        if (cartData['cart'] == null) {
          if (mounted) {
            setState(() {
              cartItems = {};
              isLoading = false;
            });
          }
          return;
        }

        final cartList = cartData['cart'] as List;
        final groupedItems = <String, List<Map<String, dynamic>>>{};
        final fetchedSellerIds = <String>{};

        for (var cartItem in cartList) {
          final postId = cartItem['postid'];
          final postUrl = Uri.parse('$baseUrl/posts/$postId');

          final postResponse = await http.get(
            postUrl,
            headers: {
              'Authorization': 'Bearer $idToken',
            },
          );

          if (postResponse.statusCode == 200) {
            final postData = json.decode(postResponse.body);
            if (postData['post'] != null) {
              final post = postData['post'] as Map<String, dynamic>;
              final sellerId = post['userid'].toString();

              if (!groupedItems.containsKey(sellerId)) {
                groupedItems[sellerId] = [];
                fetchedSellerIds.add(sellerId);
              }
              groupedItems[sellerId]!.add(post);
            }
          } else {
            print('Failed to fetch post $postId: ${postResponse.statusCode}');
          }
        }

        if (mounted) {
          setState(() {
            cartItems = groupedItems;
            isLoading = false;
          });
        }

        for (String sellerId in fetchedSellerIds) {
          await _fetchSellerInfo(sellerId);
        }
      } else {
        throw Exception(
            'Failed to load cart items: ${cartResponse.statusCode}');
      }
    } catch (e) {
      print('Error loading cart: $e');
      if (mounted) {
        setState(() {
          error = 'Failed to load cart items: ${e.toString()}';
          isLoading = false;
          cartItems = {};
        });
      }
    }
  }

  Future<void> _removeFromCart(String postId) async {
    if (!mounted) return;

    try {
      if (baseUrl == null) {
        throw Exception('Base URL not initialized');
      }

      if (userId == null) {
        throw Exception('User ID not available');
      }

      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final url = Uri.parse('$baseUrl/cart/$userId');
      print('Removing item from cart... URL: $url');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({
          'postId': postId,
        }),
      );

      print('Remove from cart response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        await _loadCartItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Item removed from cart')),
          );
        }
      } else {
        throw Exception(
            'Failed to remove item from cart: ${response.statusCode}');
      }
    } catch (e) {
      print('Error removing item from cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to remove item from cart: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildImage(Map<String, dynamic> post) {
    try {
      if (post['images'] != null &&
          post['images'] is List &&
          post['images'].isNotEmpty &&
          post['images'][0] != null &&
          post['images'][0]['data'] != null) {
        String base64String = post['images'][0]['data'];
        // Clean up base64 string
        base64String = base64String.trim();
        base64String = base64String.replaceAll(RegExp(r'\s+'), '');

        // Add padding if needed
        while (base64String.length % 4 != 0) {
          base64String += '=';
        }

        try {
          final Uint8List imageBytes = base64Decode(base64String);
          return Container(
            width: 80,
            height: 80,
            child: Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error displaying image: $error');
                return _buildPlaceholderImage();
              },
            ),
          );
        } catch (e) {
          print('Error decoding base64 for post: $e');
          return _buildPlaceholderImage();
        }
      }
      return _buildPlaceholderImage();
    } catch (e) {
      print('Error in _buildImage: $e');
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: Icon(Icons.image, color: Colors.grey[400]),
    );
  }

  double _calculateGroupTotal(List<Map<String, dynamic>> items) {
    return items.fold(0.0, (sum, item) {
      var price = item['price'];
      print('Original price value: $price (type: ${price.runtimeType})');

      double convertedPrice = 0.0;

      try {
        if (price is String) {
          String cleanPrice = price.replaceAll(RegExp(r'[^\d.]'), '');
          print('Cleaned price string: $cleanPrice');
          convertedPrice = double.tryParse(cleanPrice) ?? 0.0;
        } else if (price is num) {
          convertedPrice = price.toDouble();
        }

        print('Converted price: $convertedPrice');
        return sum + convertedPrice;
      } catch (e) {
        print('Error converting price: $e');
        return sum;
      }
    });
  }

  double _calculateTotalPrice() {
    return cartItems.values.fold(
      0.0,
      (sum, items) => sum + _calculateGroupTotal(items),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              error ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initialize,
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    print('Building cart item: ${json.encode(item)}');

    var price = item['price'];
    double displayPrice = 0.0;

    try {
      if (price is String) {
        String cleanPrice = price.replaceAll(RegExp(r'[^\d.]'), '');
        displayPrice = double.tryParse(cleanPrice) ?? 0.0;
      } else if (price is num) {
        displayPrice = price.toDouble();
      }
    } catch (e) {
      print('Error converting display price: $e');
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(
              postId: item['id'].toString(),
            ),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            _buildImage(item), // Updated to use the new image builder
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['description'] ?? 'No description',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '\$${displayPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeFromCart(item['id'].toString()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CartNavBar(),
      body: userId == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Please log in to view your cart'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initialize,
                    child: Text('Retry'),
                  ),
                ],
              ),
            )
          : isLoading
              ? Center(child: CircularProgressIndicator())
              : error != null
                  ? _buildErrorState()
                  : cartItems.isEmpty
                      ? Center(child: Text('Your cart is empty'))
                      : Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Expanded(
                                child: ListView(
                                  children: cartItems.entries.map((entry) {
                                    String sellerId = entry.key;
                                    List<Map<String, dynamic>> items =
                                        entry.value;
                                    double groupTotal =
                                        _calculateGroupTotal(items);
                                    final seller = sellerInfo[sellerId];
                                    final sellerName = seller != null
                                        ? '@${seller['username']}'
                                        : 'Seller $sellerId';

                                    return Card(
                                      margin: EdgeInsets.only(bottom: 16.0),
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Seller: $sellerName',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 16),
                                            ...items.map(_buildCartItem),
                                            Divider(),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Bagged Total: \$${groupTotal.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    // Implement checkout logic
                                                  },
                                                  child: Text('Checkout'),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.deepOrange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Cart Total: \$${_calculateTotalPrice().toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}
