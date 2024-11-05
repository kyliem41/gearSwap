import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sample/logIn/logIn.dart';
import 'dart:convert';
import 'package:sample/profile/profile.dart';

class EditProfilePage extends StatefulWidget {
  final UserData userData;
  final String idToken;

  EditProfilePage({required this.userData, required this.idToken});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _profilePictureController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.userData.bio);
    _locationController = TextEditingController(text: widget.userData.location);
    _profilePictureController = TextEditingController(text: widget.userData.profilePicture);
  }

  @override
  void dispose() {
    _bioController.dispose();
    _locationController.dispose();
    _profilePictureController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    // Show confirmation dialog
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text('Are you sure you want to delete your account? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      setState(() => _isLoading = true);

      try {
        final url = Uri.parse('https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/users/${widget.userData.id}');
        
        final response = await http.delete(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.idToken}',
          },
        );

        if (response.statusCode == 200) {
          // Successfully deleted account
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Account deleted successfully')),
            );
            // Navigate to login page and clear navigation stack
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => loginUser()),
              (Route<dynamic> route) => false,
            );
          }
        } else {
          throw Exception('Failed to delete account');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }


  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('https://96uriavbl7.execute-api.us-east-2.amazonaws.com/Stage/userProfile/${widget.userData.id}');
      final body = {
        'bio': _bioController.text,
        'location': _locationController.text,
        'profilePicture': _profilePictureController.text,
      };

      print('Making PUT request to: $url');
      print('Request body: ${json.encode(body)}');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.idToken}',
        },
        body: json.encode(body),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['message'] == 'UserProfile updated successfully') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('Unexpected response message: ${responseData['message']}');
        }
      } else {
        final errorMessage = response.body;
        throw Exception('Server returned ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      print('Error details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoading)
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            TextField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell us about yourself',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                hintText: 'Where are you located?',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _profilePictureController,
              decoration: InputDecoration(
                labelText: 'Profile Picture URL',
                hintText: 'Enter the URL of your profile picture',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('Save Changes', style: TextStyle(fontSize: 16)),
            ),
          SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _deleteAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Delete Account', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}