import 'package:flutter/material.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar.dart';
import 'package:http/http.dart' as http;
import 'package:sample/main.dart';
import 'package:sample/shared/config_utils.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html;
import 'dart:typed_data';

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
  List<Map<String, dynamic>> photos = [];
  bool _isLoading = false;
  String? baseUrl;
  final ImagePickerWeb _picker = ImagePickerWeb();
  bool _isProcessingImage = false;

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

  Future<void> _pickImage() async {
    if (photos.length >= 5) {
      _showErrorDialog('Maximum 5 photos allowed');
      return;
    }

    try {
      // Use Image Picker Web to get image bytes
      final imageData = await ImagePickerWeb.getImageAsBytes();

      if (imageData != null) {
        // Convert to base64
        final base64Image = base64Encode(imageData);

        // Default to JPEG since we can't reliably get MIME type from bytes
        String contentType = 'image/jpeg';

        setState(() {
          photos.add({
            'data': base64Image,
            'content_type': contentType,
          });
        });

        print('Image added successfully');
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorDialog('Failed to load image');
    }
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
          // 'Accept': 'application/json',
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

  Widget _buildImageUploadSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Listener(
        onPointerDown: (event) {
          // Prevent default browser behavior
          html.window.document.onDragOver
              .listen((event) => event.preventDefault());
          html.window.document.onDrop.listen((event) {
            event.preventDefault();
            final files = event.dataTransfer?.files;
            if (files != null && files.isNotEmpty) {
              _processDroppedFile(files.first);
            }
          });
        },
        child: Column(
          children: [
            Text(
              "Photos (${photos.length}/5)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  separatorBuilder: (context, index) => SizedBox(width: 8),
                  itemBuilder: (context, index) => _buildPhotoPreview(index),
                ),
              ),
            SizedBox(height: 16),
            if (photos.length < 5)
              GestureDetector(
                onTap: _pickImageAlternative,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.grey[400]!,
                      style: BorderStyle.solid, // Set border style
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: Colors.deepOrange,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Click to upload photos",
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Drag and drop or click to upload\nJPEG or PNG, max 5MB",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
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
    );
  }

  Future<void> _processDroppedFile(html.File file) async {
    if (photos.length >= 5) {
      _showErrorDialog('Maximum 5 photos allowed');
      return;
    }

    if (file.size > 5 * 1024 * 1024) {
      _showErrorDialog('File size must be less than 5MB');
      return;
    }

    if (!file.type!.startsWith('image/')) {
      _showErrorDialog('Only image files are allowed');
      return;
    }

    try {
      setState(() => _isProcessingImage = true);

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      await reader.onLoad.first;
      final bytes = reader.result as List<int>;
      final base64Image = base64Encode(bytes);

      setState(() {
        photos.add({
          'data': base64Image,
          'content_type': file.type ?? 'image/jpeg',
        });
        _isProcessingImage = false;
      });
    } catch (e) {
      print('Error processing dropped file: $e');
      _showErrorDialog('Failed to process image');
      setState(() => _isProcessingImage = false);
    }
  }

  Widget _buildPhotoPreview(int index) {
    try {
      return Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[100],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                base64Decode(photos[index]['data']),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('Error displaying image: $error');
                  return Icon(
                    Icons.image_not_supported,
                    color: Colors.grey[400],
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  photos.removeAt(index);
                });
              },
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      print('Error in photo preview: $e');
      return Container();
    }
  }

  Future<void> _pickImageAlternative() async {
    if (photos.length >= 5) {
      _showErrorDialog('Maximum 5 photos allowed');
      return;
    }

    try {
      setState(() => _isProcessingImage = true);

      final input = html.FileUploadInputElement()
        ..accept = 'image/*'
        ..multiple = false;
      input.click();

      await input.onChange.first;
      if (input.files?.isEmpty ?? true) {
        setState(() => _isProcessingImage = false);
        return;
      }

      final file = input.files!.first;
      if (file.size > 5 * 1024 * 1024) {
        _showErrorDialog('File size must be less than 5MB');
        setState(() => _isProcessingImage = false);
        return;
      }

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      await reader.onLoad.first;
      final bytes = reader.result as List<int>;
      final base64Image = base64Encode(bytes);

      setState(() {
        photos.add({
          'data': base64Image,
          'content_type': file.type ?? 'image/jpeg',
        });
        _isProcessingImage = false;
      });

      print('Image added successfully');
    } catch (e) {
      print('Error picking image: $e');
      _showErrorDialog('Failed to load image');
      setState(() => _isProcessingImage = false);
    }
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
                _buildImageUploadSection(),
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
                  onPressed: _isLoading ? null : _addPost,
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
