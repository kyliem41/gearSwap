import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String searchQuery = "";
  List<String> tags = [
    'Jackets',
    'Pink',
    'Skirts',
    'H&M',
    'Shoes',
    'Zara',
    'Denim'
  ];
  List<dynamic> searchResults = []; // For storing related posts after search
  bool isLoading = false;

  // Example posts data for grid layout
  List<Map<String, String>> posts = [
    {'image': 'assets/images/jacket1.jpg', 'description': 'Leather Jacket'},
    {'image': 'assets/images/skirt1.jpg', 'description': 'Floral Skirt'},
    {'image': 'assets/images/shoes1.jpg', 'description': 'Sneakers'},
    {'image': 'assets/images/hm1.jpg', 'description': 'H&M Dress'},
  ];

  void onTagTap(String tag) {
    setState(() {
      searchQuery = tag;
      _performSearch(tag); // Perform search using tag as query
    });
  }

  void _performSearch(String query) {
    setState(() {
      isLoading = true;
      searchResults =
          posts; // In a real scenario, you'd filter posts based on query
      isLoading = false;
    });
  }

  String? selectedTag; // Variable to track the selected tag
  List<Color> tagColors = [
    Colors.red,
    Colors.pink,
    Colors.orange,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.yellow,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Search", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepOrange,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                searchQuery = value;
              },
              decoration: InputDecoration(
                hintText: 'Search for items...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                filled: true,
                fillColor: Colors.deepOrange[100],
              ),
              textAlign: TextAlign.center,
              onSubmitted: (value) {
                _performSearch(value); // Perform search when submitted
              },
            ),
          ),
          // Tags Section with unique colors
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 10.0,
              children: tags.asMap().entries.map((entry) {
                int index = entry.key;
                String tag = entry.value;

                // Cycle through colors based on index
                Color tagColor = tagColors[index % tagColors.length];

                return ActionChip(
                  label: Text(tag),
                  backgroundColor: tagColor, // Set unique color
                  onPressed: () {
                    setState(() {
                      selectedTag = tag; // Set the selected tag
                      onTagTap(tag); // Handle tag tap
                    });
                  },
                  labelStyle: TextStyle(
                    color: selectedTag == tag ? Colors.black : Colors.white, // Change text color when selected
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 16.0),
          // Search results section (unchanged)
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Two posts per row
                        mainAxisSpacing: 10.0,
                        crossAxisSpacing: 10.0,
                        childAspectRatio: 3 / 4, // Adjust the ratio based on item size
                      ),
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            // Handle post click
                          },
                          child: Card(
                            elevation: 3.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image of the post
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(10.0)),
                                      image: DecorationImage(
                                        image: AssetImage(searchResults[index]['image']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    searchResults[index]['description'],
                                    style: TextStyle(fontSize: 16.0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
