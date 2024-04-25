import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyRoomScreen extends StatefulWidget {
  MyRoomScreen({Key? key}) : super(key: key);

  @override
  _MyRoomScreenState createState() => _MyRoomScreenState();
}

class _MyRoomScreenState extends State<MyRoomScreen> {
  List<dynamic> challengers = [];
  String roomTheme = '';
  String gameState = '';
  String createdAt = '';
  String inviteUrl = ''; // 招待URLを保持するための変数
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRoomInfo();
  }

  Future<void> fetchRoomInfo() async {
    final response = await http.get(
      Uri.parse('https://api.yourserver.com/room/info'),
      headers: {'Authorization': 'Bearer your_jwt_token_here'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        roomTheme = data['roomTheme'];
        gameState = data['gameState'];
        createdAt = data['created_at'];
        challengers = data['challengers'];
        inviteUrl = 'https://api.yourserver.com/challenger/create/${data['uniqueToken']}';
        isLoading = false;
      });
    } else {
      // エラーハンドリング
      print('Failed to load room info');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ルーム管理画面')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Text('テーマ: $roomTheme'),
                Text('状態: $gameState'),
                Text('作成日: $createdAt'),
                Text('招待URL: $inviteUrl'),
                Expanded(
                  child: ListView.builder(
                    itemCount: challengers.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(challengers[index]['challengerNickname']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.check),
                              onPressed: () => replyToChallenge(challengers[index]['id'], 'accepted'),
                            ),
                            IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () => replyToChallenge(challengers[index]['id'], 'rejected'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void replyToChallenge(String visitorId, String status) async {
    final response = await http.put(
      Uri.parse('https://api.yourserver.com/request/reply'),
      headers: {'Authorization': 'Bearer your_jwt_token_here', 'Content-Type': 'application/json'},
      body: jsonEncode({'visitorId': visitorId, 'status': status}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('返信が成功しました'),
      ));
      fetchRoomInfo(); // 状態を更新するために部屋の情報を再取得
    } else {
      // エラーハンドリング
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('返信に失敗しました'),
      ));
    }
  }

  // ルーム削除のコードも作成
}