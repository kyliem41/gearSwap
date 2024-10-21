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

  void _LogIn() { //async {
    Navigator.push(context, MaterialPageRoute(builder: (context) => MyApp()));
    // var url = Uri.parse(
    //     'https://hjsg6z4hj9.execute-api.us-east-2.amazonaws.com/Stage/login');
    // try {
    //   var response = await http.post(
    //     url,
    //     headers: {
    //       'Content-Type': 'application/json',
    //       'authorizationToken': _passwordController.text,
    //     },
    //     body: jsonEncode({
    //       'password': _passwordController.text,
    //     }),
    //   );

    //   if (response.statusCode == 200) {
    //     print('LogIn successful');
    //     Map<String, dynamic> user = jsonDecode(response.body);
    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(builder: (context) => MyApp()),
    //     );
    //   } else {
    //     _showLoginFailedDialog();
    //   }
    // } catch (e) {
    //   print('Error occurred: $e');
    // }
  }

  void _showLoginFailedDialog() {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Colors.deepOrange[100],
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
                    obscureText: true, // Hide password input
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Enter your password',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // "Forgot Password?" Link
                  Center( // Centering the link
                    child: TextButton(
                      onPressed: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => ForgotPasswordPage(),
                        //   ),
                        // );
                        Placeholder();
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Colors.deepOrange,
                          decoration: TextDecoration.underline, // Underline the text
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      _LogIn();
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
                  
                  SizedBox(height: 25),
                  
                  // "Sign Up" Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? "),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => signUpUser(),
                            ),
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.deepOrange,
                            decoration: TextDecoration.underline, // Underline the text
                          ),
                        ),
                      ),
                    ],
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
