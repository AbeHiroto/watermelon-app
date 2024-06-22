import 'package:flutter/material.dart';
//import 'package:flutter/services.dart'; // RawKeyboardListenerを使用するために必要
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
  List<Map<String, dynamic>> chatMessages = []; // メッセージと送信者IDを格納するリスト
  String opponentStatus = "offline"; // 対戦相手のオンライン状況
  TextEditingController _textController = TextEditingController();
  FocusNode _focusNode = FocusNode();
  int userId = 0; // ログイン中のユーザーIDを保持
  final ScrollController _scrollController = ScrollController();
  String winnerNickName = ""; // 勝者のニックネームを保持
  int userWins = 0; // ユーザーの勝利数
  int opponentWins = 0; // 対戦相手の勝利数
  String roundStatus = ""; // ラウンド情報を保持

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken') ?? '';
    userId = prefs.getInt('userId') ?? 0;
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
  
  Future<void> saveSessionIdAndUserId(String sessionId, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sessionId', sessionId);
    await prefs.setInt('userId', userId);
    setState(() {
      this.userId = userId; // 受信後すぐにuserIdを設定
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void handleMessage(dynamic data) {
    try {
      // final decodedData = jsonDecode(utf8.decode(data as List<int>));
      final decodedData = jsonDecode(data);
      if (decodedData.containsKey('sessionID') && decodedData.containsKey('userID')) {
        saveSessionIdAndUserId(decodedData['sessionID'], decodedData['userID']);
        print('New session ID and User ID saved: ${decodedData['sessionID']}, ${decodedData['userID']}');
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
              roundStatus = decodedData['status'];
              biasDegree = decodedData['biasDegree'] ?? 0;
              bribeCounts = (decodedData['bribeCounts'] as List<dynamic>)
                .map((count) => count ?? 0) // null を 0 に置き換える
                .cast<int>()
                .toList();
              
              if (roundStatus == "finished") {
                clearSessionId();
                showGameFinishedDialog();
              }
            });
            break;
          case 'chatMessage':
            setState(() {
              chatMessages.insert(0, {
                "message": decodedData['message'],
                "from": decodedData['from']
              });
              if (chatMessages.length > 50) {
                chatMessages.removeLast(); // 最新の50件のみ表示
              }
            });
            break;
          case 'onlineStatus':
            setState(() {
              opponentStatus = decodedData['isOnline'] ? "online" : "offline";
            });
            break;
          case 'gameResults':
            setState(() {
              board = (decodedData['board'] as List<dynamic>)
                .map((row) => (row as List<dynamic>).map((cell) => cell as String).toList())
                .toList();
              currentTurn = decodedData['currentPlayer'] ?? "Unknown";
              refereeStatus = decodedData['refereeStatus'];
              biasDegree = decodedData['biasDegree'] ?? 0;
              roundStatus = decodedData['status'];
              bribeCounts = (decodedData['bribeCounts'] as List<dynamic>)
                .map((count) => count ?? 0)
                .cast<int>()
                .toList();
              // 勝利数を計算
              userWins = 0;
              opponentWins = 0;

              final winners = decodedData['winners'] as List<dynamic>;
              for (var winnerId in winners) {
                if (winnerId == userId) {
                  userWins++;
                } else if (winnerId != 0) {
                  opponentWins++;
                }
              }

              // 勝者のニックネームを取得
              if (winners.isNotEmpty && winners.last != 0) {
                final winnerId = winners.last;
                final winnerInfo = (decodedData['playersInfo'] as List<dynamic>)
                  .firstWhere((player) => player['id'] == winnerId);
                winnerNickName = winnerInfo['nickName'] ?? "Unknown";
              } else {
                winnerNickName = "Draw";
              }
            });

            showGameResultDialog(roundStatus);
            break;
          default:
            print("Unknown message type: ${decodedData['type']}");
        }
      }
    } catch (e, stackTrace) {
      print('Error handling message: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void sendMessage(String message) {
  try {
    // final encodedMessage = utf8.encode(jsonEncode({"type": "chatMessage", "message": message}));
    print('Sending message: $message');
    channel.sink.add(message);
    _textController.clear();
  } catch (e, stackTrace) {
    print('Error sending message: $e');
    print('Stack trace: $stackTrace');
  }
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

  void accuseReferee() {
    final msg = jsonEncode({
      "type": "action",
      "actionType": "accuse",
    });
    sendMessage(msg);
  }

  void handleRetry(bool wantRetry) {
    final msg = jsonEncode({
      "type": "action",
      "actionType": "retry",
      "wantRetry": wantRetry,
    });
    sendMessage(msg);
  }

  void showGameResultDialog(String status) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            children: [
              Text(
                roundStatus == "round1_finished"
                    ? "Round 1 Finished!"
                    : roundStatus == "round2_finished"
                        ? "Round 2 Finished!"
                        : "Game Finished! Thank You for Playing!",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "You ",
                      style: TextStyle(fontSize: 16), // Smaller text for "You"
                    ),
                    TextSpan(
                      text: "$userWins - $opponentWins",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), // Larger, bold text for the score
                    ),
                    TextSpan(
                      text: " Rival",
                      style: TextStyle(fontSize: 16), // Smaller text for "Rival"
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                winnerNickName == "Draw"
                    ? "It's a draw!"
                    : "$winnerNickName wins!",
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(height: 16),
              Text("Bribe Counts:"),
              Text("You: ${bribeCounts[0]}"),
              Text("Rival: ${bribeCounts[1]}"),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    // Add the retry message to chat
    setState(() {
      if (status == "round1_finished" || status == "round2_finished") {
        chatMessages.insert(0, {
          "message": "Play Next Round?",
          "from": 0, // 0 indicates system message
          "type": "system"
        });
      } else if (status == "finished") {
        chatMessages.insert(0, {
          "message": "This is the End of the Match!",
          "from": 0,
          "type": "system"
        });
      }
    });
  }

  Future<void> clearSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sessionId');
  }


  void showGameFinishedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Game Finished!"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Thank You for Playing!"),
              SizedBox(height: 8),
              Text("(Reload to Back to Home)"),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
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
                  onPressed: accuseReferee,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Current Turn: $currentTurn"),
              SizedBox(width: 20),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Opponent: ",
                      style: TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text: opponentStatus,
                      style: TextStyle(
                        color: opponentStatus == "online" ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Text("Current Turn: $currentTurn"),
          // // Text("Current Turn: $currentTurn", style: TextStyle(fontFamily: 'NotoSansJP')),
          SizedBox(height: 20),
          Container(
            height: 140, // チャットメッセージリストの高さを制限
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) {
                      final messageData = chatMessages[index];
                      final isMe = messageData["from"] == userId;
                      final isSystem = messageData["type"] == "system";
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: isSystem 
                              ? MainAxisAlignment.center 
                              : isMe 
                                ? MainAxisAlignment.end 
                                : MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                                  margin: EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                                  decoration: BoxDecoration(
                                    color: isSystem
                                        ? Colors.yellow[100]
                                        : isMe
                                          ? Colors.blue[100]
                                          : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Text(
                                    messageData["message"],
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (isSystem && messageData["message"] == "Play Next Round?")
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    handleRetry(true);
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text("Retry Request Sent!"),
                                          content: Text("Waiting for your opponent's response."),
                                          actions: <Widget>[
                                            TextButton(
                                              child: Text("OK"),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: Text("Play"),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    handleRetry(false);
                                  },
                                  child: Text("Quit"),
                                ),
                              ],
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
                        try {
                          sendMessage(jsonEncode({"type": "chatMessage", "message": input}));
                          //sendMessage(input);
                        } catch (e) {
                          print('Error on message submit: $e');
                        }
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
