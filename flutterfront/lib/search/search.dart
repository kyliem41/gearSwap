import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar.dart';
import 'package:sample/posts/postDetails.dart';
import 'package:sample/shared/config_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

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
  String? baseUrl;
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
    _initialize();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _loadRecentSearches();
        _showOverlay();
      }
    });
  }

  Future<void> _initialize() async {
    baseUrl = await ConfigUtils.getBaseUrl();
    _loadUserData();
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
    if (_idToken == null || _userId == null || baseUrl == null) return;

    try {
      final url = Uri.parse('$baseUrl/search/$_userId');

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
    if (baseUrl == null) return;

    try {
      final url = Uri.parse('$baseUrl/search/$_userId/$searchId');

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

    if (_idToken == null || _userId == null || baseUrl == null) {
      print('No authentication token, user ID, or configuration found');
      return;
    }

    setState(() {
      isLoading = true;
      searchResults = [];
    });

    try {
      var searchUrl = Uri.parse('$baseUrl/search/$_userId');

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

  Future<Uint8List> _loadImageData(String postId) async {
    if (baseUrl == null) {
      throw Exception('Base URL not initialized');
    }

    if (_idToken == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/posts/$postId/images'),
      headers: {
        'Authorization': 'Bearer $_idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['images'] != null &&
          data['images'] is List &&
          data['images'].isNotEmpty &&
          data['images'][0]['data'] != null) {
        return base64Decode(data['images'][0]['data']);
      }
    }
    throw Exception('Failed to load image: ${response.statusCode}');
  }

  Widget _buildPostImage(Map<String, dynamic> post) {
    try {
      print('Post ID: ${post['id']}');
      print('Images data: ${post['images']}');

      if (post['images'] != null &&
          post['images'] is List &&
          post['images'].isNotEmpty &&
          post['images'][0] != null &&
          post['images'][0]['data'] != null) {
        String base64String = post['images'][0]['data'];
        base64String = base64String.trim();
        base64String = base64String.replaceAll(RegExp(r'\s+'), '');

        while (base64String.length % 4 != 0) {
          base64String += '=';
        }

        try {
          final Uint8List imageBytes = base64Decode(base64String);
          return Container(
            width: double.infinity,
            height: double.infinity,
            child: Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error displaying image: $error');
                return _buildPlaceholder();
              },
            ),
          );
        } catch (e) {
          print('Error decoding base64 for post ${post['id']}: $e');
          return _buildPlaceholder();
        }
      } else {
        print('No image data available for post ${post['id']}');
        return FutureBuilder<Uint8List>(
          future: _loadImageData(post['id'].toString()),
          builder: (context, AsyncSnapshot<Uint8List> snapshot) {
            if (snapshot.hasData) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                child: Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error displaying loaded image: $error');
                    return _buildPlaceholder();
                  },
                ),
              );
            }
            return _buildPlaceholder();
          },
        );
      }
    } catch (e) {
      print('Error in _buildPostImage for post ${post['id']}: $e');
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[200],
      child: Icon(
        Icons.image,
        size: 40,
        color: Colors.grey[400],
      ),
    );
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
                                            Expanded(
                                              child: _buildPostImage(post),
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
