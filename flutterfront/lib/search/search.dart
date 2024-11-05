import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar.dart';
import 'package:sample/posts/postDetails.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isSearchBarFocused = false;
  String searchQuery = "";
  List<dynamic> searchResults = [];
  List<dynamic> recentSearches = [];
  bool isLoading = false;
  String? selectedTag;
  String? _idToken;
  String? _userId;
  FocusNode _focusNode = FocusNode();

  List<String> tags = [
    'Jackets',
    'Pink',
    'Skirts',
    'H&M',
    'Shoes',
    'Zara',
    'Denim'
  ];

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
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _loadRecentSearches();
        _showOverlay();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _hideOverlay();
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

  void _showOverlay() {
    if (_overlayEntry != null || recentSearches.isEmpty) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _hideOverlay();
        },
        child: Stack(
          children: [
            Positioned(
              width: size.width - 32,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, 60),
                child: GestureDetector(
                  onTap: () {}, // Prevent click from propagating to background
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var search in recentSearches)
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: ListTile(
                                onTap: () {
                                  _searchController.text =
                                      search['searchquery'];
                                  searchQuery = search['searchquery'];
                                  _performSearch(search['searchquery']);
                                  _hideOverlay();
                                },
                                hoverColor: Colors.grey[200],
                                title: Text(
                                  search['searchquery'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.close, size: 20),
                                  onPressed: () async {
                                    await _deleteSearch(
                                        search['id'].toString());
                                  },
                                  splashRadius: 20,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _loadRecentSearches() async {
    if (_idToken == null || _userId == null) return;

    try {
      final url = Uri.parse(
        'https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/search/$_userId',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          recentSearches = data['searches'] ?? [];
        });

        if (_overlayEntry != null) {
          if (recentSearches.isEmpty) {
            _hideOverlay();
          } else {
            _overlayEntry!.markNeedsBuild();
          }
        }
      }
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }

  Future<void> _deleteSearch(String searchId) async {
    try {
      final url = Uri.parse(
        'https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/search/$_userId/$searchId',
      );

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $_idToken',
        },
      );

      if (response.statusCode == 200) {
        // Update the local state
        setState(() {
          recentSearches
              .removeWhere((search) => search['id'].toString() == searchId);
        });

        // If there are no more searches, hide the overlay
        if (recentSearches.isEmpty) {
          _hideOverlay();
        } else {
          // Force overlay to rebuild
          _overlayEntry?.markNeedsBuild();
        }
      }
    } catch (e) {
      print('Error deleting search: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    // Validate query before sending
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      print('Empty search query, skipping search');
      return;
    }

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
        body: json.encode({'searchQuery': trimmedQuery}),
      );

      if (response.statusCode == 201) {
        var data = json.decode(response.body);
        print('Search response: ${response.body}');
        setState(() {
          searchResults = data['posts'] ?? [];
          isLoading = false;
        });
        // Only reload recent searches if the search was successful
        _loadRecentSearches();
      } else if (response.statusCode == 400) {
        print('Invalid search query: ${response.body}');
        setState(() {
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
            child: CompositedTransformTarget(
              link: _layerLink,
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
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
                  if (value.trim().isNotEmpty) {
                    setState(() {
                      selectedTag = null;
                    });
                    _performSearch(value);
                    _focusNode.unfocus();
                  }
                },
              ),
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
                              print('Post tapped: ${post['id']}');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostDetailPage(
                                    postId: post['id'].toString(),
                                  ),
                                ),
                              );
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
