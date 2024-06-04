import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
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
    print('Loaded jwtToken: $jwtToken');

    final headers = {'Content-Type': 'application/json'};
    if (jwtToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $jwtToken';
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/create'),
        headers: headers,
        body: jsonEncode({
          'nickname': _nicknameController.text,
          'roomTheme': '3x3_biased', // ルームテーマを固定
          'subscriptionStatus': 'paid',
        }),
      );

      if (!mounted) return; // ここで画面がまだ存在しているか確認

      setState(() {
        _isLoading = false;
      });

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 新しいJWTトークンがレスポンスに含まれている場合、それを保存
        if (data.containsKey('newToken')) {
          await prefs.setString('jwtToken', data['newToken']);
          print('Saved newToken: ${data['newToken']}');
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('招待URLが正常に作成されました。'),
        ));
        // 成功したら自動的にホーム画面に遷移
        Navigator.pushReplacementNamed(context, '/');
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('招待URL作成に失敗しました。ステータスコード: ${response.statusCode}, メッセージ: ${data['error']}'),
        ));

        // 新しいJWTトークンがレスポンスに含まれている場合、それを保存
        if (data.containsKey('newToken')) {
          await prefs.setString('jwtToken', data['newToken']);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('リクエスト中にエラーが発生しました: $e'),
      ));
    }
  }

  void reloadHomeScreen(BuildContext context) {
    Provider.of<HomeState>(context, listen: false).reloadHomeData(context);
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
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: reloadHomeScreen,
                    child: Text('ホーム画面をリロード'),
                  ),
                ],
              ),
      ),
    );
  }
}
