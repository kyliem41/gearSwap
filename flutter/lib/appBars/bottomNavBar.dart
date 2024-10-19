import 'package:flutter/material.dart';
import 'package:sample/main.dart';
import 'package:sample/posts/newPost.dart';
import 'package:sample/profile/profile.dart';
import 'package:sample/search/search.dart';
import 'package:sample/styler/styler.dart';
import 'package:sample/wishlist/wishlist.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class BottomNavBar extends StatefulWidget {
  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  // Navigation functions
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Use Navigator to go to the new page
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MyHomePage(title: 'GearSwap'),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SearchPage(),
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NewPostPage(),
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StylistPage(),
          ),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WishlistPage(
              username: 'john',
            ),
          ),
        );
        break;
      case 5:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(),
          ),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.deepOrange,
      selectedItemColor: Colors.lightBlue[300],
      unselectedItemColor: Color.fromARGB(248, 255, 255, 255),
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_rounded),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_add),
          label: 'New Post',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.checkroom_rounded),
          label: 'Styler',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.mail_outline_rounded),
          label: 'Inbox',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'My Swap',
        ),
      ],
    );
  }
}
