import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MyRequestScreen extends StatefulWidget {
  const MyRequestScreen({Key? key}) : super(key: key);

  @override
  _MyRequestScreenState createState() => _MyRequestScreenState();
}

class _MyRequestScreenState extends State<MyRequestScreen> {
  Future<List<dynamic>>? _requestInfo;

  @override
  void initState() {
    super.initState();
    _requestInfo = fetchRequestInfo();
  }

  Future<List<dynamic>> fetchRequestInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken') ?? '';

      // 　 　＿＿＿　　　／￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣
      // 　／´∀｀;::::＼ ＜ おれの名はテレホマン。さすがにここは直さんといかんだろ。
      // /　　　　/::::::::::|　 ＼＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿
      // | ./|　　/:::::|::::::|
      // | |｜／::::::::|::::::|

    final response = await http.get(
      Uri.parse('https://abehiroto.com:10443/request/info'),
      //Uri.parse('http://localhost:8080/request/info'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['requests'];
    } else {
      throw Exception('Failed to load request info');
    }
  }

  Future<void> disableMyRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken') ?? '';

      // 　 　＿＿＿　　　／￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣
      // 　／´∀｀;::::＼ ＜ おれの名はテレホマン。さすがにここは直さんといかんだろ。
      // /　　　　/::::::::::|　 ＼＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿
      // | ./|　　/:::::|::::::|
      // | |｜／::::::::|::::::|

    final response = await http.delete(
      Uri.parse('https://abehiroto.com:10443/request/disable'),
      //Uri.parse('http://localhost:8080/request/disable'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Requests successfully disabled')),
      );
      setState(() {
        _requestInfo = fetchRequestInfo();  // Refresh the list
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to disable requests')),
      );
    }
  }

  void _clearJwtAndSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwtToken');
    await prefs.remove('sessionId');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('JWT and Session ID cleared'),
    ));
    Navigator.pushReplacementNamed(context, '/');
  }

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reset App?'),
          content: Text('If you reset this App, your invitation URL and accepted request will be disposed. Are you sure?'),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Reset'),
              onPressed: () {
                Navigator.of(context).pop();
                _clearJwtAndSessionId();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpeechBubble(String text) {
    return CustomPaint(
      painter: SpeechBubblePainter(color: Colors.white),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: IconButton(
          icon: Icon(Icons.info_outline),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Obsessed with Watermelon'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('This App is not too political🍉'),
                      SizedBox(height: 8),
                      Text('© 2024 Hiroto Abe. All rights reserved.'),
                    ],
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: Text('Close'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.warning_amber_outlined),
            onPressed: _showResetConfirmationDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/my_request.png', // 背景画像のパス
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              color: Color.fromARGB(255, 0, 18, 46), // ネイビー背景
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: TextButton(
                onPressed: disableMyRequest,
                child: Text(
                  'Disable Request',
                  style: TextStyle(
                    color: Colors.white, // 白文字
                    fontSize: 18.0,
                  ),
                ),
              ),
            ),
          ),
          FutureBuilder<List<dynamic>>(
            future: _requestInfo,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                final pendingRequest = snapshot.data!.firstWhere(
                    (request) => request['status'] == 'pending',
                    orElse: () => null);

                if (pendingRequest == null) {
                  return Center(child: Text('No pending requests'));
                } else {
                  return Align(
                    alignment: Alignment(0.0, -0.2), // 中央より少し上に配置
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildSpeechBubble(
                          'Waiting for ${pendingRequest['roomCreator']}...'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class SpeechBubblePainter extends CustomPainter {
  final Color color;

  SpeechBubblePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    var path = Path()
      ..moveTo(size.width * 0.05, 0) // Start at the top-left corner with a small inset for the curve
      ..lineTo(0, size.height * 0.05)
      ..quadraticBezierTo(0, 0, size.width * 0.05, 0) // Top-left corner curve
      ..lineTo(size.width * 0.95, 0)
      ..quadraticBezierTo(size.width, 0, size.width, size.height * 0.05) // Top-right corner curve
      ..lineTo(size.width, size.height * 0.95)
      ..quadraticBezierTo(size.width, size.height, size.width * 0.95, size.height) // Bottom-right corner curve
      ..lineTo(size.width * 0.05, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height * 0.95) // Bottom-left corner curve
      ..lineTo(0, size.height * 0.05)
      ..quadraticBezierTo(0, 0, size.width * 0.05, 0) // Top-left corner curve
      ..close();

    // 吹き出しの尻尾を追加
    path.moveTo(size.width * 0.7, size.height);
    path.lineTo(size.width * 0.45, size.height + 10);
    path.lineTo(size.width * 0.55, size.height);

    // 影を描画
    canvas.drawShadow(path, Colors.black.withOpacity(0.5), 4.0, true);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}