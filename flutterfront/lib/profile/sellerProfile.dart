import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/shared/config_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:sample/profile/profile.dart';
import 'package:sample/profile/profilePostDetails.dart';
import 'dart:typed_data';
import 'dart:math';

class UserData {
  final String id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  String? bio;
  String? location;
  String? profilePicture;
  List<dynamic> posts;
  int likeCount;
  int? followersCount;
  int? followingCount;

  UserData({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.bio,
    this.location,
    this.profilePicture,
    this.posts = const [],
    this.likeCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'].toString(),
      firstName: json['firstname'] ?? '',
      lastName: json['lastname'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      bio: json['bio'],
      location: json['location'],
      profilePicture: json['profilepicture'],
      posts: json['posts'] ?? [],
      likeCount: json['likecount']?.toInt() ?? 0,
      followersCount: (json['followers'] as List?)?.length ?? 0,
      followingCount: (json['following'] as List?)?.length ?? 0,
    );
  }
}

class SellerProfilePage extends StatefulWidget {
  final String sellerId;

  const SellerProfilePage({
    Key? key,
    required this.sellerId,
  }) : super(key: key);

  @override
  _SellerProfilePageState createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  UserData? sellerData;
  bool isLoading = true;
  String? _idToken;
  String? _currentUserId;
  bool _isFollowing = false;
  String? baseUrl;

  @override
  void initState() {
    super.initState();
    print('SellerProfilePage initialized with sellerId: ${widget.sellerId}');
    _initialize();
  }

  Future<void> _initialize() async {
    baseUrl = await ConfigUtils.getBaseUrl();
    _loadTokenAndData();
  }

  Future<void> _loadTokenAndData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');
      final userStr = prefs.getString('user');

      if (userStr != null) {
        final userData = jsonDecode(userStr);
        _currentUserId = userData['id'].toString();
      }

      if (idToken != null) {
        setState(() => _idToken = idToken);
        if (_currentUserId != widget.sellerId) {
          await _checkFollowStatus();
        }

        await _loadSellerData();
        await _fetchSellerProfile();
        await _fetchSellerPosts();
      }
    } catch (e) {
      print('Error loading token and data: $e');
    }
  }

  Future<void> _loadSellerData() async {
    if (baseUrl == null) return;

    try {
      setState(() => isLoading = true);
      // Get user data
      final userResponse = await http.get(
        Uri.parse('$baseUrl/users/${widget.sellerId}'),
        headers: {'Authorization': 'Bearer $_idToken'},
      );

      // Get followers data
      final followersResponse = await http.get(
        Uri.parse('$baseUrl/users/followers/${widget.sellerId}'),
        headers: {'Authorization': 'Bearer $_idToken'},
      );

      // Get following data
      final followingResponse = await http.get(
        Uri.parse('$baseUrl/users/following/${widget.sellerId}'),
        headers: {'Authorization': 'Bearer $_idToken'},
      );

      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);
        final followersData = json.decode(followersResponse.body);
        final followingData = json.decode(followingResponse.body);

        // Create user data with followers and following
        final userJson = userData['user'];
        userJson['followers'] = followersData['followers'];
        userJson['following'] = followingData['following'];

        setState(() {
          sellerData = UserData.fromJson(userJson);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading seller data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchSellerProfile() async {
    if (baseUrl == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/userProfile/${widget.sellerId}'),
        headers: {'Authorization': 'Bearer $_idToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final profile = data['userProfile'];
        setState(() {
          sellerData?.bio = profile['bio'];
          sellerData?.location = profile['location'];
          sellerData?.profilePicture = profile['profilepicture'];
        });
      }
    } catch (e) {
      print('Error fetching seller profile: $e');
    }
  }

  Future<void> _fetchSellerPosts() async {
    if (baseUrl == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts'),
        headers: {
          'Authorization': 'Bearer $_idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            sellerData?.posts = (data['posts'] as List)
                .where((post) => post['userid'].toString() == widget.sellerId)
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching seller posts: $e');
    }
  }

  Future<void> _checkFollowStatus() async {
    if (baseUrl == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');
      if (idToken == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/users/following/$_currentUserId'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final following = data['following'] as List;
        setState(() {
          _isFollowing =
              following.any((user) => user['id'].toString() == widget.sellerId);
        });
      }
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    if (baseUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Configuration error. Please try again later.')),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');
      if (idToken == null) return;

      final url = Uri.parse('$baseUrl/users/follow/${widget.sellerId}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({
          'followerId': _currentUserId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _isFollowing = !_isFollowing;
        });

        // Refresh all seller data
        await Future.wait([
          _loadSellerData(),
          _fetchSellerProfile(),
          _fetchSellerPosts(),
        ]);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(_isFollowing ? 'Following seller' : 'Unfollowed seller'),
            ),
          );
        }
      }
    } catch (e) {
      print('Error toggling follow status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating follow status')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // In the _SellerProfilePageState class, add these methods:

  Widget _buildPostImage(Map<String, dynamic> post) {
    // First try to get images array
    if (post['images'] != null &&
        post['images'] is List &&
        post['images'].isNotEmpty) {
      final firstImage = post['images'][0];
      if (firstImage != null && firstImage['data'] != null) {
        try {
          return _buildImageFromData(firstImage['data']);
        } catch (e) {
          print('Error building image from images array: $e');
          return _buildPlaceholder();
        }
      }
    }

    // Fallback to first_image if images array is empty
    if (post['first_image'] != null && post['first_image']['data'] != null) {
      try {
        return _buildImageFromData(post['first_image']['data']);
      } catch (e) {
        print('Error building image from first_image: $e');
        return _buildPlaceholder();
      }
    }

    return _buildPlaceholder();
  }

  Widget _buildImageFromData(String imageData) {
    try {
      final Uint8List bytes = _base64ToImage(imageData);
      return Container(
        width: double.infinity,
        height: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(4.0)),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading image: $error');
              return _buildPlaceholder();
            },
          ),
        ),
      );
    } catch (e) {
      print('Error processing image data: $e');
      return _buildPlaceholder();
    }
  }

  Uint8List _base64ToImage(String base64String) {
    try {
      // Handle both formats: with and without data URI scheme
      String pureBase64;
      if (base64String.contains(';base64,')) {
        pureBase64 = base64String.split(';base64,')[1].trim();
      } else if (base64String.contains(',')) {
        pureBase64 = base64String.split(',')[1].trim();
      } else {
        pureBase64 = base64String.trim();
      }

      // Remove any whitespace
      pureBase64 = pureBase64.replaceAll(RegExp(r'\s+'), '');

      // Add padding if needed
      while (pureBase64.length % 4 != 0) {
        pureBase64 += '=';
      }

      final bytes = base64Decode(pureBase64);
      if (bytes.isEmpty) {
        throw Exception('Decoded base64 is empty');
      }

      print('Successfully decoded image, byte length: ${bytes.length}');
      return bytes;
    } catch (e) {
      print('Error decoding base64: $e');
      print(
          'Base64 string preview: ${base64String.substring(0, min<int>(100, base64String.length))}');
      rethrow;
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.image,
          size: 40,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepOrange,
          title: Text('${sellerData?.username ?? "Seller"}\'s Profile'),
        ),
        body: Center(child: CircularProgressIndicator()),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 0,
        ),
      );
    }

    if (sellerData == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepOrange,
          title: Text('Seller Profile'),
        ),
        body: Center(child: Text('No seller data available')),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 0,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFFFFBF5),
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: Text('${sellerData!.username}\'s Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.grey[200],
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: sellerData!.profilePicture != null
                        ? NetworkImage(sellerData!.profilePicture!)
                        : null,
                    child: sellerData!.profilePicture == null
                        ? Text(
                            '${sellerData!.firstName[0]}${sellerData!.lastName[0]}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${sellerData!.firstName} ${sellerData!.lastName}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${sellerData!.username}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (sellerData!.bio != null && sellerData!.bio!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        sellerData!.bio!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  if (sellerData!.location != null &&
                      sellerData!.location!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on,
                              size: 16, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            sellerData!.location!,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatColumn('Likes', sellerData!.likeCount),
                      const SizedBox(width: 20),
                      _buildStatColumn('Items', sellerData!.posts.length),
                      const SizedBox(width: 20),
                      _buildStatColumn(
                          'Followers', sellerData!.followersCount ?? 0),
                      const SizedBox(width: 20),
                      _buildStatColumn(
                          'Following', sellerData!.followingCount ?? 0),
                    ],
                  ),
                  SizedBox(height: 16),
                  if (_currentUserId != null &&
                      _currentUserId != widget.sellerId)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        onPressed: _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isFollowing ? Colors.grey : Colors.deepOrange,
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          _isFollowing ? 'Unfollow' : 'Follow',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: sellerData!.posts.isEmpty
                  ? Center(child: Text("No items available"))
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10.0,
                        mainAxisSpacing: 10.0,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: sellerData!.posts.length,
                      itemBuilder: (context, index) {
                        final post = sellerData!.posts[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfilePostDetailPage(
                                  postId: post['id'].toString(),
                                ),
                              ),
                            ).then((_) => _fetchSellerPosts());
                          },
                          child: Card(
                            elevation: 4.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    color: Colors.grey[200],
                                    child: _buildPostImage(post),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '\$${post['price']}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        post['description'] ?? 'No description',
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
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
      ),
    );
  }
}
