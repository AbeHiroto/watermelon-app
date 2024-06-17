import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/html.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late WebSocketChannel channel;
  String message = "";
  List<List<String>> board = List.generate(3, (_) => List.generate(3, (_) => ''));
  String currentTurn = "";
  String refereeStatus = "normal";
  int biasDegree = 0;
  List<int> bribeCounts = [0, 0];
  List<String> chatMessages = [];
  TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken') ?? '';
    String sessionId = prefs.getString('sessionId') ?? '';

    if (jwtToken.isNotEmpty) {
      _connectWebSocket(jwtToken, sessionId);
    } else {
      print("JWT token is missing");
    }
  }

  Future<void> _connectWebSocket(String jwtToken, String sessionId) async {
    try {
      final url = 'ws://localhost:8080/ws?token=$jwtToken&sessionID=$sessionId';
      if (kIsWeb) {
        channel = HtmlWebSocketChannel.connect(url);
      } else {
        channel = IOWebSocketChannel.connect(Uri.parse(url));
      }
  
      channel.stream.listen((data) {
        handleMessage(data);
      }, onError: (error) async {
        print("WebSocket connection error: $error");
      });
    } catch (e) {
      print("Failed to connect to WebSocket: $e");
    }
  }

  Future<void> saveSessionId(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sessionId', sessionId);
  }

  @override
  void dispose() {
    channel.sink.close();
    _textController.dispose();
    super.dispose();
  }

  void handleMessage(dynamic data) {
    try {
      final decodedData = jsonDecode(data);
      if (decodedData.containsKey('sessionID')) {
        saveSessionId(decodedData['sessionID']);
        print('New session ID saved: ${decodedData['sessionID']}');
      } else {
        switch (decodedData['type']) {
          case 'gameState':
            setState(() {
              board = (decodedData['board'] as List<dynamic>)
                .map((row) => (row as List<dynamic>).map((cell) => cell as String).toList())
                .toList();
              //board = List<List<String>>.from(decodedData['board']);
              currentTurn = decodedData['currentPlayer'] ?? "Unknown";
              refereeStatus = decodedData['refereeStatus'];
              biasDegree = decodedData['biasDegree'] ?? 0;
              bribeCounts = (decodedData['bribeCounts'] as List<dynamic>)
                .map((count) => count ?? 0) // null を 0 に置き換える
                .cast<int>()
                .toList();
            });
            break;
          case 'chatMessage':
            setState(() {
              chatMessages.add(decodedData['message']);
              if (chatMessages.length > 3) {
                chatMessages.removeAt(0); // 最新の3件のみ表示
              }
            });
            break;
          default:
            print("Unknown message type: ${decodedData['type']}");
        }
      }
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  void sendMessage(String message) {
    channel.sink.add(message);
    _textController.clear();
  }

  void markCell(int x, int y) {
    final msg = jsonEncode({
      "type": "action",
      "actionType": "markCell",
      "x": x,
      "y": y,
    });
    sendMessage(msg);
  }

  void bribeReferee() {
    final msg = jsonEncode({
      "type": "action",
      "actionType": "bribe",
    });
    sendMessage(msg);
  }

  void accuseOpponent() {
    final msg = jsonEncode({
      "type": "action",
      "actionType": "accuse",
    });
    sendMessage(msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Game Screen")),
      body: Column(
        children: <Widget>[
          Container(
            height: 50, // 最上段の高さを固定
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                ElevatedButton(
                  onPressed: bribeReferee,
                  child: Text("Bribe"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                Text("Referee Status: $refereeStatus"),
                ElevatedButton(
                  onPressed: accuseOpponent,
                  child: Text("Accuse"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1, // 正方形のマス目を維持
                child: Container(
                  constraints: BoxConstraints(maxWidth: 200, maxHeight: 200), // マス目の最大サイズを設定
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                    ),
                    itemBuilder: (context, index) {
                      final x = index ~/ 3;
                      final y = index % 3;
                      return GestureDetector(
                        onTap: () {
                          markCell(x, y);
                        },
                        child: Container(
                          decoration: BoxDecoration(border: Border.all()),
                          child: Center(child: Text(board[x][y])),
                        ),
                      );
                    },
                    itemCount: 9,
                    shrinkWrap: true,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Text("Current Turn: $currentTurn"),
          SizedBox(height: 20),
          Container(
            height: 140, // チャットメッセージリストの高さを制限
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) {
                      return Row(
                        mainAxisSize: MainAxisSize.min, // 背景の幅をメッセージの長さに応じて調整
                        children: [
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0), // パディングを調整
                              margin: EdgeInsets.symmetric(vertical: 2.0), // 各メッセージ間のマージンを設定
                              decoration: BoxDecoration(
                                color: Colors.blue[100], // 背景色を設定
                                borderRadius: BorderRadius.circular(12.0), // 角を丸くする
                              ),
                              child: Text(
                                chatMessages[index],
                                style: TextStyle(
                                  color: Colors.black, // 文字色を設定
                                  fontSize: 16.0, // フォントサイズを設定
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: "Send a message",
                        ),
                        onSubmitted: (String input) {
                          sendMessage(jsonEncode({"type": "chatMessage", "message": input}));
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        sendMessage(jsonEncode({"type": "chatMessage", "message": _textController.text}));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
