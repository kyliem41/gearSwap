import 'dart:async';

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
import 'dart:math';

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
          userData!.posts = profile['posts'] ?? [];
        });

        print('Fetched profile with ${userData!.posts.length} posts');
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  Future<void> _fetchUserPosts() async {
    if (baseUrl == null) return;

    try {
      final url = Uri.parse('$baseUrl/posts?include_sold=true');
      print('Fetching posts from URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Log the raw response
        print('Raw API response: ${response.body}');

        var data = json.decode(response.body);
        var allPosts = data['posts'] as List;

        // Process and log each post before filtering
        print('All posts before processing:');
        for (var post in allPosts) {
          print(
              'Post ${post['id']}: isSold = ${post['issold']}, type = ${post['issold'].runtimeType}');
        }

        var userPosts = allPosts
            .where((post) => post['userid'] == userData!.id)
            .map((post) {
          // Create a new map to avoid reference issues
          var processedPost = Map<String, dynamic>.from(post);

          // Explicit boolean conversion with logging
          var rawIsSold = post['issold'];
          print('Processing post ${post['id']}:');
          print('  Raw issold value: $rawIsSold');
          print('  Raw issold type: ${rawIsSold.runtimeType}');

          bool isSold;
          if (rawIsSold is bool) {
            isSold = rawIsSold;
          } else if (rawIsSold is String) {
            isSold = rawIsSold.toLowerCase() == 'true';
          } else {
            isSold = false;
          }

          processedPost['issold'] = isSold;
          print('  Final isSold value: ${processedPost['issold']}');
          return processedPost;
        }).toList();

        print('Processed user posts:');
        for (var post in userPosts) {
          print(
              'Post ${post['id']}: isSold = ${post['issold']}, type = ${post['issold'].runtimeType}');
        }

        if (mounted) {
          setState(() {
            userData!.posts = userPosts;
          });

          // Verify the state after setting
          print('Posts in state after update:');
          for (var post in userData!.posts) {
            print(
                'Post ${post['id']}: isSold = ${post['issold']}, type = ${post['issold'].runtimeType}');
          }
        }
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error fetching user posts: $e');
      print('Stack trace: $stackTrace');
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

      setState(() {
        isLoading = true;
      });

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      await reader.onLoad.first;
      final Uint8List imageData = reader.result as Uint8List;
      final String base64Data = base64Encode(imageData);

      // Create request body
      final Map<String, dynamic> requestBody = {
        'profilePicture': base64Data,
        'content_type': file.type ?? 'image/jpeg'
      };

      // Convert request body to JSON string
      final String jsonBody = json.encode(requestBody);

      // Make the HTTP PUT request
      final response = await http.put(
        Uri.parse('$baseUrl/userProfile/${userData!.id}/profilePicture'),
        headers: {
          'Authorization': 'Bearer $_idToken',
          'Content-Type': 'application/json',
        },
        body: jsonBody,
      );

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
        SnackBar(content: Text('Failed to update profile picture: $e')),
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
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              child: userData?.profilePicture != null
                  ? ClipOval(
                      child: _buildProfileImage(),
                    )
                  : Text(
                      '${userData!.firstName[0]}${userData!.lastName[0]}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
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
    return Center(
      child: Text(
        '${userData?.firstName[0] ?? ''}${userData?.lastName[0] ?? ''}',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.deepOrange,
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

  Widget _buildProfileImage() {
    if (userData?.profilePicture != null) {
      try {
        return Image.memory(
          _base64ToImage(userData!.profilePicture!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading profile image: $error');
            return _buildDefaultAvatar();
          },
        );
      } catch (e) {
        print('Error processing profile image: $e');
        return _buildDefaultAvatar();
      }
    }
    return _buildDefaultAvatar();
  }

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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WishlistPage()),
                );
              } else if (index == 2) {
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
                                  child: Stack(
                                    children: [
                                      _buildPostImage(post),
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        right: 8,
                                        child: Text(
                                          '\$${post['price']}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                            backgroundColor:
                                                Colors.white.withOpacity(0.8),
                                            // Add padding to the text
                                            height: 1.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
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
      if (post['first_image'] != null &&
          post['first_image']['data'] != null &&
          post['first_image']['content_type'] != null) {
        String imageData = post['first_image']['data'];

        print('Raw isSold value for post ${post['id']}: ${post['issold']}');
        print('isSold value type: ${post['issold'].runtimeType}');

        bool isSold = false;
        var rawSoldStatus = post['issold'];
        if (rawSoldStatus is bool) {
          isSold = rawSoldStatus;
        } else if (rawSoldStatus is String) {
          isSold = rawSoldStatus.toLowerCase() == 'true';
        } else if (rawSoldStatus != null) {
          isSold = rawSoldStatus == true;
        }

        print('Final isSold status for post ${post['id']}: $isSold');

        return Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(4.0)),
                child: Image.memory(
                  _base64ToImage(imageData),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading image: $error');
                    return _buildPlaceholder();
                  },
                ),
              ),
            ),
            if (isSold)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'SOLD',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            // Positioned(
            //   bottom: 8,
            //   left: 8,
            //   right: 8,
            //   child: Container(
            //     padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            //     color: Colors.white.withOpacity(0.8),
            //     child: Text(
            //       '\$${post['price']}',
            //       style: TextStyle(
            //         fontSize: 18,
            //         fontWeight: FontWeight.bold,
            //         color: Colors.black,
            //       ),
            //       textAlign: TextAlign.center,
            //     ),
            //   ),
            // ),
          ],
        );
      }
      return _buildPlaceholder();
    } catch (e) {
      print('Error in _buildPostImage: $e');
      return _buildPlaceholder();
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
