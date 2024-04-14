import 'dart:async';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (FlutterErrorDetails details) {
    bool inDebug = false;
    assert(() {
      inDebug = true;
      return true;
    }());
    if (inDebug) {
      return ErrorWidget(details.exception);
    } else {
      return Container(
        alignment: Alignment.center,
        child: Text(
          'Something went wrong!',
          style: TextStyle(color: const Color.fromARGB(255, 221, 130, 123)),
        ),
      );
    }
  };

  runZonedGuarded(
    () async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      runApp(const MyApp());
    },
    (error, stackTrace) {
      print('Firebase initialization failed: $error');
      // ここでエラーロギングを行う、例えばFirebase Crashlyticsにエラーを送信
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeState(),
      child: MaterialApp(
        title: 'BRIBE!',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeState with ChangeNotifier {
  bool hasToken = false;
  bool hasRoom = false;
  bool hasRequest = false;
  String replyStatus = "none";
  String roomStatus = "none";

  Future<void> fetchHomeData() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.yourserver.com/home'),
        headers: {
          'Authorization': 'Bearer your_jwt_token_here',
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
        throw Exception('Failed to load home data');
      }
    } catch (e) {
      print('Error fetching home data: $e');
    }
  }
}

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
    homeState.fetchHomeData();  // データ取得をトリガー
  }

  @override
  Widget build(BuildContext context) {
    final homeState = Provider.of<HomeState>(context);
    return Scaffold(
      appBar: AppBar(title: const Text("ホーム")),
      body: _buildBody(context, homeState),
    );
  }

  Widget _buildBody(BuildContext context, HomeState homeState) {
  // ログイントークンの有無に関わらず、ゲームルームや申請がない場合はルーム作成画面を表示
  if (!homeState.hasRoom && !homeState.hasRequest) {
    return _buildRoomCreationScreen(context);
  }

  // 申請が承認された場合は対戦画面を表示
  if (homeState.hasRequest && homeState.replyStatus == "accepted") {
    return _buildGameScreen(context);
  }

  // 申請管理画面（申請があり、まだ承認されていない場合）
  if (homeState.hasRequest && homeState.replyStatus == "none") {
    return _buildRequestListScreen(context);
  }

  // ルーム管理画面（ルームがあり、申請のステータスによって分岐）
  if (homeState.hasRoom) {
    switch (homeState.roomStatus) {
      case "sent":
        return _buildGameScreen(context); // 対戦が開始された場合
      case "none":
      case "waiting":
      default:
        return _buildRoomManagementScreen(context); // ルームが存在し、申請待ちまたは申請なし
    }
  }

  // どの条件にも当てはまらない場合、安全のためログインプロンプトを表示
  return _buildLoginPrompt(context);
}

// 以下のウィジェット生成メソッドはそれぞれの画面に対応するウィジェットを返します。
Widget _buildLoginPrompt(BuildContext context) {
  return Center(child: Text("ログインしてください"));
}

Widget _buildRoomManagementScreen(BuildContext context) {
  return Center(child: Text("ルーム管理画面"));
}

Widget _buildRequestListScreen(BuildContext context) {
  return Center(child: Text("入室申請一覧"));
}

Widget _buildRoomCreationScreen(BuildContext context) {
  return Center(child: Text("ルーム作成画面"));
}

Widget _buildGameScreen(BuildContext context) {
  return Center(child: Text("対戦画面"));
}
}
