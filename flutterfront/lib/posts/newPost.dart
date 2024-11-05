import 'package:flutter/material.dart';
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar.dart';
import 'package:http/http.dart' as http;
import 'package:sample/main.dart';
import 'package:sample/shared/config_utils.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NewPostPage extends StatefulWidget {
  @override
  _NewPostPageState createState() => _NewPostPageState();
}

class _NewPostPageState extends State<NewPostPage> {
  final List<String> sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
  final List<String> categories = [
    'Clothing',
    'Electronics',
    'Furniture',
    'Accessories'
  ];
  final List<String> clothingTypes = [
    'Shirt',
    'Pants',
    'Dress',
    'Jacket',
    'Shoes'
  ];
  final List<String> colors = ['Red', 'Blue', 'Green', 'Black', 'White'];
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
  String? selectedColor;
  List<String> photos = [];
  bool _isLoading = false;
  String? baseUrl;

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    baseUrl = await ConfigUtils.getBaseUrl();
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

  Future<void> _addPost() async {
    if (!_validateInputs()) return;

    if (baseUrl == null) {
      _showErrorDialog('Configuration error. Please try again later.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      final accessToken = prefs.getString('accessToken');
      final idToken = prefs.getString('idToken');

      print('User string: $userStr');
      print('Access token available: ${accessToken != null}');
      print('ID token available: ${idToken != null}');

      if (userStr == null || idToken == null) {
        _showErrorDialog('Please log in to create a post');
        return;
      }

      final userData = json.decode(userStr);
      final userId = userData['id'];

      print('User ID: $userId');

      final requestBody = {
        'price': double.parse(priceController.text),
        'description': descriptionController.text.trim(),
        'size': selectedSize,
        'category': selectedCategory,
        'clothingType': selectedClothingType,
        'tags': selectedTags,
        'photos': photos,
      };

      print('Request body: ${json.encode(requestBody)}');
      final url = '$baseUrl/posts/create/$userId';
      print('Endpoint URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Success"),
              content: Text("Post created successfully!"),
              actions: [
                TextButton(
                  child: Text("OK"),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyHomePage(title: "GearSwap"),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      } else {
        String errorMessage;
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData is String
              ? errorData
              : (errorData['error'] ??
                  errorData['message'] ??
                  errorData['body'] ??
                  'Failed to create post');
        } catch (e) {
          print('Error parsing response body: $e');
          errorMessage = response.body;
        }
        print('Error message: $errorMessage');
        _showErrorDialog('Error: $errorMessage');
      }
    } catch (e, stackTrace) {
      print('Exception details: $e');
      print('Stack trace: $stackTrace');
      _showErrorDialog('Error creating post: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    if (photos.isEmpty) {
      _showErrorDialog('Please add at least one photo');
      return false;
    }

    return true;
  }

  Future<void> _uploadPhotos() async {
    setState(() {
      if (photos.length < 5) {
        photos.add('https://example.com/photo${photos.length + 1}.jpg');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavBar(),
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
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Tap to add photos (max 5)"),
                        if (photos.isNotEmpty) ...[
                          SizedBox(height: 8),
                          Text(
                            "${photos.length} photo(s) selected",
                            style: TextStyle(color: Colors.deepOrange),
                          ),
                        ],
                        ElevatedButton(
                          onPressed: _uploadPhotos,
                          child: Text("Add Test Photo"),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.0),

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
                    items: sizes
                        .map((size) => DropdownMenuItem(
                              value: size,
                              child: Text(size),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => selectedSize = value),
                  ),
                  SizedBox(height: 16.0),

                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: "Category",
                      border: OutlineInputBorder(),
                    ),
                    items: categories
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedCategory = value),
                  ),
                  SizedBox(height: 16.0),

                  DropdownButtonFormField<String>(
                    value: selectedClothingType,
                    decoration: InputDecoration(
                      labelText: "Clothing Type",
                      border: OutlineInputBorder(),
                    ),
                    items: clothingTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedClothingType = value),
                  ),
                  SizedBox(height: 16.0),

                  Text("Tags (select up to 5):",
                      style: TextStyle(fontSize: 16)),
                  Wrap(
                    spacing: 8.0,
                    children: tags
                        .map((tag) => ChoiceChip(
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
                            ))
                        .toList(),
                  ),
                  SizedBox(height: 24.0),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _addPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator()
                        : Text(
                            'Add Post',
                            style: TextStyle(fontSize: 18),
                          ),
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
