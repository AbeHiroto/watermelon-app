import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
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

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken') ?? '';
    final sessionId = prefs.getString('sessionId') ?? '';

    channel = IOWebSocketChannel.connect(
      Uri.parse('ws://localhost:8080/ws'), // WebSocketサーバーのURL
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'SessionID': sessionId,
      },
    );

    channel.stream.listen((data) {
      handleMessage(data);
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  void handleMessage(dynamic data) {
    final decodedData = jsonDecode(data);
    switch (decodedData['type']) {
      case 'gameState':
        setState(() {
          board = List<List<String>>.from(decodedData['board']);
          currentTurn = decodedData['currentTurn'].toString();
          refereeStatus = decodedData['refereeStatus'];
          biasDegree = decodedData['biasDegree'];
          bribeCounts = List<int>.from(decodedData['bribeCounts']);
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
      // 他のメッセージタイプの処理
      default:
        print("Unknown message type: ${decodedData['type']}");
    }
  }

  void sendMessage(String message) {
    channel.sink.add(message);
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text("Referee Status: $refereeStatus"),
          SizedBox(height: 20),
          Expanded(
            child: Row(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: bribeReferee,
                      child: Text("Bribe Referee"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      GridView.builder(
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
                      Text("Current Turn: $currentTurn"),
                    ],
                  ),
                ),
                Column(
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: accuseOpponent,
                      child: Text("Accuse Opponent"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(chatMessages[index]),
                      );
                    },
                  ),
                ),
                TextField(
                  onSubmitted: (String input) {
                    sendMessage(jsonEncode({"type": "chatMessage", "message": input}));
                  },
                  decoration: InputDecoration(
                    hintText: "Send a message",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
