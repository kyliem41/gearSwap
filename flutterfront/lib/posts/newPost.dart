import 'package:flutter/material.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar.dart';
import 'package:sample/main.dart';
import 'package:sample/shared/config_utils.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:async';

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
  List<Map<String, dynamic>> photos = [];
  bool _isLoading = false;
  bool _isProcessingImage = false;
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

  Future<void> _pickImages() async {
    if (photos.length >= 5) {
      _showErrorDialog('Maximum 5 photos allowed');
      return;
    }

    try {
      setState(() => _isProcessingImage = true);

      final input = html.FileUploadInputElement()
        ..accept = 'image/*'
        ..multiple = true;
      input.click();

      await input.onChange.first;
      if (input.files == null || input.files!.isEmpty) return;

      for (var file in input.files!) {
        if (photos.length >= 5) break;

        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        await reader.onLoad.first;

        String base64String = reader.result as String;
        // Remove the data URL prefix
        base64String = base64String.split(',')[1];

        setState(() {
          photos.add({
            'data': base64String,
            'content_type': file.type ?? 'image/jpeg',
          });
        });
      }
    } catch (e) {
      print('Error picking images: $e');
      _showErrorDialog('Failed to load images');
    } finally {
      setState(() => _isProcessingImage = false);
    }
  }

  Future<void> _createPost() async {
    if (!_validateInputs()) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      final idToken = prefs.getString('idToken');

      if (userStr == null || idToken == null) {
        _showErrorDialog('Please log in to create a post');
        return;
      }

      final userData = json.decode(userStr);
      final userId = userData['id'];

      // First create the post without images
      final createPostResponse = await http.post(
        Uri.parse('$baseUrl/posts/create/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({
          'price': double.parse(priceController.text),
          'description': descriptionController.text.trim(),
          'size': selectedSize,
          'category': selectedCategory,
          'clothingType': selectedClothingType,
          'tags': selectedTags,
        }),
      );

      if (createPostResponse.statusCode != 201) {
        throw Exception('Failed to create post: ${createPostResponse.body}');
      }

      final postData = json.decode(createPostResponse.body);
      final postId = postData['post']['id'];

      // Then upload each image separately
      for (var photo in photos) {
        final imageResponse = await http.post(
          Uri.parse('$baseUrl/posts/$postId/images'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: json.encode({
            'data': photo['data'],
            'content_type': photo['content_type'],
          }),
        );

        if (imageResponse.statusCode != 201) {
          print('Failed to upload image: ${imageResponse.body}');
        }
      }

      // Show success dialog and navigate back
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
    } catch (e) {
      print('Error creating post: $e');
      _showErrorDialog('Error creating post: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
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

  Widget _buildPhotoPreview(int index) {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              base64Decode(photos[index]['data']),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error displaying image: $error');
                return Icon(Icons.image_not_supported, color: Colors.grey[400]);
              },
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => setState(() => photos.removeAt(index)),
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
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
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image upload section
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Photos (${photos.length}/5)",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      if (_isProcessingImage)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      if (photos.isNotEmpty)
                        Container(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: photos.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(width: 8),
                            itemBuilder: (context, index) =>
                                _buildPhotoPreview(index),
                          ),
                        ),
                      SizedBox(height: 16),
                      if (photos.length < 5)
                        Container(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _pickImages,
                            icon: Icon(
                              Icons.photo_library,
                              color: Colors.white,
                            ),
                            label: Text(
                              "Choose from Gallery",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        )
                      else
                        Text(
                          "Maximum number of photos reached",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
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
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                Text("Tags (select up to 5):", style: TextStyle(fontSize: 16)),
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
                  onPressed: _isLoading ? null : _createPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Add Post',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}
