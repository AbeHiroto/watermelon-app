import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

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

  void showDeleteConfirmationDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Dispose URL?"),
        actions: <Widget>[
          TextButton(
            child: Text("Close"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text("Dispose"),
            onPressed: () {
              Navigator.of(context).pop(); // モーダルを閉じる
              deleteRoom(); // ルーム削除を実行
            },
          ),
        ],
      );
    },
  );
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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('URL copied to clipboard'),
    ));
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
        title: Text('Invitate Your Friend'),
        actions: [
          IconButton(
            icon: Icon(Icons.warning),
            onPressed: _showResetConfirmationDialog,
          ),
        ],
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
                          Center(
                            child: Column(
                              children: [
                                QrImageView(
                                  data: "https://demo.com/bribe/play/${roomData!['uniqueToken']}",
                                  version: QrVersions.auto,
                                  size: 240.0,
                                ),
                                SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('https://demo.com/bribe/play/${roomData!['uniqueToken']}'),
                                    IconButton(
                                      icon: Icon(Icons.copy),
                                      onPressed: () {
                                        _copyToClipboard("https://demo.com/bribe/play/${roomData!['uniqueToken']}");
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: showDeleteConfirmationDialog, // 確認ダイアログを表示
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(), // 水平線
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
