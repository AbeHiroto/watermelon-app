import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'screens/my_request.dart';
import 'screens/my_room.dart';
import 'screens/room_create.dart';
import 'screens/game.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final homeState = Provider.of<HomeState>(context, listen: false);
    homeState.fetchHomeData(context);
  }

  @override
  Widget build(BuildContext context) {
    final homeState = Provider.of<HomeState>(context);
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text("ホーム"),
      //   backgroundColor: Colors.transparent,
      //   elevation: 0, // AppBarの影を削除
      // ),
      backgroundColor: Colors.transparent,
      body: homeState.isLoading
          ? Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue), // インジケータの色を青に設定
            )
            )
          : _buildBody(context, homeState),
    );
  }

  Widget _buildBody(BuildContext context, HomeState homeState) {
  // トークンが無い場合、またはルームや申請がない場合はルーム作成画面を表示
  if (!homeState.hasToken || (!homeState.hasRoom && !homeState.hasRequest)) {
    return RoomCreateScreen();
  }

  // 申請が承認された場合は対戦画面を表示
  if (homeState.hasRequest && homeState.replyStatus == "accepted") {
    return GameScreen();
  }

  // 申請管理画面（申請があり、まだ承認されていない場合）
  if (homeState.hasRequest && homeState.replyStatus == "none") {
    return MyRequestScreen();
  }

  // ルーム管理画面（ルームがあり、申請のステータスによって分岐）
  if (homeState.hasRoom) {
    switch (homeState.roomStatus) {
      case "sent":
        return GameScreen();
      case "none":
      case "waiting":
      default:
        return MyRoomScreen(); // ルームが存在し、申請待ちまたは申請なし
    }
  }
  return _buildErrorScreen(context);
}

Widget _buildErrorScreen(BuildContext context) {
    return Center(child: Text("ERROR AT '_buildBody'"));
}

// ！仮設用ゲーム画面ウィジェット！
Widget _buildGameScreen(BuildContext context) {
  return Center(child: Text("対戦画面"));
}
}

class HomeState with ChangeNotifier {
  bool isLoading = false; // ローディング状態のフラグ
  bool hasToken = false;
  bool hasRoom = false;
  bool hasRequest = false;
  String replyStatus = "none";
  String roomStatus = "none";

  Future<String> getTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken') ?? '';
    return jwtToken;
  }

  Future<void> fetchHomeData(BuildContext context) async {
    isLoading = true;
    notifyListeners();  // UIにローディング開始を通知
    // トークンをストレージから取得（SharedPreferencesから取得）
    String jwtToken = await getTokenFromStorage();

    if (jwtToken.isEmpty) {
      // トークンがない場合の早期リターン
      hasToken = false;
      hasRoom = false;
      hasRequest = false;
      replyStatus = "none";
      roomStatus = "none";
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/home'), // ホスト名は環境ごとに設定
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        hasToken = data['hasToken'];
        hasRoom = data['hasRoom'];
        hasRequest = data['hasRequest'];
        replyStatus = data['replyStatus'];
        roomStatus = data['roomStatus'];
        notifyListeners();  // 通知してUIを更新
      } else {
        hasToken = false;
        hasRoom = false;
        hasRequest = false;
        replyStatus = "none";
        roomStatus = "none";
      }
    } catch (e) {
      hasToken = false;
      hasRoom = false;
      hasRequest = false;
      replyStatus = "none";
      roomStatus = "none";
      _showErrorDialog(context, '読み込みを失敗しました。リロードしてください。');
    } finally {
      isLoading = false;
      notifyListeners();  // UIにローディング終了を通知
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ERROR'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();  // ダイアログを閉じる
            },
            child: const Text('閉じる'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/');
            },
            child: const Text('ホームに戻る'),
          ),
        ],
      ),
    );
  }

  void reloadHomeData(BuildContext context) {
    fetchHomeData(context);
  }
}
