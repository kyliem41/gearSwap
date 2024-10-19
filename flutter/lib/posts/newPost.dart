import 'package:flutter/material.dart';
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar.dart';

class NewPostPage extends StatefulWidget {
  @override
  _NewPostPageState createState() => _NewPostPageState();
}

class _NewPostPageState extends State<NewPostPage> {
  final List<String> sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
  final List<String> categories = ['Clothing', 'Electronics', 'Furniture', 'Accessories'];
  final List<String> brands = ['Nike', 'Adidas', 'H&M', 'Zara', 'Puma'];
  final List<String> colors = ['Red', 'Blue', 'Green', 'Black', 'White'];
  final List<String> tags = ['Jackets', 'Shoes', 'Skirts', 'Dresses', 'Casual', 'Formal'];
  
  List<String> selectedTags = [];
  String? selectedSize;
  String? selectedCategory;
  String? selectedBrand;
  String? selectedColor;
  
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  
  void _saveDraft() {
    // Save draft logic here
    print("Draft saved");
  }

  void _addPost() {
    // Add post logic here
    print("Post added");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Photo Upload Section
              GestureDetector(
                onTap: () {
                  // Logic to upload photos
                },
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text("Tap to add photos (max 5)")),
                ),
              ),
              SizedBox(height: 16.0),
              
              // Description Field
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16.0),

              // Size Dropdown
              DropdownButtonFormField<String>(
                value: selectedSize,
                onChanged: (value) {
                  setState(() {
                    selectedSize = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: "Size",
                  border: OutlineInputBorder(),
                ),
                items: sizes.map((String size) {
                  return DropdownMenuItem<String>(
                    value: size,
                    child: Text(size),
                  );
                }).toList(),
              ),
              SizedBox(height: 16.0),

              // Price Field
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: "Price",
                  border: OutlineInputBorder(),
                  prefixText: "\$",
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.0),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: selectedCategory,
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                ),
                items: categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
              ),
              SizedBox(height: 16.0),

              // Brand Dropdown
              DropdownButtonFormField<String>(
                value: selectedBrand,
                onChanged: (value) {
                  setState(() {
                    selectedBrand = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: "Brand",
                  border: OutlineInputBorder(),
                ),
                items: brands.map((String brand) {
                  return DropdownMenuItem<String>(
                    value: brand,
                    child: Text(brand),
                  );
                }).toList(),
              ),
              SizedBox(height: 16.0),

              // Color Dropdown
              DropdownButtonFormField<String>(
                value: selectedColor,
                onChanged: (value) {
                  setState(() {
                    selectedColor = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: "Color",
                  border: OutlineInputBorder(),
                ),
                items: colors.map((String color) {
                  return DropdownMenuItem<String>(
                    value: color,
                    child: Text(color),
                  );
                }).toList(),
              ),
              SizedBox(height: 16.0),

              // Tags Selection
              Wrap(
                spacing: 8.0,
                children: tags.map((String tag) {
                  return ChoiceChip(
                    label: Text(tag),
                    selected: selectedTags.contains(tag),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          if (selectedTags.length < 6) {
                            selectedTags.add(tag);
                          }
                        } else {
                          selectedTags.remove(tag);
                        }
                      });
                    },
                    selectedColor: Colors.deepOrange,
                  );
                }).toList(),
              ),
              SizedBox(height: 16.0),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _saveDraft,
                    child: Text("Save as Draft"),
                  ),
                  ElevatedButton(
                    onPressed: _addPost,
                    child: Text("Add Post"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}
