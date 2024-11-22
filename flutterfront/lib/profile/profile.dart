import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar.dart';
import 'package:sample/outfits/outfits.dart';
import 'package:sample/profile/editProfile.dart';
import 'package:sample/profile/profilePostDetails.dart';
import 'package:sample/shared/config_utils.dart';
import 'package:sample/wishlist/wishlist.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

class UserData {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? profileInfo;
  final DateTime joinDate;
  final int likeCount;
  String? bio;
  String? location;
  String? profilePicture;
  List<dynamic> posts = [];
  List<dynamic> followers = [];
  List<dynamic> following = [];
  bool isFollowedByCurrentUser;

  UserData({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.profileInfo,
    required this.joinDate,
    required this.likeCount,
    this.bio,
    this.location,
    this.profilePicture,
    List<dynamic>? posts,
    List<dynamic>? followers,
    List<dynamic>? following,
    this.isFollowedByCurrentUser = false,
  }) {
    this.posts = posts ?? [];
    this.followers = followers ?? [];
    this.following = following ?? [];
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'],
      firstName: json['firstname'] ?? '',
      lastName: json['lastname'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profileInfo: json['profileinfo']?.toString(),
      joinDate: DateTime.parse(json['joindate']),
      likeCount: json['likecount'] ?? 0,
      bio: json['bio'],
      location: json['location'],
      profilePicture: json['profilepicture'],
      followers: json['followers'] ?? [],
      following: json['following'] ?? [],
    );
  }

  int get followersCount {
    return followers.length;
  }

  int get followingCount {
    return following.length;
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserData? userData;
  bool isLoading = true;
  String? _idToken;
  String? baseUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _initialize();
  }

  Future<void> _initialize() async {
    baseUrl = await ConfigUtils.getBaseUrl();
    _loadUserDataAndProfile();
  }

  Future<void> _loadUserDataAndProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      final idToken = prefs.getString('idToken');

      print('Loading user data...');
      print('User string exists: ${userString != null}');
      print('ID token exists: ${idToken != null}');

      if (userString != null && idToken != null) {
        final userJson = jsonDecode(userString);
        print('User ID from stored data: ${userJson['id']}');

        setState(() {
          _idToken = idToken;
          userData = UserData.fromJson(userJson);
        });

        await _fetchUserProfile();
        await _fetchUserPosts();
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    if (baseUrl == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/userProfile/${userData!.id}'),
        headers: {
          'Authorization': 'Bearer $_idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final profile = data['userProfile'];
        setState(() {
          userData!.bio = profile['bio'];
          userData!.location = profile['location'];
          userData!.profilePicture = profile['profilepicture'];
        });
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  Future<void> _fetchUserPosts() async {
    if (baseUrl == null) return;

    try {
      final url = Uri.parse('$baseUrl/posts');
      print('Fetching posts for user ID: ${userData!.id}');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_idToken',
          'Content-Type': 'application/json',
        },
      );

      print('Posts response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var allPosts = data['posts'] as List;
        var userPosts =
            allPosts.where((post) => post['userid'] == userData!.id).toList();

        print('Found ${userPosts.length} posts for user ${userData!.id}');
        // Debug first post's image data
        if (userPosts.isNotEmpty) {
          print('First post images: ${userPosts[0]['images']}');
        }

        setState(() {
          userData!.posts = userPosts;
        });
      }
    } catch (e) {
      print('Error fetching user posts: $e');
    }
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          userData: userData!,
          idToken: _idToken!,
        ),
      ),
    );

    if (result == true) {
      _loadUserDataAndProfile();
    }
  }

  Future<void> _updateProfilePicture() async {
    if (baseUrl == null || _idToken == null || userData == null) return;

    try {
      final input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();

      await input.onChange.first;
      if (input.files?.isEmpty ?? true) return;

      final file = input.files!.first;

      // Validate file size (5MB limit)
      if (file.size! > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image size must be less than 5MB')),
        );
        return;
      }

      // Validate file type
      if (!['image/jpeg', 'image/png'].contains(file.type)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Only JPEG and PNG images are allowed')),
        );
        return;
      }

      setState(() {
        isLoading = true;
      });

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      await reader.onLoad.first;
      final bytes = reader.result as Uint8List;
      final base64Image = base64Encode(bytes);

      // Print request details for debugging
      print(
          'Making request to: $baseUrl/userProfile/${userData!.id}/profilePicture');
      print('Content type: ${file.type}');

      final response = await http.put(
        Uri.parse('$baseUrl/userProfile/${userData!.id}/profilePicture'),
        headers: {
          'Authorization': 'Bearer $_idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'profilePicture': base64Image,
          'content_type': file.type,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        await _fetchUserProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile picture updated successfully')),
        );
      } else {
        throw Exception('Failed to update profile picture: ${response.body}');
      }
    } catch (e) {
      print('Error updating profile picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile picture: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildProfilePicture() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _showImageOptions,
        child: Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: ClipOval(
                child: userData?.profilePicture != null
                    ? Image.memory(
                        _getImageData(userData!.profilePicture!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading profile image: $error');
                          return _buildDefaultAvatar();
                        },
                      )
                    : _buildDefaultAvatar(),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.3),
                ),
                child: Center(
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Text(
          '${userData?.firstName[0] ?? ""}${userData?.lastName[0] ?? ""}',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
      ),
    );
  }

  Uint8List _getImageData(String profilePicture) {
    try {
      if (profilePicture.startsWith('data:image')) {
        final base64String = profilePicture.split(',')[1];
        return base64Decode(base64String);
      } else {
        // Handle URL-based images if needed
        throw Exception('Unsupported image format');
      }
    } catch (e) {
      print('Error decoding image data: $e');
      throw e;
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _updateProfilePicture();
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel),
                title: Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  // ImageProvider _buildProfileImage() {
  //   if (userData?.profilePicture == null)
  //     return NetworkImage('path_to_default_image');

  //   try {
  //     if (userData!.profilePicture!.startsWith('data:image')) {
  //       // Handle base64 image
  //       final base64String = userData!.profilePicture!.split(',').last;
  //       return MemoryImage(base64Decode(base64String));
  //     } else {
  //       // Handle URL image
  //       return NetworkImage(userData!.profilePicture!);
  //     }
  //   } catch (e) {
  //     print('Error loading profile image: $e');
  //     return NetworkImage('path_to_default_image');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavBar(),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.deepOrange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepOrange,
            indicatorWeight: 3,
            onTap: (index) {
              if (index == 0) {
                // Navigate to WishlistPage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WishlistPage()),
                );
              } else if (index == 2) {
                // Navigate to OutfitsPage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OutfitsPage()),
                );
              }
            },
            tabs: const [
              Tab(text: "Wishlist"),
              Tab(text: "My Swap"),
              Tab(text: "Outfits"),
            ],
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToEditProfile,
        child: Icon(Icons.edit),
        backgroundColor: Colors.deepOrange,
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (userData == null) {
      return Center(child: Text('No profile data available'));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: Column(
              children: [
                _buildProfilePicture(),
                // CircleAvatar(
                //   radius: 50,
                //   backgroundImage: userData!.profilePicture != null
                //       ? NetworkImage(userData!.profilePicture!)
                //       : null,
                //   child: userData!.profilePicture == null
                //       ? Text(
                //           '${userData!.firstName[0]}${userData!.lastName[0]}',
                //           style: TextStyle(
                //             fontSize: 32,
                //             fontWeight: FontWeight.bold,
                //             color: Colors.deepOrange,
                //           ),
                //         )
                //       : null,
                // ),
                const SizedBox(height: 16),
                Text(
                  '${userData!.firstName} ${userData!.lastName}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${userData!.username}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                if (userData!.bio != null && userData!.bio!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      userData!.bio!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                if (userData!.location != null &&
                    userData!.location!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          userData!.location!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatColumn('Likes', userData!.likeCount),
                    const SizedBox(width: 30),
                    _buildStatColumn('Items', userData!.posts.length),
                    const SizedBox(width: 30),
                    _buildStatColumn('Followers', userData!.followers.length),
                    const SizedBox(width: 30),
                    _buildStatColumn('Following', userData!.following.length),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: userData!.posts.isEmpty
                ? Center(child: Text("No posts available"))
                : GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: userData!.posts.length,
                    itemBuilder: (context, index) {
                      final post = userData!.posts[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePostDetailPage(
                                postId: post['id'].toString(),
                              ),
                            ),
                          ).then((_) {
                            _fetchUserPosts();
                          });
                        },
                        child: Card(
                          elevation: 4.0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: _buildPostImage(post),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            '\$${post['price']}',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
    );
  }

  Widget _buildPostImage(Map<String, dynamic> post) {
    try {
      print('Building image for post ${post['id']}');
      print('Images data: ${post['images']}');

      if (post['images'] != null &&
          post['images'] is List &&
          post['images'].isNotEmpty &&
          post['images'][0] != null) {
        if (post['images'][0]['data'] != null) {
          String base64String = post['images'][0]['data'];
          // Clean up base64 string
          base64String = base64String.trim();
          base64String = base64String.replaceAll(RegExp(r'\s+'), '');

          // Add padding if needed
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
                  print(
                      'Error displaying image for post ${post['id']}: $error');
                  return _buildPlaceholder();
                },
              ),
            );
          } catch (e) {
            print('Error decoding base64 for post ${post['id']}: $e');
            return _buildPlaceholder();
          }
        }
      }
      return _buildPlaceholder();
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

  Future<Uint8List> _loadImageData(String imageId) async {
    if (baseUrl == null) {
      throw Exception('Base URL not initialized');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/posts/images/$imageId'),
      headers: {
        'Authorization': 'Bearer $_idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return base64Decode(response.body);
    }
    throw Exception('Failed to load image');
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
}
