import 'package:flutter/material.dart';
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar.dart';
import 'package:sample/profile/profile.dart';
import 'package:sample/wishlist/wishlist.dart';

class OutfitsPage extends StatefulWidget {
  @override
  _OutfitsPageState createState() => _OutfitsPageState();
}

class _OutfitsPageState extends State<OutfitsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> outfits = [
    {
      'name': 'Casual Day Out',
      'posts': [
        {'image': 'assets/images/jacket1.jpg', 'description': 'Leather Jacket'},
        {'image': 'assets/images/skirt1.jpg', 'description': 'Floral Skirt'},
      ],
    },
    {
      'name': 'Summer Vibes',
      'posts': [
        {'image': 'assets/images/shoes1.jpg', 'description': 'Sneakers'},
        {'image': 'assets/images/hm1.jpg', 'description': 'H&M Dress'},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 3, vsync: this, initialIndex: 2);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void onOutfitClick(int index) {
    // Handle outfit click, e.g., show details or navigate to another page
  }

  void createNewOutfit() {
    // Logic to create a new outfit, navigate to a creation page
    print('Create a new outfit');
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
            onTap: (index) {
              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => WishlistPage(
                            username: 'john',
                          )),
                );
              } else if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              }
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10.0,
                  crossAxisSpacing: 10.0,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: outfits.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      onOutfitClick(index);
                    },
                    child: Card(
                      elevation: 3.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              outfits[index]['name'],
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children:
                                  outfits[index]['posts'].map<Widget>((post) {
                                return Expanded(
                                  child: Container(
                                    margin: EdgeInsets.all(5.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      image: DecorationImage(
                                        image: AssetImage(post['image']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewOutfit,
        backgroundColor: Colors.deepOrange,
        child: Icon(Icons.add),
        tooltip: 'Create a new outfit',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      bottomNavigationBar: BottomNavBar(),
    );
  }
}
