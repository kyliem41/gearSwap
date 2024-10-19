import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:sample/appBar.dart'; // Assuming BottomNavBar is defined here
import 'package:sample/logIn/logIn.dart';
import 'package:sample/signUp/signUp.dart';

void main() {
  runApp(signUpUser()); // Entry point
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
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _GetPosts();
  }

  void _GetPosts() async {
    var url = Uri.parse(
        'https://hjsg6z4hj9.execute-api.us-east-2.amazonaws.com/Stage/posts');
    try {
      var response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print(data);

        setState(() {
          hasError = false;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load items');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: Colors.black,
                width: 0.5,
              ),
            ),
          ),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.deepOrange,
            elevation: 0,
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
                      ? Center(child: Text("Failed to load"))
                      : ListView(
                          children: <Widget>[
                            Wrap(
                              spacing: 10.0,
                              runSpacing: 10.0,
                              // Add your grid or list of items here
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(), // Placing BottomNavBar here
    );
  }
}
