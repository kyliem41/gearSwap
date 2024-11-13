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
  bool _isConnecting = false;

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
            const SnackBar(
                content: Text('Please log in to access the stylist')),
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (_userId == null || _idToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to send messages')),
      );
      return;
    }

    final timestamp = DateTime.now();
    final userMessage = Message(
      text: text,
      isAI: false,
      timestamp: timestamp,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    try {
      print('Sending message to backend...');
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

      print('Backend response status: ${response.statusCode}');
      print('Backend response body: ${response.body}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to send message');
      }

      // Start a timeout timer
      Future.delayed(const Duration(seconds: 30), () {
        if (_isLoading && mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Response timeout - please try again')),
          );
        }
      });
    } catch (e) {
      print('Error sending message: $e');
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
    if (_userId == null || _isConnecting) return;

    setState(() => _isConnecting = true);

    try {
      print('Initializing Ably for user: $_userId');
      final ablyKey = await ConfigUtils.getAblyKey();
      print('Got Ably key, creating client...');

      _realtime = ably.Realtime(
        options: ably.ClientOptions(
          key: ablyKey,
          clientId: 'stylist_$_userId',
          logLevel: ably.LogLevel.verbose,
          autoConnect: true,
          environment: 'production',
          useBinaryProtocol: true,
        ),
      );

      _realtime.connection.on().listen(
          (ably.ConnectionStateChange stateChange) {
        print('Ably connection state changed to: ${stateChange.current}');
        if (mounted) {
          setState(() {
            if (stateChange.current == ably.ConnectionState.failed) {
              print('Connection failed: ${stateChange.reason}');
              _isInitialized = false;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Connection failed - retrying...')),
              );
              _retryConnection();
            } else if (stateChange.current == ably.ConnectionState.connected) {
              _isInitialized = true;
            }
          });
        }
      }, onError: (error) {
        print('Connection state error: $error');
        _retryConnection();
      });

      String channelName = 'stylist:$_userId';
      print('Creating channel: $channelName');
      _channel = _realtime.channels.get(channelName);

      // Listen for channel state changes
      _channel.on().listen((ably.ChannelStateChange stateChange) {
        print('Channel state changed to: ${stateChange.current}');
        if (stateChange.current == ably.ChannelState.failed) {
          _retryConnection();
        }
      }, onError: (error) {
        print('Channel state error: $error');
        _retryConnection();
      });

      print('Subscribing to channel...');
      await _channel.attach();

      _channel.subscribe(name: 'stylist_response').listen(
        (ably.Message message) {
          print('Received message from Ably: ${message.data}');
          if (mounted) {
            try {
              final response = message.data as Map<String, dynamic>;
              setState(() {
                _messages.add(Message(
                  text: response['response'] as String,
                  isAI: true,
                  timestamp: DateTime.parse(response['timestamp']),
                  model: response['model'],
                  type: response['type'],
                ));
                _isLoading = false;
              });
            } catch (e) {
              print('Error processing message: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error processing response: $e')),
                );
              }
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

      print('Successfully attached to channel');
    } catch (e) {
      print('Error initializing Ably: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize chat: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _retryConnection() async {
    if (!_isConnecting && mounted) {
      await Future.delayed(Duration(seconds: 2)); // Wait before retrying
      _initializeAbly();
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
          if (_isInitialized)
            ConnectionStateWidget(
              state: _realtime.connection.state,
            ),
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

  const MessageBubble({
    required this.text,
    required this.isAI,
    this.model,
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
            child: Text(
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

class ConnectionStateWidget extends StatelessWidget {
  final ably.ConnectionState state;

  const ConnectionStateWidget({
    required this.state,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (state) {
      case ably.ConnectionState.connected:
        color = Colors.green;
        text = 'Connected';
        break;
      case ably.ConnectionState.connecting:
        color = Colors.orange;
        text = 'Connecting...';
        break;
      case ably.ConnectionState.disconnected:
        color = Colors.red;
        text = 'Disconnected';
        break;
      case ably.ConnectionState.failed:
        color = Colors.red;
        text = 'Connection Failed';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
