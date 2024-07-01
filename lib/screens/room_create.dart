import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home_state.dart';

class RoomCreateScreen extends StatefulWidget {
  RoomCreateScreen({Key? key}) : super(key: key);

  @override
  _RoomCreateScreenState createState() => _RoomCreateScreenState();
}

class _RoomCreateScreenState extends State<RoomCreateScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> createRoom(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken') ?? '';
    print('Loaded jwtToken: $jwtToken');

    final headers = {'Content-Type': 'application/json'};
    if (jwtToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $jwtToken';
    }

        // 　 　＿＿＿　　　／￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣
        // 　／´∀｀;::::＼ ＜ おれの名はテレホマン。さすがにここは直さんといかんだろ。
        // /　　　　/::::::::::|　 ＼＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿
        // | ./|　　/:::::|::::::|
        // | |｜／::::::::|::::::|

    try {
    final response = await http.post(
      Uri.parse('https://abehiroto.com:10443/create'),
      // Uri.parse('http://localhost:8080/create'),
      headers: headers,
      body: jsonEncode({
        'nickname': _nicknameController.text,
        'roomTheme': '5x5_biased', // ルームテーマは固定
        // 'roomTheme': '3x3_biased', // ルームテーマは固定
        'subscriptionStatus': 'paid',
      }),
    );

    if (!mounted) return; // ここで画面がまだ存在しているか確認

    setState(() {
      _isLoading = false;
    });

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    final data = jsonDecode(response.body);

    // 新しいJWTトークンがレスポンスに含まれている場合、それを保存し、再度リクエストを送信
    if (data.containsKey('newToken')) {
      await prefs.setString('jwtToken', data['newToken']);
      print('Saved newToken: ${data['newToken']}');
      await createRoom(context); // 新しいトークンで再度リクエストを送信
      return;
    }

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Successfully Generated URL'),
      ));
      // 成功したら自動的にホーム画面に遷移
      Navigator.pushReplacementNamed(context, '/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to Generate URL. Status Code: ${response.statusCode}, Message: ${data['error']}'),
      ));
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    print('Error occurred: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Error Occurred: $e'),
    ));
  }
  }

  void reloadHomeScreen(BuildContext context) {
    Provider.of<HomeState>(context, listen: false).reloadHomeData(context);
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
                  title: Text('Obbsessed with Watermelon'),
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
        //title: Text('Generate Your Invitation URL'),
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
              "assets/cover.png", // 使用する背景画像のパス
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: _isLoading
                ? CircularProgressIndicator()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _nicknameController,
                          decoration: InputDecoration(
                            labelText: 'Your Nickname',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => createRoom(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 0, 44, 80), // ボタンの背景色
                          foregroundColor: Colors.white, // 文字の色
                        ),
                        child: Text('New Game'),
                      ),
                      // ElevatedButton(
                      //   onPressed: () => createRoom(context),
                      //   child: Text('Generate'),
                      // ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
