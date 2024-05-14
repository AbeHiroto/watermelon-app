import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'myRoom.dart';

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

    final response = await http.post(
      Uri.parse('http://localhost:8080/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nickname': _nicknameController.text,
        // 他に必要なデータがあればここに追加します
      }),
    );

    if (!mounted) return;  // ここで画面がまだ存在しているか確認

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('招待URLが正常に作成されました。'),
      ));
      // 成功したら自動的にルーム管理画面に遷移
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyRoomScreen()),  // 修正: 直接 MyRoomScreen インスタンスを生成
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('招待URL作成に失敗しました。'),
      ));
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
