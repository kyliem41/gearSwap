import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sample/signUp/signUp.dart';
import '../main.dart';

void login() {
  runApp(const loginUser());
}

class loginUser extends StatelessWidget {
  const loginUser({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(),
      home: const MyLoginPage(title: 'Login'),
    );
  }
}

class MyLoginPage extends StatefulWidget {
  const MyLoginPage({super.key, required this.title});

  final String title;

  @override
  State<MyLoginPage> createState() => _MyLoginPageState();
}

class _MyLoginPageState extends State<MyLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // final storage = new FlutterSecureStorage();

  void _LogIn() async {
    //print(response1.body);
    var url = Uri.parse(
        'https://hjsg6z4hj9.execute-api.us-east-2.amazonaws.com/Stage/login');
    print('url');
    try {
      print(url);
      var response = await http.post(
        url,
        headers: {
          'Content-Type':
              'application/json',
          'authorizationToken': _passwordController.text,
        },
        body: jsonEncode({
          'password': _passwordController.text,
        }),
      );

      print(response.statusCode);
      if (response.statusCode == 200) {
        print('LogIn successful');
        // Navigate to the next page
        Map<String, dynamic> user = jsonDecode(response.body);
        // print(response.body);
        // await storage.write(key: 'token', value: user["Id"]);
        // await storage.write(key: 'UserId', value: user["Id"]);
        // await storage.write(key: 'role', value: user["role"]);
        // print(await storage.read(key: 'role'));
        // String? token = await storage.read(key: 'token');
        print('userid');
        print(user["Id"]);

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyApp()),
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Login Failed"),
              content: const Text("Incorrect Email or Password."),
              actions: <Widget>[
                TextButton(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        print('Failed to LogIn');
        // Handle failure or show error message
      }
    } catch (e) {
      print('Error occurred: $e');
      // Handle network error or show error message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Colors.deepPurple[100],
              // image: DecorationImage(
              //   image: AssetImage("assets/BidBackground.png"),
              //   fit: BoxFit.cover,
              // ),
            ),
          ),
          Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 300),
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2.0),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Login',
                    style: TextStyle(color: Colors.black, fontSize: 24.0),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  const Text(
                    'Email',
                    style: TextStyle(color: Colors.black),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Enter your Email',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  const Text(
                    'Password',
                    style: TextStyle(color: Colors.black),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Enter your password',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      // Add your onPressed code here
                      Navigator.push(
                       context,
                       MaterialPageRoute(
                           builder: (context) => signUpUser()),
                      );
                    },
                    child: Text(''),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      _LogIn();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyHomePage(title: 'GearSwap'),
                        ),
                      );
                    },
                    child: Text('Login'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                    ),
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
