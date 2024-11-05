import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sample/logIn/resetPass.dart';
import 'package:sample/signUp/signUp.dart';
import 'package:sample/shared/config_utils.dart';
import '../main.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _isLoading = false;
  String _errorMessage = '';
  String? baseUrl;

  @override
  void initState() {
    super.initState();
    _initializeBaseUrl();
  }

  Future<void> _initializeBaseUrl() async {
    baseUrl = await ConfigUtils.getBaseUrl();
  }

  Future<void> _logIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    if (!_validateInputs()) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (baseUrl == null) {
      setState(() {
        _errorMessage = 'Configuration error. Please try again later.';
        _isLoading = false;
      });
      _showErrorDialog(_errorMessage);
      return;
    }

    var url = Uri.parse('$baseUrl/login');
    
    try {
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      // Print the raw response body for debugging
      print("Raw response: ${response.body}");
      
      var data = jsonDecode(response.body);
      
      // Handle error response
      if (response.statusCode != 200) {
        setState(() {
          _errorMessage = data['body'] ?? 'Login failed. Please try again.';
        });
        _showErrorDialog(_errorMessage);
        return;
      }

      // Handle successful response
      if (data['message'] == 'Login successful') {
        // Save the tokens
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', data['accessToken']);
        await prefs.setString('idToken', data['idToken']);
        await prefs.setString('refreshToken', data['refreshToken']);
        
        // Save user info if present
        if (data['user'] != null) {
          await prefs.setString('user', jsonEncode(data['user']));
        }
        
        // Navigate to home page
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MyHomePage(title: 'GearSwap'),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Login failed. Please try again.';
        });
        _showErrorDialog(_errorMessage);
      }
    } catch (e, stackTrace) {
      print('Login error: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
      _showErrorDialog(_errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _validateInputs() {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email';
      });
      _showErrorDialog(_errorMessage);
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailController.text.trim())) {
      setState(() {
        _errorMessage = 'Please enter a valid email';
      });
      _showErrorDialog(_errorMessage);
      return false;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password';
      });
      _showErrorDialog(_errorMessage);
      return false;
    }

    return true;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
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
            child: SingleChildScrollView(
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
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Enter your Email',
                        filled: true,
                        fillColor: Colors.white,
                        errorText: _errorMessage.contains('email') ? _errorMessage : null,
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
                      obscureText: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Enter your password',
                        filled: true,
                        fillColor: Colors.white,
                        errorText: _errorMessage.contains('password') ? _errorMessage : null,
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResetPasswordPage(),
                              ),
                            );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.deepOrange,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    _isLoading
                        ? CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                          )
                        : ElevatedButton(
                            onPressed: _logIn,
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
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
