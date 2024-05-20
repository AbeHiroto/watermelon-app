import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

  void createRoom(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken') ?? '';

    final headers = {'Content-Type': 'application/json'};
    if (jwtToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $jwtToken';
    }

    final response = await http.post(
    Uri.parse('http://localhost:8080/create'),
    headers: headers,
    body: jsonEncode({
      'nickname': _nicknameController.text,
      'roomTheme': '3x3_biased', // ルームテーマを固定
    }),
  );

    if (!mounted) return;  // ここで画面がまだ存在しているか確認

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // 新しいJWTトークンがレスポンスに含まれている場合、それを保存
      if (data.containsKey('newToken')) {
        await prefs.setString('jwtToken', data['newToken']);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('招待URLが正常に作成されました。'),
      ));
      // 成功したら自動的にホーム画面に遷移
      Navigator.pushReplacementNamed(context, '/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('招待URL作成に失敗しました。'),
      ));

      final data = jsonDecode(response.body);

      // 新しいJWTトークンがレスポンスに含まれている場合、それを保存
      if (data.containsKey('newToken')) {
        await prefs.setString('jwtToken', data['newToken']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('招待URL作成'),
      ),
      body: Center(
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
                        labelText: 'あなたのニックネーム',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => createRoom(context),
                    child: Text('招待URLを発行する'),
                  ),
                ],
              ),
      ),
    );
  }
}
