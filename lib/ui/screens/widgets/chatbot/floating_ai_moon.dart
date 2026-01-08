import 'dart:async';
import 'dart:convert';

import 'package:Tijaraa/ui/screens/widgets/chatbot/TijaraaBotService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatAiMessage {
  final String text;
  final bool isUser;

  ChatAiMessage({required this.text, required this.isUser});

  Map<String, dynamic> toJson() => {'text': text, 'isUser': isUser};
  factory ChatAiMessage.fromJson(Map<String, dynamic> json) =>
      ChatAiMessage(text: json['text'], isUser: json['isUser']);
}

// Global key to control drawer from anywhere
final GlobalKey<ScaffoldState> mainScaffoldKey = GlobalKey<ScaffoldState>();

class FloatingAIMoon extends StatefulWidget {
  const FloatingAIMoon({super.key});

  @override
  State<FloatingAIMoon> createState() => _FloatingAIMoonState();
}

class _FloatingAIMoonState extends State<FloatingAIMoon>
    with WidgetsBindingObserver {
  double bottom = 120;
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Handle lifecycle changes if needed
  }

  void _openChatDrawer() {
    final scaffoldState = mainScaffoldKey.currentState;
    if (scaffoldState != null) {
      scaffoldState.openEndDrawer();
      setState(() => unreadCount = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      right: -14,
      bottom: bottom,
      child: _moonDraggable(),
    );
  }

  Widget _moonDraggable() {
    return Draggable(
      axis: Axis.vertical,
      feedback: _moonBody(),
      childWhenDragging: const SizedBox(),
      onDragEnd: (d) {
        setState(() {
          bottom = MediaQuery.of(context).size.height - d.offset.dy - 80;
        });
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openChatDrawer,
        child: Stack(
          children: [
            RepaintBoundary(child: _moonBody()),
            if (unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _moonBody() {
    return Container(
      height: 60,
      width: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xff6a11cb), Color(0xff2575fc)],
        ),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: const Center(
        child: Icon(Icons.smart_toy, color: Colors.white, size: 26),
      ),
    );
  }
}

// Chat Drawer Widget
class AIChatDrawer extends StatefulWidget {
  const AIChatDrawer({super.key});

  @override
  State<AIChatDrawer> createState() => _AIChatDrawerState();
}

class _AIChatDrawerState extends State<AIChatDrawer>
    with WidgetsBindingObserver {
  late FocusNode _inputFocus;
  late TextEditingController _controller;
  late ScrollController _scrollCtrl;
  final TijaraaBotService _botService = TijaraaBotService();
  final List<ChatAiMessage> _messages = [];
  bool _isTyping = false;
  bool _isInitialized = false;
  bool _isUserTyping = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _listening = false;

  // Key for SharedPreferences
  static const String _chatMessagesKey = 'chat_messages';
  List<String> _currentSuggestions = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inputFocus = FocusNode();
    _controller = TextEditingController();
    _scrollCtrl = ScrollController();
    TijaraaBotService().loadBotData();
    // Listen to keyboard visibility changes
    _inputFocus.addListener(_onFocusChange);

    // Load messages when the widget is initialized
    _loadMessages();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inputFocus.removeListener(_onFocusChange);
    _inputFocus.dispose();
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        // App is not visible but still running - save messages
        _saveMessages();
        break;
      case AppLifecycleState.resumed:
        // App is visible and responding to user input - load messages
        _loadMessages();
        break;
      case AppLifecycleState.detached:
        // App is about to be terminated - clear messages
        _clearMessages();
        break;
      case AppLifecycleState.inactive:
        // App is in an inactive state - save messages
        _saveMessages();
        break;
      case AppLifecycleState.hidden:
        // App is hidden - save messages
        _saveMessages();
        break;
    }
  }

  // Load messages from SharedPreferences
  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getStringList(_chatMessagesKey) ?? [];

      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(
            messagesJson.map(
              (json) => ChatAiMessage.fromJson(jsonDecode(json)),
            ),
          );
          _isInitialized = true;
        });
      }
    } catch (e) {
      // If there's an error loading messages, just continue with empty list
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  // Save messages to SharedPreferences
  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = _messages
          .map((msg) => jsonEncode(msg.toJson()))
          .toList();
      await prefs.setStringList(_chatMessagesKey, messagesJson);
    } catch (e) {
      // If there's an error saving, just continue
      print('Error saving messages: $e');
    }
  }

  // Clear messages from SharedPreferences
  Future<void> _clearMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chatMessagesKey);
    } catch (e) {
      // If there's an error clearing, just continue
      print('Error clearing messages: $e');
    }
  }

  void _onFocusChange() {
    if (_inputFocus.hasFocus) {
      // Scroll to bottom when keyboard appears
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToBottom();
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatAiMessage(text: text, isUser: true));
      _isTyping = true;
      _currentSuggestions =
          []; // Clear suggestions when user sends a new message
    });

    _scrollToBottom();

    final BotResponse response = _botService.getReply(text);
    final String botReply = response.text;

    int delayMs = (botReply.length * 20).clamp(600, 1500);
    await Future.delayed(Duration(milliseconds: delayMs));

    if (mounted) {
      setState(() {
        _messages.add(ChatAiMessage(text: botReply, isUser: false));
        _isTyping = false;
        // Store suggestions from the bot response
        _currentSuggestions = response.suggestions;
      });
      _scrollToBottom();
      _saveMessages();
    }
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (!available) return;

    setState(() => _listening = true);
    _speech.listen(
      onResult: (r) {
        _controller.text = r.recognizedWords;
      },
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _listening = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // FIX 1: Get keyboard height to adjust input bar position
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final drawerWidth = MediaQuery.of(context).size.width * 0.8;

    // FIX 2: Set status bar color to match app bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xff6a11cb), // Match gradient start color
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Drawer(
      width: drawerWidth,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFf5f7fa), Color(0xFFc3cfe2)],
          ),
        ),
        // FIX 3: Remove SafeArea to extend to status bar
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                // FIX 4: Add bottom padding when keyboard is open
                padding: EdgeInsets.only(bottom: keyboardHeight),
                child: _buildMessageList(),
              ),
            ),
            if (_isTyping) _buildTypingIndicator(),
            _buildSuggestions(),
            // FIX 5: Input bar moves with keyboard
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              transform: Matrix4.translationValues(0, -keyboardHeight, 0),
              child: _buildInputBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_currentSuggestions.isEmpty || _isTyping)
      return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _currentSuggestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: Text(
                _currentSuggestions[index],
                style: const TextStyle(color: Color(0xff6a11cb), fontSize: 13),
              ),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xff6a11cb)),
              shape: StadiumBorder(),
              onPressed: () => _sendMessage(_currentSuggestions[index]),
            ),
          );
        },
      ),
    );
  }

  void _handleClearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear Conversation?"),
        content: const Text(
          "This will delete all messages and cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _currentSuggestions = [];
              });
              _clearMessages(); // Wipes SharedPreferences
              Navigator.pop(context);
            },
            child: const Text("Clear", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      // FIX 6: Add top padding for status bar
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff6a11cb), Color(0xff2575fc)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Container(
          //   padding: const EdgeInsets.all(8),
          //   decoration: BoxDecoration(
          //     color: Colors.white.withOpacity(0.2),
          //     borderRadius: BorderRadius.circular(12),
          //   ),
          //   child: IgnorePointer(
          //     child: Lottie.asset(
          //       'assets/ai.json',
          //       width: 46,
          //       height: 46,
          //       repeat: true,
          //       animate: _isTyping || _isUserTyping,
          //       // ✅ ONLY when AI is typing
          //       frameRate: FrameRate.max,
          //     ),
          //   ),
          // ),
          // const SizedBox(width: 8),
          const Expanded(
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tijaraa AI Assistant",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Always here to help",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white70),
            tooltip: 'Clear Chat',
            onPressed: _handleClearChat,
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () {
              // Unfocus keyboard before closing
              _inputFocus.unfocus();
              // Save messages before closing
              _saveMessages();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 60,
                color: Color(0xff6a11cb),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Start a conversation!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xff6a11cb),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Ask me anything about Tijaraa",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        return _buildMessageBubble(msg);
      },
    );
  }

  Widget _buildMessageBubble(ChatAiMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        decoration: BoxDecoration(
          gradient: msg.isUser
              ? const LinearGradient(
                  colors: [Color(0xff6a11cb), Color(0xff2575fc)],
                )
              : null,
          color: msg.isUser ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(msg.isUser ? 20 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTypingDot(0),
              const SizedBox(width: 4),
              _buildTypingDot(1),
              const SizedBox(width: 4),
              _buildTypingDot(2),
              const SizedBox(width: 8),
              Text(
                "Thinking...",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, double value, child) {
        final delay = index * 0.2;
        final animValue = (value - delay).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, -4 * animValue),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xff6a11cb).withOpacity(0.3 + 0.5 * animValue),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // IconButton(
            //   icon: Icon(
            //     _listening ? Icons.mic : Icons.mic_none,
            //     color: _listening ? Colors.red : const Color(0xff6a11cb),
            //   ),
            //   onPressed: _listening ? _stopListening : _startListening,
            // ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  focusNode: _inputFocus,
                  controller: _controller,
                  textInputAction: TextInputAction.send,

                  onChanged: (value) {
                    setState(() {
                      _isUserTyping = value.trim().isNotEmpty;
                    });
                  },

                  onSubmitted: (v) {
                    if (v.trim().isNotEmpty) {
                      _sendMessage(v);
                      _controller.clear();
                      setState(() => _isUserTyping = false);
                      _inputFocus.requestFocus();
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: "Ask me anything...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff6a11cb), Color(0xff2575fc)],
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () {
                  if (_controller.text.trim().isNotEmpty) {
                    _sendMessage(_controller.text);
                    _controller.clear();
                    // Keep focus for continuous typing
                    _inputFocus.requestFocus();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
