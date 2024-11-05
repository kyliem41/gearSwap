import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/cartNavBar.dart';
import 'package:sample/posts/postDetails.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool isLoading = true;
  Map<String, Map<String, dynamic>> sellerInfo = {};
  Map<String, List<Map<String, dynamic>>> cartItems = {};
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndCart();
  }

  Future<void> _loadUserIdAndCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');

      if (userString != null) {
        final userJson = jsonDecode(userString);
        setState(() {
          userId = userJson['id'].toString();
        });
        print('Loaded userId from user data: $userId');
        await _loadCartItems();
      } else {
        print('No user data found');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchSellerInfo(String sellerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');

      if (idToken == null) return;

      final url = Uri.parse(
        'https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/userProfile/$sellerId',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['userProfile'] != null) {
          setState(() {
            sellerInfo[sellerId] = data['userProfile'];
          });
        }
      }
    } catch (e) {
      print('Error fetching seller info: $e');
    }
  }

  Future<void> _loadCartItems() async {
    try {
      setState(() => isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');

      if (idToken == null) {
        throw Exception('No authentication token found');
      }

      print('Loading cart items for user: $userId');

      final cartUrl = Uri.parse(
        'https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/cart/$userId',
      );

      final cartResponse = await http.get(
        cartUrl,
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      print('Cart response status: ${cartResponse.statusCode}');
      print('Cart response body: ${cartResponse.body}');

      if (cartResponse.statusCode == 200) {
        final cartData = json.decode(cartResponse.body);
        if (cartData['cart'] != null && cartData['cart'].isNotEmpty) {
          final cartList = cartData['cart'] as List;

          final groupedItems = <String, List<Map<String, dynamic>>>{};
          final fetchedSellerIds = <String>{};

          for (var cartItem in cartList) {
            final postId = cartItem['postid'];

            final postUrl = Uri.parse(
              'https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/posts/$postId',
            );

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
            }
          }

          setState(() {
            cartItems = groupedItems;
            isLoading = false;
          });

          // Fetch seller information for each unique seller
          for (String sellerId in fetchedSellerIds) {
            await _fetchSellerInfo(sellerId);
          }
        } else {
          setState(() {
            cartItems = {};
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load cart items');
      }
    } catch (e) {
      print('Error loading cart: $e');
      setState(() {
        isLoading = false;
        cartItems = {};
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load cart items')),
        );
      }
    }
  }

  Future<void> _removeFromCart(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');

      if (idToken == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse(
        'https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/cart/$userId',
      );

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
      print('Remove from cart response body: ${response.body}');

      if (response.statusCode == 200) {
        await _loadCartItems(); // Reload cart after removal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item removed from cart')),
        );
      } else {
        throw Exception('Failed to remove item from cart');
      }
    } catch (e) {
      print('Error removing item from cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove item from cart')),
      );
    }
  }

  double _calculateGroupTotal(List<Map<String, dynamic>> items) {
    return items.fold(0, (sum, item) => sum + (item['price'] as num));
  }

  double _calculateTotalPrice() {
    return cartItems.values.fold(
      0,
      (sum, items) => sum + _calculateGroupTotal(items),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(
        appBar: CartNavBar(),
        body: Center(
          child: Text('Please log in to view your cart'),
        ),
      );
    }

    if (isLoading) {
      return Scaffold(
        appBar: CartNavBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: CartNavBar(),
      body: cartItems.isEmpty
          ? Center(child: Text('Your cart is empty'))
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: cartItems.entries.map((entry) {
                        String sellerId = entry.key;
                        List<Map<String, dynamic>> items = entry.value;
                        double groupTotal = _calculateGroupTotal(items);
                        final seller = sellerInfo[sellerId];
                        final sellerName = seller != null
                            ? '@${seller['username']}'
                            : 'Seller $sellerId';

                        return Card(
                          margin: EdgeInsets.only(bottom: 16.0),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Seller: $sellerName',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16),
                                ...items.map((item) => GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PostDetailPage(
                                              postId: item['id'].toString(),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 8.0),
                                        child: Row(
                                          children: [
                                            if (item['photos'] != null &&
                                                (item['photos'] as List)
                                                    .isNotEmpty)
                                              Image.network(
                                                item['photos'][0],
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Container(
                                                  width: 80,
                                                  height: 80,
                                                  color: Colors.grey[200],
                                                  child: Icon(Icons.image),
                                                ),
                                              ),
                                            SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['description'] ??
                                                        'No description',
                                                    style:
                                                        TextStyle(fontSize: 16),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    '\$${item['price']}',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () => _removeFromCart(
                                                  item['id'].toString()),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )),
                                Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepOrange,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
