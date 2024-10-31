import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar.dart';
import 'package:sample/outfits/outfits.dart';
import 'package:sample/profile/editProfile.dart';
import 'package:sample/profile/profilePostDetails.dart';
import 'package:sample/wishlist/wishlist.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  });

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
    );
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
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
    try {
      final response = await http.get(
        Uri.parse(
            'https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/userProfile/${userData!.id}'),
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
  try {
    // Get the user's posts where userid matches
    var postsUrl = Uri.parse('https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/posts');
    
    print('Fetching posts for user ID: ${userData!.id}');
    var response = await http.get(
      postsUrl,
      headers: {
        'Authorization': 'Bearer $_idToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('Posts response status: ${response.statusCode}');
    print('Posts response: ${response.body}');

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        // Filter posts where userid matches current user's id
        userData!.posts = (data['posts'] as List).where((post) => 
          post['userid'] == userData!.id
        ).toList();
      });
      print('Found ${userData!.posts.length} posts for user ${userData!.id}');
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
                CircleAvatar(
                  radius: 50,
                  backgroundImage: userData!.profilePicture != null
                      ? NetworkImage(userData!.profilePicture!)
                      : null,
                  child: userData!.profilePicture == null
                      ? Text(
                          '${userData!.firstName[0]}${userData!.lastName[0]}',
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
                if (userData!.location != null && userData!.location!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
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
                    const SizedBox(width: 40),
                    _buildStatColumn('Items', userData!.posts.length),
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
                            // Refresh the posts when returning from detail page
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
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (post['photos'] != null &&
                                            post['photos'].isNotEmpty)
                                          Image.network(
                                            post['photos'][0],
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
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
                                        const SizedBox(height: 8),
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
