import 'package:flutter/material.dart';
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sample/shared/config_utils.dart';
import 'package:ably_flutter/ably_flutter.dart' as ably;

class StylistPage extends StatefulWidget {
  const StylistPage({super.key});

  @override
  State<StylistPage> createState() => _StylistPageState();
}

class _StylistPageState extends State<StylistPage> {
  final List<Message> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  String? _baseUrl;
  String? _userId;
  String? _idToken;
  late ably.Realtime _realtime;
  late ably.RealtimeChannel _channel;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<bool> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      _idToken = prefs.getString('idToken');

      if (userString != null && _idToken != null) {
        final userJson = jsonDecode(userString);
        setState(() {
          _userId = userJson['id'].toString();
        });
        print('Loaded userId: $_userId with token: $_idToken');
        return true;
      } else {
        print('No user data or token found');
        return false;
      }
    } catch (e) {
      print('Error loading user data: $e');
      return false;
    }
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    
    try {
      _baseUrl = await ConfigUtils.getBaseUrl();
      final isAuthenticated = await _loadUserData();

      if (!isAuthenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to access the stylist')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      await _loadChatHistory();
      await _initializeAbly();
      
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      print('Initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadChatHistory() async {
    if (_userId == null || _idToken == null) return;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/styler/chat/$_userId/history'),
        headers: {
          'Authorization': 'Bearer $_idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final history = data['history'] as List;

        setState(() {
          _messages.addAll(history.map((msg) => Message(
                text: msg['message'],
                isAI: msg['type'] == 'ai',
                timestamp: DateTime.parse(msg['timestamp']),
              )));
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        });
      } else {
        throw Exception('Failed to load chat history: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading chat history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chat history: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getLastMessages(int count) {
    final messages = _messages.reversed.take(count).toList().reversed;
    return messages
        .map((msg) => {
              'content': msg.text,
              'role': msg.isAI ? 'assistant' : 'user',
              'timestamp': msg.timestamp.toIso8601String(),
            })
        .toList();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (_userId == null || _idToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to send messages')),
      );
      return;
    }

    final timestamp = DateTime.now();

    setState(() {
      _messages.add(Message(
        text: text,
        isAI: false,
        timestamp: timestamp,
      ));
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/styler/chat/$_userId'),
        headers: {
          'Authorization': 'Bearer $_idToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'message': text,
          'type': _determineMessageType(text),
          'context': _getLastMessages(3),
          'timestamp': timestamp.toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to send message');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String _determineMessageType(String text) {
    final lowercase = text.toLowerCase();
    if (lowercase.contains('outfit') ||
        lowercase.contains('wear') ||
        lowercase.contains('dress')) {
      return 'outfit';
    } else if (lowercase.contains('shop') ||
        lowercase.contains('buy') ||
        lowercase.contains('purchase')) {
      return 'item';
    }
    return 'conversation';
  }

  Future<void> _initializeAbly() async {
    if (_userId == null) return;

    try {
      final ablyKey = await ConfigUtils.getAblyKey();
      _realtime = ably.Realtime(
        options: ably.ClientOptions(key: ablyKey),
      );

      _channel = _realtime.channels.get('stylist:$_userId');

      _channel.subscribe(name: 'stylist_response').listen(
        (ably.Message message) {
          if (mounted) {
            try {
              final response = message.data as Map<String, dynamic>;
              setState(() {
                _messages.add(Message(
                  text: response['response'] as String,
                  isAI: true,
                  timestamp: DateTime.now(),
                ));
                _isLoading = false;
              });
            } catch (e) {
              print('Error processing message: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error processing response: $e')),
              );
              setState(() => _isLoading = false);
            }
          }
        },
        onError: (error) {
          print('Subscription error: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error receiving message: $error')),
            );
            setState(() => _isLoading = false);
          }
        },
      );

      // Only add welcome message if no messages exist
      if (_messages.isEmpty) {
        setState(() {
          _messages.add(Message(
            text: "Hi! I'm your AI stylist. I can help you with:\n"
                "• Outfit recommendations\n"
                "• Style advice\n"
                "• Color combinations\n"
                "• Shopping suggestions\n"
                "What would you like help with today?",
            isAI: true,
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      print('Error initializing Ably: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize chat: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    if (_isInitialized) {
      _channel.detach();
      _realtime.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null || _idToken == null) {
      return Scaffold(
        appBar: TopNavBar(),
        body: const Center(
          child: Text('Please log in to access the stylist'),
        ),
        bottomNavigationBar: BottomNavBar(),
      );
    }

    if (_isLoading && _messages.isEmpty) {
      return Scaffold(
        appBar: TopNavBar(),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: BottomNavBar(),
      );
    }

    return Scaffold(
      appBar: TopNavBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final message = _messages[index];
                return MessageBubble(
                  text: message.text,
                  isAI: message.isAI,
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: MessageInput(
              controller: _messageController,
              onSend: (text) {
                _sendMessage(text);
                _messageController.clear();
              },
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}

class Message {
  final String text;
  final bool isAI;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isAI,
    required this.timestamp,
  });
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isAI;

  const MessageBubble({
    required this.text,
    required this.isAI,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isAI ? Colors.grey[200] : Colors.deepOrange,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isAI ? Colors.black87 : Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final bool isLoading;

  const MessageInput({
    required this.controller,
    required this.onSend,
    required this.isLoading,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: "Ask your AI stylist anything...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide(color: Colors.deepOrange),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                enabled: !isLoading,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                isLoading ? Icons.hourglass_empty : Icons.send,
                color: Colors.deepOrange,
              ),
              onPressed: isLoading ? null : () => onSend(controller.text),
            ),
          ],
        ),
      ),
    );
  }
}
