import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MyRoomScreen extends StatefulWidget {
  MyRoomScreen({Key? key}) : super(key: key);

  @override
  _MyRoomScreenState createState() => _MyRoomScreenState();
}

class _MyRoomScreenState extends State<MyRoomScreen> {
  bool isLoading = true;
  Map<String, dynamic>? roomData;

  @override
  void initState() {
    super.initState();
    fetchRoomInfo();
  }

  Future<void> fetchRoomInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken') ?? '';

    final response = await http.get(
      Uri.parse('http://localhost:8080/room/info'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // challengers が null の場合に空のリストに設定
      for (var room in data['rooms']) {
        room['challengers'] = room['challengers'] ?? [];
      }

      // デバッグ用にレスポンスデータをプリントアウト
      print(data);

      setState(() {
      roomData = data['rooms'].isNotEmpty ? data['rooms'][0] : null;
      isLoading = false;
      });
    } else {
      // エラーハンドリング
      print('Failed to load room info');
      setState(() {
        isLoading = false;
      });
    }
  }

  void replyToChallenge(int visitorId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken') ?? '';

    print('Replying to challenge with status: $status for visitorId: $visitorId');

    final response = await http.put(
      Uri.parse('http://localhost:8080/request/reply'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'visitorId': visitorId,
        'status': status,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('返信が成功しました'),
      ));
      fetchRoomInfo(); // 状態を更新するために部屋の情報を再取得
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('返信に失敗しました'),
      ));
    }
  }

  void deleteRoom() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken') ?? '';

    final response = await http.delete(
      Uri.parse('http://localhost:8080/room'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('ルームが正常に削除されました'),
      ));
      Navigator.pop(context); // ルーム削除後にホーム画面に戻る
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('ルームの削除に失敗しました'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('招待URL/Invitation URL'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : roomData == null
              ? Center(child: Text('ルーム情報を読み込めませんでした'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Theme: ${roomData!['roomTheme']}'),
                          Text('State: ${roomData!['gameState']}'),
                          Text('Available Since: ${roomData!['createdAt']}'),
                          Text('URL: https://yourserver.com/challenger/create/${roomData!['uniqueToken']}'),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: deleteRoom,
                            child: Text('ルームを削除する'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: (roomData!['challengers'] as List).length,
                        itemBuilder: (context, index) {
                          final challenger = roomData!['challengers'][index];
                          final visitorId = challenger['visitorId'] as int;  // visitorIdをintとして処理
                          return ListTile(
                            title: Text(challenger['challengerNickname']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check),
                                  onPressed: () {
                                    print('Accepted button pressed');
                                    replyToChallenge(visitorId, 'accepted');
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () {
                                    print('Rejected button pressed');
                                    replyToChallenge(visitorId, 'rejected');
                                  },
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
}
