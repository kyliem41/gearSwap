import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
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
  List<dynamic> searchResults = [];
  bool isLoading = false;
  String? selectedTag;
  String? _idToken;
  String? _userId;

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
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      final idToken = prefs.getString('idToken');

      if (userStr != null && idToken != null) {
        final userData = json.decode(userStr);
        setState(() {
          _userId = userData['id'].toString();
          _idToken = idToken;
        });
        // Initially load all posts
        _performSearch('');
      } else {
        print('No user data or token found');
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    if (_idToken == null || _userId == null) {
      print('No authentication token or user ID found');
      return;
    }

    setState(() {
      isLoading = true;
      searchResults = [];
    });

    try {
      var searchUrl = Uri.parse(
          'https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/search/$_userId');

      var response = await http.post(
        searchUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_idToken',
        },
        body: json.encode({'searchQuery': query}),
      );

      if (response.statusCode == 201) {
        var data = json.decode(response.body);
        print('Search response: ${response.body}');
        setState(() {
          searchResults = data['posts'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to perform search: ${response.body}');
      }
    } catch (e) {
      print('Error performing search: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void onTagTap(String tag) {
    setState(() {
      selectedTag = tag;
      searchQuery = tag;
      _searchController.clear();
      _performSearch(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavBar(),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
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
                setState(() {
                  selectedTag = null;
                });
                _performSearch(value);
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 10.0,
              children: tags.asMap().entries.map((entry) {
                int index = entry.key;
                String tag = entry.value;
                Color tagColor = tagColors[index % tagColors.length];

                return ActionChip(
                  label: Text(tag),
                  backgroundColor: tagColor,
                  onPressed: () => onTagTap(tag),
                  labelStyle: TextStyle(
                    color: selectedTag == tag ? Colors.black : Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 16.0),
          if (_idToken == null || _userId == null)
            Center(
              child: Text('Please log in to search'),
            )
          else if (isLoading)
            Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: searchResults.isEmpty
                    ? Center(
                        child: Text('No results found'),
                      )
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 10.0,
                          crossAxisSpacing: 10.0,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final post = searchResults[index];
                          return GestureDetector(
                            onTap: () {
                              // Handle post tap
                              print('Post tapped: ${post['id']}');
                            },
                            child: Card(
                              elevation: 4.0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(10.0),
                                        ),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (post['photos'] != null &&
                                                post['photos'].isNotEmpty)
                                              Image.network(
                                                post['photos'][0],
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Icon(
                                                  Icons.image,
                                                  size: 40,
                                                  color: Colors.grey[400],
                                                ),
                                              )
                                            else
                                              Icon(
                                                Icons.image,
                                                size: 40,
                                                color: Colors.grey[400],
                                              ),
                                            SizedBox(height: 8),
                                            Text(
                                              '\$${post['price']}',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          post['description'] ??
                                              'No description',
                                          style: TextStyle(fontSize: 14),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (post['size'] != null)
                                          Text(
                                            'Size: ${post['size']}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
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
      bottomNavigationBar: BottomNavBar(),
    );
  }
}
