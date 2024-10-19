import 'package:flutter/material.dart';
import 'package:sample/cart/cart.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize; // Define preferred size

  TopNavBar({Key? key})
      : preferredSize = Size.fromHeight(60.0), // Set your preferred height here
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, // Removes the back arrow
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swap_calls_rounded, color: Colors.white), // Home icon to match bottom navbar
          SizedBox(width: 8), // Add some spacing
          Text(
            'GearSwap', // Title of the app
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
      backgroundColor: Colors.deepOrange,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0), // Add padding to the right
          child: IconButton(
            icon: Icon(
              Icons.shopping_bag_outlined, // Cart icon
              color: Color.fromARGB(248, 255, 255, 255), // Match color with bottom navbar
              size: 30, // Set icon size to match bottom navbar icons
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
      ],
    );
  }
}
