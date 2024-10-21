import 'package:flutter/material.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Example cart data grouped by seller
  Map<String, List<Map<String, dynamic>>> cartData = {
    'seller1': [
      {
        'image': 'assets/item1.jpg',
        'name': 'Item 1',
        'price': 50.0,
        'quantity': 1,
      },
      {
        'image': 'assets/item2.jpg',
        'name': 'Item 2',
        'price': 30.0,
        'quantity': 2,
      },
    ],
    'seller2': [
      {
        'image': 'assets/item3.jpg',
        'name': 'Item 3',
        'price': 100.0,
        'quantity': 1,
      },
    ],
  };

  double _calculateGroupTotal(List<Map<String, dynamic>> group) {
    return group.fold(
      0,
      (sum, item) => sum + (item['price'] * item['quantity']),
    );
  }

  double _calculateTotalPrice() {
    return cartData.values.fold(
      0,
      (sum, group) => sum + _calculateGroupTotal(group),
    );
  }

  void _increaseQuantity(String seller, int index) {
    setState(() {
      cartData[seller]![index]['quantity']++;
    });
  }

  void _decreaseQuantity(String seller, int index) {
    setState(() {
      if (cartData[seller]![index]['quantity'] > 1) {
        cartData[seller]![index]['quantity']--;
      }
    });
  }

  void _removeItem(String seller, int index) {
    setState(() {
      cartData[seller]!.removeAt(index);
      if (cartData[seller]!.isEmpty) {
        cartData.remove(seller);
      }
    });
  }

  // Checkout for a particular group
  void _checkout(String seller) {
    // Handle checkout logic for seller's items here
    print('Checking out for $seller');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: cartData.entries.map((entry) {
                  String seller = entry.key;
                  List<Map<String, dynamic>> items = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Seller's Username
                        Text(
                          'Seller: $seller',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10.0),
                        // List of items in the seller's group
                        Column(
                          children: items.asMap().entries.map((itemEntry) {
                            int index = itemEntry.key;
                            Map<String, dynamic> item = itemEntry.value;

                            return Card(
                              margin: EdgeInsets.only(bottom: 10.0),
                              child: Padding(
                                padding: EdgeInsets.all(10.0),
                                child: Row(
                                  children: [
                                    // Post image
                                    Container(
                                      width: 80.0,
                                      height: 80.0,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage(item['image']),
                                          fit: BoxFit.cover,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                    ),
                                    SizedBox(width: 16.0),
                                    // Post details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['name'],
                                            style: TextStyle(
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 5.0),
                                          Text(
                                            '\$${item['price']}',
                                            style: TextStyle(
                                              fontSize: 16.0,
                                            ),
                                          ),
                                          SizedBox(height: 5.0),
                                          // Quantity controls
                                          Row(
                                            children: [
                                              IconButton(
                                                onPressed: () => _decreaseQuantity(seller, index),
                                                icon: Icon(Icons.remove),
                                              ),
                                              Text('${item['quantity']}'),
                                              IconButton(
                                                onPressed: () => _increaseQuantity(seller, index),
                                                icon: Icon(Icons.add),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _removeItem(seller, index),
                                      icon: Icon(Icons.delete),
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total: \$${_calculateGroupTotal(items)}',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _checkout(seller),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange[400],
                              ),
                              child: Text('Checkout',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                        Divider(thickness: 1.0),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Price: \$${_calculateTotalPrice()}',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
