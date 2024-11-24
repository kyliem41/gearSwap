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
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'dart:math' as math;

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
      final idToken = prefs.getString('idToken');

      if (userStr == null || idToken == null) {
        _showErrorDialog('Please log in to create a post');
        return;
      }

      final userData = json.decode(userStr);
      final userId = userData['id'];

      // First, upload all images and get their IDs
      List<String> uploadedImageIds = [];
      for (var photo in photos) {
        try {
          print('Attempting to upload image...'); // Debug print
          final imageId = await _uploadSingleImage(userId, photo, idToken);
          print('Image upload response: $imageId'); // Debug print

          if (imageId != null) {
            uploadedImageIds.add(imageId);
          }
        } catch (e) {
          print('Error uploading single image: $e');
          // Show error but continue with other images
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to upload one image: ${e.toString()}')),
          );
        }
      }

      if (uploadedImageIds.isEmpty) {
        throw Exception('Failed to upload any images');
      }

      // Now create the post with image references
      final requestBody = {
        'price': double.parse(priceController.text),
        'description': descriptionController.text.trim(),
        'size': selectedSize,
        'category': selectedCategory,
        'clothingType': selectedClothingType,
        'tags': selectedTags,
        'photoIds': uploadedImageIds,
      };

      print(
          'Sending post request with body: ${json.encode(requestBody)}'); // Debug print

      final url = '$baseUrl/posts/create/$userId';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
          'Accept': '*/*',
          'Access-Control-Allow-Origin': '*',
        },
        body: json.encode(requestBody),
      );

      print(
          'Post creation response status: ${response.statusCode}'); // Debug print
      print('Post creation response body: ${response.body}'); // Debug print

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
        _handleErrorResponse(response);
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

  Future<String?> _uploadSingleImage(
      String userId, Map<String, dynamic> photo, String idToken) async {
    try {
      final uploadUrl = '$baseUrl/images/upload/$userId';
      final response = await http.post(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
          'Accept': '*/*', // Add this
          'Access-Control-Allow-Origin': '*', // Add this
        },
        body: json.encode({
          'data': photo['data'],
          'content_type': photo['content_type'],
        }),
      );

      // Add debug prints
      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['imageId']?.toString(); // Ensure we return a string
      } else {
        print('Failed to upload image: ${response.body}');
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Error uploading image: $e');
    }
  }

  void _handleErrorResponse(http.Response response) {
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

  Widget _buildImageUploadSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
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
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickImageAlternative,
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
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    );
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
        ..multiple = true;
      input.click();

      await input.onChange.first;
      if (input.files == null || input.files!.isEmpty) {
        setState(() => _isProcessingImage = false);
        return;
      }

      // Process all selected images
      final processedImages =
          await ImageUploadHandler.handleMultipleImages(input.files!);

      setState(() {
        for (var image in processedImages) {
          if (photos.length < 5) {
            photos.add(image);
          }
        }
      });

      setState(() => _isProcessingImage = false);
      print('Images added successfully');
    } catch (e) {
      print('Error picking images: $e');
      _showErrorDialog('Failed to load images');
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

class ImageUploadHandler {
  static const int MAX_IMAGE_SIZE = 2 * 1024 * 1024;
  static const int MAX_DIMENSION = 1600;

  static Future<List<Map<String, dynamic>>> handleMultipleImages(
      List<html.File> files) async {
    List<Map<String, dynamic>> processedImages = [];
    List<String> errors = [];

    for (var file in files) {
      if (processedImages.length >= 5) break; // Keep maximum of 5 images

      if (!file.type!.startsWith('image/')) {
        errors.add('${file.name}: Only image files are allowed');
        continue;
      }

      try {
        // Check original file size
        if (file.size > 10 * 1024 * 1024) {
          // 10MB limit for original files
          errors.add('${file.name}: File too large (max 10MB)');
          continue;
        }

        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;

        final Uint8List originalData = reader.result as Uint8List;
        final compressedData =
            await compressImage(originalData, MAX_IMAGE_SIZE);

        // Convert to base64
        final base64Image = base64Encode(compressedData);

        // Verify final size
        final finalSize =
            base64Image.length * 3 ~/ 4; // Approximate decoded size
        if (finalSize > MAX_IMAGE_SIZE) {
          errors.add('${file.name}: Failed to compress to target size');
          continue;
        }

        processedImages.add({
          'data': base64Image,
          'content_type': file.type ?? 'image/jpeg',
        });

        print('Processed ${file.name}: ${finalSize ~/ 1024}KB');
      } catch (e) {
        print('Error processing ${file.name}: $e');
        errors.add('${file.name}: ${e.toString()}');
      }
    }

    // If we have errors but also some successful images, continue with what worked
    if (errors.isNotEmpty && processedImages.isEmpty) {
      throw Exception('Failed to process images:\n${errors.join('\n')}');
    }

    return processedImages;
  }

  static Future<Uint8List> compressImage(
      Uint8List inputData, int targetSize) async {
    final img.Image? originalImage = img.decodeImage(inputData);
    if (originalImage == null) throw Exception('Failed to decode image');

    // Calculate initial scale factor
    double scale = 1.0;
    if (originalImage.width > MAX_DIMENSION ||
        originalImage.height > MAX_DIMENSION) {
      scale =
          MAX_DIMENSION / math.max(originalImage.width, originalImage.height);
    }

    // Initial resize
    var newWidth = (originalImage.width * scale).round();
    var newHeight = (originalImage.height * scale).round();
    var resizedImage = img.copyResize(originalImage,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear);

    // Progressive compression
    int quality = 92; // Start with higher quality
    Uint8List compressedData;
    int attempts = 0;

    do {
      compressedData =
          Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));

      // If size is still too large, try more aggressive compression
      if (compressedData.length > targetSize && attempts < 3) {
        quality = (quality * 0.7).round(); // More aggressive quality reduction
        attempts++;
      }
      // If still too large after several attempts, reduce dimensions
      else if (compressedData.length > targetSize) {
        scale *= 0.7;
        newWidth = (newWidth * 0.7).round();
        newHeight = (newHeight * 0.7).round();
        resizedImage = img.copyResize(originalImage,
            width: newWidth,
            height: newHeight,
            interpolation: img.Interpolation.linear);
        quality = 92; // Reset quality for the new size
        attempts = 0;
      }
    } while (compressedData.length > targetSize &&
        (newWidth > 300 || newHeight > 300));

    print(
        'Final image size: ${compressedData.length ~/ 1024}KB, Quality: $quality%, Dimensions: ${newWidth}x${newHeight}');

    return compressedData;
  }
}
