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
import 'dart:math';

class NewPostPage extends StatefulWidget {
  @override
  _NewPostPageState createState() => _NewPostPageState();
}

class _NewPostPageState extends State<NewPostPage> {
  final List<String> sizes = ['XXXS', 'XXS', 'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];

  final List<String> categories = [
    'Tops',
    'Bottoms',
    'Dresses',
    'Outerwear',
    'Shoes',
    'Sleepwear',
    'Swimwear',
    'Accessories',
    'Costume',
  ];

  final List<String> condition = [
    'Brand New',
    'Like New',
    'Gently Used',
    'Well Used'
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
  String? selectedCondition;
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

        if (!file.type!.startsWith('image/')) {
          _showErrorDialog('Only image files are allowed');
          continue;
        }

        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        await reader.onLoad.first;

        String base64String = reader.result as String;
        String contentType = file.type ?? 'image/jpeg';

        // More robust prefix removal
        final regExp = RegExp(r'data:image/[^;]+;base64,');
        base64String = base64String.replaceFirst(regExp, '');

        // Clean the base64 string
        base64String = base64String.trim();
        base64String = base64String.replaceAll(
            RegExp(r'\s+'), ''); // Remove any whitespace
        base64String = base64String.replaceAll(
            RegExp(r'[^A-Za-z0-9+/=]'), ''); // Remove invalid characters

        // Ensure proper padding
        while (base64String.length % 4 != 0) {
          base64String += '=';
        }

        // Debug print to verify the string
        print(
            'Base64 string prefix: ${base64String.substring(0, min(50, base64String.length))}...');

        setState(() {
          photos.add({
            'data': base64String,
            'content_type': contentType,
          });
        });

        print('Added image with content type: $contentType');
      }
    } catch (e) {
      print('Error picking images: $e');
      _showErrorDialog('Failed to load images: ${e.toString()}');
    } finally {
      setState(() => _isProcessingImage = false);
    }
  }

  Future<void> _uploadImages(String postId, String idToken) async {
    for (var photo in photos) {
      try {
        print('Uploading image for post: $postId');

        final imageResponse = await http.post(
          Uri.parse('$baseUrl/posts/$postId/images'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: json.encode(
              {'data': photo['data'], 'content_type': photo['content_type']}),
        );

        print(
            'Image upload response: ${imageResponse.statusCode} - ${imageResponse.body}');

        if (imageResponse.statusCode != 201 &&
            imageResponse.statusCode != 200) {
          throw Exception('Failed to upload image: ${imageResponse.body}');
        }
      } catch (e) {
        print('Error uploading image: $e');
        throw e;
      }
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

      // Create post first
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
          'condition': selectedCondition,
          'tags': selectedTags,
          'photos': [] // Initialize with empty JSONB array
        }),
      );

      print(
          'Post creation response: ${createPostResponse.statusCode} - ${createPostResponse.body}');

      if (createPostResponse.statusCode != 201 &&
          createPostResponse.statusCode != 200) {
        throw Exception('Failed to create post: ${createPostResponse.body}');
      }

      final postData = json.decode(createPostResponse.body);
      final postId = postData['post']['id'];

      // Upload images
      await _uploadImages(postId, idToken);

      // Show success and navigate
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MyHomePage(title: "GearSwap"),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Post created successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error creating post: $e');
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
    if (selectedCondition == null) {
      _showErrorDialog('Please select a condition');
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
                  value: selectedCondition,
                  decoration: InputDecoration(
                    labelText: "Condition",
                    border: OutlineInputBorder(),
                  ),
                  items: condition
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedCondition = value),
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
