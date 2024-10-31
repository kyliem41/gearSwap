import 'package:flutter/material.dart';
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EditPostPage extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postDetails;

  EditPostPage({required this.postId, required this.postDetails});

  @override
  _EditPostPageState createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final List<Map<String, String>> sizes = [
    {'value': 'XS', 'label': 'XS'},
    {'value': 'S', 'label': 'S'},
    {'value': 'M', 'label': 'M'},
    {'value': 'L', 'label': 'L'},
    {'value': 'XL', 'label': 'XL'},
    {'value': 'XXL', 'label': 'XXL'},
    {'value': 'XXXL', 'label': 'XXXL'},
  ];

  final List<Map<String, String>> categories = [
    {'value': 'Clothing', 'label': 'Clothing'},
    {'value': 'Electronics', 'label': 'Electronics'},
    {'value': 'Furniture', 'label': 'Furniture'},
    {'value': 'Accessories', 'label': 'Accessories'},
  ];

  final List<Map<String, String>> clothingTypes = [
    {'value': 'Shirt', 'label': 'Shirt'},
    {'value': 'Pants', 'label': 'Pants'},
    {'value': 'Dress', 'label': 'Dress'},
    {'value': 'Jacket', 'label': 'Jacket'},
    {'value': 'Shoes', 'label': 'Shoes'},
  ];

  final List<String> tags = [
    'Casual',
    'Formal',
    'Vintage',
    'Modern',
    'Sporty',
    'Designer'
  ];

  List<String> selectedTags = [];
  String? selectedSize;
  String? selectedCategory;
  String? selectedClothingType;
  List<String> photos = [];
  bool _isLoading = false;
  String? userId;

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _initializeFormData();
  }

  void _initializeFormData() {
    print('Initializing form with data: ${widget.postDetails}');

    descriptionController.text =
        widget.postDetails['description']?.toString() ?? '';
    priceController.text = widget.postDetails['price']?.toString() ?? '';

    setState(() {
      selectedSize = widget.postDetails['size']?.toString();
      selectedCategory = widget.postDetails['category']?.toString();
      selectedClothingType = widget.postDetails['clothingType']
          ?.toString(); // Match database column case

      // Validate dropdown values against available options
      if (selectedSize != null &&
          !sizes.any((size) => size['value'] == selectedSize)) {
        print('Warning: Invalid size value: $selectedSize');
        selectedSize = null;
      }

      if (selectedCategory != null &&
          !categories.any((cat) => cat['value'] == selectedCategory)) {
        print('Warning: Invalid category value: $selectedCategory');
        selectedCategory = null;
      }

      if (selectedClothingType != null &&
          !clothingTypes.any((type) => type['value'] == selectedClothingType)) {
        print('Warning: Invalid clothingType value: $selectedClothingType');
        selectedClothingType = null;
      }

      // Initialize tags
      selectedTags = [];
      if (widget.postDetails['tags'] != null) {
        if (widget.postDetails['tags'] is List) {
          selectedTags = widget.postDetails['tags']
              .whereType<String>()
              .where((tag) => tags.contains(tag))
              .toList();
        }
      }

      // Initialize photos
      photos = [];
      if (widget.postDetails['photos'] != null) {
        if (widget.postDetails['photos'] is List) {
          photos = List<String>.from(widget.postDetails['photos']);
        }
      }
    });

    print('Form initialized with:');
    print('Size: $selectedSize');
    print('Category: $selectedCategory');
    print('ClothingType: $selectedClothingType');
    print('Tags: $selectedTags');
    print('Photos: ${photos.length} photos');
  }

  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');

      if (userStr != null) {
        final userData = json.decode(userStr);
        userId = userData['id'].toString();
      }
    } catch (e) {
      print('Error loading user ID: $e');
    }
  }

  Future<void> _updatePost() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');

      if (idToken == null || userId == null) {
        _showErrorDialog('Please log in to update the post');
        return;
      }

      // Prepare the request body
      final requestBody = {
        'price': double.parse(priceController.text),
        'description': descriptionController.text.trim(),
        'size': selectedSize,
        'category': selectedCategory,
        'clothingType': selectedClothingType,
        'tags': selectedTags,
        'photos': photos,
      };

      print('Updating post with data:');
      print(json.encode(requestBody));

      final url = Uri.parse(
        'https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/posts/update/$userId/${widget.postId}',
      );

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode(requestBody),
      );

      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.body}');

      if (response.statusCode == 200) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Success"),
              content: Text("Post updated successfully!"),
              actions: [
                TextButton(
                  child: Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        throw Exception('Failed to update post: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating post: $e');
      _showErrorDialog('Error updating post: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateInputs() {
    if (descriptionController.text.trim().isEmpty) {
      _showErrorDialog('Please enter a description');
      return false;
    }
    if (priceController.text.isEmpty) {
      _showErrorDialog('Please enter a price');
      return false;
    }
    try {
      double.parse(priceController.text);
    } catch (e) {
      _showErrorDialog('Please enter a valid price');
      return false;
    }
    if (selectedSize == null) {
      _showErrorDialog('Please select a size');
      return false;
    }
    if (selectedCategory == null) {
      _showErrorDialog('Please select a category');
      return false;
    }
    if (selectedClothingType == null) {
      _showErrorDialog('Please select a clothing type');
      return false;
    }
    return true;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Post'),
      ),
      body: Stack(
        children: [
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(child: CircularProgressIndicator()),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16.0),
                  TextField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: "Price",
                      border: OutlineInputBorder(),
                      prefixText: "\$",
                    ),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                  ),
                  SizedBox(height: 16.0),
                  DropdownButtonFormField<String>(
                    value: selectedSize,
                    decoration: InputDecoration(
                      labelText: "Size",
                      border: OutlineInputBorder(),
                    ),
                    items: sizes.map((size) {
                      return DropdownMenuItem(
                        value: size['value'],
                        child: Text(size['label']!),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedSize = value;
                      });
                    },
                  ),
                  SizedBox(height: 16.0),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: "Category",
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category['value'],
                        child: Text(category['label']!),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                  ),
                  SizedBox(height: 16.0),
                  DropdownButtonFormField<String>(
                    value: selectedClothingType,
                    decoration: InputDecoration(
                      labelText: "Clothing Type",
                      border: OutlineInputBorder(),
                    ),
                    items: clothingTypes.map((type) {
                      return DropdownMenuItem(
                        value: type['value'],
                        child: Text(type['label']!),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedClothingType = value;
                      });
                    },
                  ),
                  SizedBox(height: 16.0),
                  Text("Tags (select up to 5):",
                      style: TextStyle(fontSize: 16)),
                  Wrap(
                    spacing: 8.0,
                    children: tags.map((tag) {
                      return ChoiceChip(
                        label: Text(tag),
                        selected: selectedTags.contains(tag),
                        onSelected: (selected) {
                          setState(() {
                            if (selected && selectedTags.length < 5) {
                              selectedTags.add(tag);
                            } else {
                              selectedTags.remove(tag);
                            }
                          });
                        },
                        selectedColor: Colors.deepOrange,
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 24.0),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updatePost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator()
                        : Text('Update Post',
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}
