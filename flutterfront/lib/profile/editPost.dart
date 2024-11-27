import 'package:flutter/material.dart';
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar.dart';
import 'package:sample/shared/config_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html;

class EditPostPage extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postDetails;

  EditPostPage({required this.postId, required this.postDetails});

  @override
  _EditPostPageState createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final List<Map<String, String>> sizes = [
    {'value': 'XXXS', 'label': 'XXXS'},
    {'value': 'XXS', 'label': 'XXS'},
    {'value': 'XS', 'label': 'XS'},
    {'value': 'S', 'label': 'S'},
    {'value': 'M', 'label': 'M'},
    {'value': 'L', 'label': 'L'},
    {'value': 'XL', 'label': 'XL'},
    {'value': 'XXL', 'label': 'XXL'},
    {'value': 'XXXL', 'label': 'XXXL'},
  ];

  final List<Map<String, String>> categories = [
    {'value': 'Tops', 'label': 'Tops'},
    {'value': 'Bottoms', 'label': 'Bottoms'},
    {'value': 'Dresses', 'label': 'Dresses'},
    {'value': 'Outerwear', 'label': 'Outerwear'},
    {'value': 'Shoes', 'label': 'Shoes'},
    {'value': 'Sleepwear', 'label': 'Sleepwear'},
    {'value': 'Swimwear', 'label': 'Swimwear'},
    {'value': 'Accessories', 'label': 'Accessories'},
    {'value': 'Costume', 'label': 'Costume'},
  ];

  final List<Map<String, String>> condition = [
    {'value': 'Brand New', 'label': 'Brand New'},
    {'value': 'Like New', 'label': 'Like New'},
    {'value': 'Gently Used', 'label': 'Gently Used'},
    {'value': 'Well Used', 'label': 'Well Used'},
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
  List<Map<String, dynamic>> existingImages = [];
  List<Map<String, dynamic>> newImages = [];
  bool _isLoading = false;
  bool _isProcessingImage = false;
  String? userId;
  String? baseUrl;
  bool isSold = false;

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    baseUrl = await ConfigUtils.getBaseUrl();
    await _loadUserId();
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
      selectedCondition = widget.postDetails['condition']?.toString();

      // Initialize tags
      selectedTags = [];
      if (widget.postDetails['tags'] != null) {
        if (widget.postDetails['tags'] is List) {
          selectedTags = List<String>.from(widget.postDetails['tags']);
        }
      }

      // Initialize existing images
      if (widget.postDetails['images'] != null) {
        existingImages =
            List<Map<String, dynamic>>.from(widget.postDetails['images']);
      }
    });
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

  Future<void> _pickImages() async {
    if (existingImages.length + newImages.length >= 5) {
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
        if (existingImages.length + newImages.length >= 5) break;

        if (!file.type!.startsWith('image/')) {
          _showErrorDialog('Only image files are allowed');
          continue;
        }

        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        await reader.onLoad.first;

        String base64String = reader.result as String;
        String contentType = file.type ?? 'image/jpeg';

        final regExp = RegExp(r'data:image/[^;]+;base64,');
        base64String = base64String.replaceFirst(regExp, '');
        base64String = base64String.trim().replaceAll(RegExp(r'\s+'), '');
        base64String = base64String.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');

        while (base64String.length % 4 != 0) {
          base64String += '=';
        }

        setState(() {
          newImages.add({
            'data': base64String,
            'content_type': contentType,
            'action': 'add'
          });
        });
      }
    } catch (e) {
      print('Error picking images: $e');
      _showErrorDialog('Failed to load images: ${e.toString()}');
    } finally {
      setState(() => _isProcessingImage = false);
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      Map<String, dynamic> image = existingImages[index];
      image['action'] = 'delete';
      existingImages.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      newImages.removeAt(index);
    });
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

      // Prepare all images (existing and new) with their actions
      List<Map<String, dynamic>> allImages = [
        ...existingImages.where((img) => img['action'] == 'delete').toList(),
        ...newImages
            .map((img) => {
                  ...img,
                  'action': 'add',
                })
            .toList(),
      ];

      final requestBody = {
        'price': double.parse(priceController.text),
        'description': descriptionController.text.trim(),
        'size': selectedSize,
        'category': selectedCategory,
        'condition': selectedCondition,
        'tags': selectedTags,
        'images': allImages,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/posts/update/$userId/${widget.postId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        if (!context.mounted) return;
        Navigator.of(context)
            .pop(true); // Return true to indicate successful update
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
    if (selectedCondition == null) {
      _showErrorDialog('Please select a condition');
      return false;
    }
    if (existingImages.isEmpty && newImages.isEmpty) {
      _showErrorDialog('Please add at least one photo');
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

  Widget _buildImagePreview(
      Map<String, dynamic> image, int index, bool isExisting) {
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
            child: isExisting
                ? Image.memory(
                    base64Decode(image['data'].split(',').last),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error displaying image: $error');
                      return Icon(Icons.image_not_supported,
                          color: Colors.grey[400]);
                    },
                  )
                : Image.memory(
                    base64Decode(image['data']),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error displaying image: $error');
                      return Icon(Icons.image_not_supported,
                          color: Colors.grey[400]);
                    },
                  ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              if (isExisting) {
                _removeExistingImage(index);
              } else {
                _removeNewImage(index);
              }
            },
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
          if (widget.postDetails['isSold'] == true)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'SOLD',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image management section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Photos (${existingImages.length + newImages.length}/5)",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        if (_isProcessingImage)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        if (existingImages.isNotEmpty || newImages.isNotEmpty)
                          Container(
                            height: 120,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                ...existingImages.asMap().entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: _buildImagePreview(
                                        entry.value, entry.key, true),
                                  );
                                }),
                                ...newImages.asMap().entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: _buildImagePreview(
                                        entry.value, entry.key, false),
                                  );
                                }),
                              ],
                            ),
                          ),
                        SizedBox(height: 16),
                        if (existingImages.length + newImages.length < 5)
                          Container(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _pickImages,
                              icon: Icon(Icons.photo_library,
                                  color: Colors.white),
                              label: Text("Add Photos",
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
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
                    value: selectedCondition,
                    decoration: InputDecoration(
                      labelText: "Condition",
                      border: OutlineInputBorder(),
                    ),
                    items: condition.map((type) {
                      return DropdownMenuItem(
                        value: type['value'],
                        child: Text(type['label']!),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedCondition = value;
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
