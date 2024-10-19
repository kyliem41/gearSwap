import 'package:flutter/material.dart';
import 'package:sample/main.dart';
import 'package:sample/profile/profile.dart';
import 'package:sample/search/search.dart';

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

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyHomePage(title: 'GearSwap'),
          ),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchPage(),
          ),
        );
        break;
      case 2:
        // Add functionality for calendar
        break;
      case 3:
        // Add functionality for help
        break;
      case 4:
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => SettingsPage(),
        //   ),
        // );
        break;
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(),
          ),
        );
        break;
      case 6:
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => signUpUser(),
        //   ),
        // );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _getBodyContent(_selectedIndex), // Body content based on selected index
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensures all items are shown
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
            icon: Icon(Icons.person),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'New Post',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'My Swap',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
      ),
    );
  }

  // Body content based on navigation selection
  Widget _getBodyContent(int index) {
    switch (index) {
      case 0:
        return Text('Home Page');
      case 1:
        return Text('Search Page');
      case 2:
        return Text('New Post Page');
      case 3:
        return Text('Inbox Page');
      case 4:
        return Text('My Swap Page');
      case 5:
        return Text('Logging Out...');
      default:
        return Text('Page not found');
    }
  }
}
