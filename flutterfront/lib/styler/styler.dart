import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:sample/appBars/bottomNavBar.dart';
import 'package:sample/appBars/topNavBar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sample/shared/config_utils.dart';

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
  WebSocketChannel? _channel;
  bool _isConnected = false;
  StreamSubscription? _wsSubscription;

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
      final wsUrl = await ConfigUtils.getWebSocketUrl();
      final isAuthenticated = await _loadUserData();

      if (!isAuthenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please log in to access the stylist')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      await _loadChatHistory();
      await _connectWebSocket(wsUrl);

      setState(() {
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

  Future<void> _connectWebSocket(String wsBaseUrl) async {
    if (_channel != null) {
      await _wsSubscription?.cancel();
      _channel?.sink.close();
    }

    try {
      final wsUrl = Uri.parse('$wsBaseUrl?token=$_idToken');
      print('Connecting to WebSocket: $wsUrl');

      // Connect to WebSocket
      _channel = WebSocketChannel.connect(wsUrl);

      await _channel?.ready;
      print('WebSocket connection established');

      _wsSubscription = _channel?.stream.listen(
        (message) {
          print('WebSocket message received: $message');
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          print('WebSocket stream error: $error');
          _handleWebSocketError(error);
        },
        onDone: () {
          print('WebSocket connection closed by server');
          _handleWebSocketDone();
        },
      );

      setState(() => _isConnected = true);
    } catch (e) {
      print('WebSocket connection error: $e');
      _handleWebSocketError(e);
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      print('Received WebSocket message: $message');
      final data = json.decode(message as String);
      print('Decoded message data: $data');

      if (data['error'] != null) {
        print('Error from server: ${data['error']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${data['error']}')),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (data['type'] == 'stylist_response') {
        setState(() {
          _messages.add(Message(
            text: data['response'],
            isAI: true,
            timestamp: DateTime.parse(data['timestamp']),
            model: data['model'],
            type: data['type'],
          ));
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
      setState(() => _isLoading = false);
    }
  }

  void _handleWebSocketError(dynamic error) {
    print('WebSocket error: $error');
    setState(() => _isConnected = false);
    _reconnectWebSocket();
  }

  void _handleWebSocketDone() {
    print('WebSocket connection closed');
    setState(() => _isConnected = false);
    _reconnectWebSocket();
  }

  Future<void> _reconnectWebSocket() async {
    if (!_isConnected) {
      await Future.delayed(const Duration(seconds: 2));
      final wsUrl = await ConfigUtils.getWebSocketUrl();
      await _connectWebSocket(wsUrl);
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (_channel == null || !_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Not connected to chat service. Attempting to reconnect...')),
      );
      await _reconnectWebSocket();
      if (!_isConnected) return;
    }

    setState(() {
      _messages.add(Message(
        text: text,
        isAI: false,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    try {
      final message = {
        'action': 'sendMessage',
        'message': text,
        'type': _determineMessageType(text),
        'context': _getLastMessages(3),
      };
      print(
          'Preparing to send WebSocket message with action: ${message['action']}');
      print('Full message payload: ${json.encode(message)}');

      _channel?.sink.add(json.encode(message));
      print('Message sent successfully through WebSocket');
    } catch (e) {
      print('Error sending message: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
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
                text: msg['message'] ?? msg['response'] ?? '',
                isAI: msg['type'] == 'ai',
                timestamp: DateTime.parse(msg['timestamp']),
                model: msg['model'],
                type: msg['type'],
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

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _channel?.sink.close();
    _messageController.dispose();
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
        bottomNavigationBar: BottomNavBar(
          currentIndex: 3,
        ),
      );
    }

    if (_isLoading && _messages.isEmpty) {
      return Scaffold(
        appBar: TopNavBar(),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 3,
        ),
      );
    }

    return Scaffold(
      appBar: TopNavBar(),
      body: Column(
        children: [
          //connection status
          Container(
            padding: const EdgeInsets.all(8),
            color: _isConnected ? Colors.green[100] : Colors.red[100],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isConnected ? Icons.check_circle : Icons.error,
                  color: _isConnected ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return MessageBubble(
                    text: '',
                    isAI: true,
                    model: 'Assistant',
                    isTyping: true,
                  );
                }
                final message = _messages[index];
                return MessageBubble(
                  text: message.text,
                  isAI: message.isAI,
                  model: message.model,
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
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
      ),
    );
  }
}

class Message {
  final String text;
  final bool isAI;
  final DateTime timestamp;
  final String? model;
  final String? type;

  Message({
    required this.text,
    required this.isAI,
    required this.timestamp,
    this.model,
    this.type,
  });
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isAI;
  final String? model;
  final bool isTyping;

  const MessageBubble({
    required this.text,
    required this.isAI,
    this.model,
    this.isTyping = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Column(
        crossAxisAlignment:
            isAI ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAI && model != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
              child: Text(
                'AI ($model)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          Container(
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
            child: isTyping
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDot(0),
                      _buildDot(1),
                      _buildDot(2),
                    ],
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: isAI ? Colors.black87 : Colors.white,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600),
      builder: (context, double value, child) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 2),
          child: Opacity(
            opacity: (value + (index * 0.2)) % 1.0,
            child: const Text(
              '•',
              style: TextStyle(fontSize: 24, color: Colors.black54),
            ),
          ),
        );
      },
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
        color: Color(0xFFFFFBF5),
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
