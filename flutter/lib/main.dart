import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sample/logIn/logIn.dart';
import 'dart:convert';

import 'package:sample/signUp/signUp.dart';

void main() {
  // runApp(const loginUser());
  runApp(signUpUser());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GearSwap',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'GearSwap'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // final storage = new FlutterSecureStorage();
  // List<dynamic> courses = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      _GetPosts();
    });
  }

  void _GetPosts() async {
    //get the items from the database
    //return the items

    var url = Uri.parse(
        'https://hjsg6z4hj9.execute-api.us-east-2.amazonaws.com/Stage/posts');
    try {
      var response = await http.get(
        url,
        headers: {
          'Content-Type':
              'application/json', // Set the content type to application/json
        },
      );

      if (response.statusCode == 200) {
        // Parse the JSON response
        var data = jsonDecode(response.body);
        print(data);

        setState(() {
          // courses = List<dynamic>.from(data);
          hasError = false;
          isLoading = false;
          // print(courses);
        });

        // // Return the list of items
        // return List<dynamic>.from(data);
      } else {
        // If the response status code is not 200, throw an exception
        print("failed to get all items");
        throw Exception('Failed to load items');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          // Fixed Side App Bar
          // SideAppBar(), // Include the side app bar here

          // Main Content Area
          Expanded(
            child: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(100.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Transparent background
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black, // Bottom border color
                        width: .5, // Bottom border thickness
                      ),
                    ),
                  ),
                  child: AppBar(
                    automaticallyImplyLeading: false,
                    backgroundColor: Colors.deepPurple[100],
                    elevation: 0, // Remove the shadow
                    title: Padding(
                      padding: EdgeInsets.only(top: 20.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Dashboard",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 50.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              body: Column(
                children: <Widget>[
                  // Main content area (scrollable)
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(20.0),
                      child: isLoading
                          ? Center(child: CircularProgressIndicator())
                          : hasError
                              ? Center(child: Text("Failed to load "))
                              : ListView(
                                  children: <Widget>[
                                    Wrap(
                                      spacing: 10.0,
                                      runSpacing: 10.0,
                                      // children: <Widget>[
                                    //     for (var course in courses)
                                    //       if (course['status'] == "ACTIVE")
                                    //         CoursesWidget(json: course),
                                    //   ],
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  //footer
                  Container(
                    height: 70.0,
                    width: double.infinity,
                    color: Colors.deepPurple[100],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
