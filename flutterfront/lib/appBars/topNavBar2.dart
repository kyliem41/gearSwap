import 'package:flutter/material.dart';
import 'package:sample/cart/cart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sample/logIn/logIn.dart';

class TopNavBar2 extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;

  TopNavBar2({Key? key})
      : preferredSize = Size.fromHeight(60.0),
        super(key: key);

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all authentication data
      await prefs.remove('idToken');
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      await prefs.remove('user');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged out successfully'),
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => loginUser()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('Error during logout: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.deepOrange,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: 120),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swap_calls_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'GearSwap',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: Icon(
                    Icons.shopping_bag_outlined,
                    color: Color.fromARGB(248, 255, 255, 255),
                    size: 30,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CartPage(),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: Icon(
                    Icons.logout,
                    color: Color.fromARGB(248, 255, 255, 255),
                    size: 30,
                  ),
                  onPressed: () => _handleLogout(context),
                  tooltip: 'Logout',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}