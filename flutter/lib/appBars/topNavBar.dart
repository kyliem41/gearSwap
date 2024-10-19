import 'package:flutter/material.dart';
import 'package:sample/cart/cart.dart';
import 'package:sample/main.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize; // Define preferred size

  TopNavBar({Key? key})
      : preferredSize = Size.fromHeight(60.0),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, 
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swap_calls_rounded, color: Colors.white), 
          SizedBox(width: 8), 
          Text(
            'GearSwap',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
      backgroundColor: Colors.deepOrange,
      actions: [
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
              Icons.logout, // Logout icon
              color: Color.fromARGB(248, 255, 255, 255),
              size: 30, 
            ),
            onPressed: () {
              logOut(context); // Call logOut function
            },
          ),
        ),
      ],
    );
  }
}

logOut(context) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => MyHomePage(title: "GearSwap"),
    ),
  );
}
