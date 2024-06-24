import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class InviteScreen extends StatefulWidget {
  final String uniqueToken;

  const InviteScreen({Key? key, required this.uniqueToken}) : super(key: key);

  @override
  _InviteScreenState createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  bool _isLoading = false;
  String roomCreator = '';
  String roomTheme = '';

  @override
  void initState() {
    super.initState();
    fetchRoomInfo();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> fetchRoomInfo() async {
    setState(() {
      _isLoading = true;
    });

    final response = await http.get(
      Uri.parse('http://localhost:8080/play/${widget.uniqueToken}'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        roomCreator = data['roomCreator'];
        roomTheme = data['roomTheme'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('ルーム情報の取得に失敗しました。'),
      ));
    }
  }

  Future<void> submitChallenge(BuildContext context) async {
    if (_nicknameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Enter Your Nickname'),
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    String jwtToken = prefs.getString('jwtToken') ?? '';

    final headers = {'Content-Type': 'application/json'};
    if (jwtToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $jwtToken';
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/challenger/create/${widget.uniqueToken}'),
        headers: headers,
        body: jsonEncode({
          'nickname': _nicknameController.text,
          'subscriptionStatus': 'paid', // 課金ステータスが必要であれば設定
        }),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      // 新しいJWTトークンがレスポンスに含まれている場合、それを保存し、再度リクエストを送信
      if (data.containsKey('newToken')) {
        await prefs.setString('jwtToken', data['newToken']);
        print('Saved newToken: ${data['newToken']}');
        await submitChallenge(context); // 新しいトークンで再度リクエストを送信
        return;
      }

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Request sent successfully'),
        ));
        // 対戦申請後にホーム画面に遷移
        Navigator.pushReplacementNamed(context, '/');
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Fail to Send Request. Status Code: ${response.statusCode}, Message: ${data['error']}'),
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
    // final response = await http.post(
    //   Uri.parse('http://localhost:8080/challenger/create/${widget.uniqueToken}'),
    //   headers: headers,
    //   body: jsonEncode({
    //     'nickname': _nicknameController.text,
    //     'subscriptionStatus': 'paid', // 課金ステータスが必要であれば設定
    //   }),
    // );

    // if (response.statusCode == 201) {
    //   final data = jsonDecode(response.body);
    //   if (data.containsKey('newToken')) {
    //     await prefs.setString('jwtToken', data['newToken']);
    //     print('Saved newToken: ${data['newToken']}');
    //     jwtToken = data['newToken'];
    //   }
      
    //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //     content: Text('Request sent successfully'),
    //   ));
    //   // 対戦申請後にホーム画面に遷移
    //   Navigator.pushReplacementNamed(context, '/');
    // } else {
    //   final data = jsonDecode(response.body);

    //   // 新しいJWTトークンがレスポンスに含まれている場合、それを保存
    //   if (data.containsKey('newToken')) {
    //     await prefs.setString('jwtToken', data['newToken']);
    //     print('Saved newToken: ${data['newToken']}');
    //   }

    //   setState(() {
    //     _isLoading = false;
    //   });
    //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //     content: Text('Fail to Send Request'),
    //   ));
    // }
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
        title: Text('Request Matching'),
        actions: [
          IconButton(
            icon: Icon(Icons.warning),
            onPressed: _showResetConfirmationDialog,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Opponent: $roomCreator'),
                  Text('Theme: $roomTheme'),
                  SizedBox(height: 20),
                  TextField(
                    controller: _nicknameController,
                    decoration: InputDecoration(
                      labelText: 'Your Nickname',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => submitChallenge(context),
                    child: Text('Submit'),
                  ),
                ],
              ),
            ),
    );
  }
}
