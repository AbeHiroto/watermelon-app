import 'dart:async';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uni_links/uni_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/invitation.dart';
import 'screens/my_request.dart';
import 'screens/my_room.dart';
import 'screens/room_create.dart';


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
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        print('Firebase initialization failed: $e');
        // Firebaseが初期化に失敗してもアプリを起動します。
        // 必要であればエラーロギングを行う、例えばFirebase Crashlyticsにエラーを送信
      }
      runApp(const MyApp()); // Firebaseの状態にかかわらずアプリを起動
    },
    (error, stackTrace) {
      print('Unhandled exception occurred: $error');
      // 未処理の例外があればここで捕捉し、ログに記録
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initUniLinks();
  }

  Future<void> initUniLinks() async {
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }

      linkStream.listen((String? link) {
        if (link != null) {
          _handleDeepLink(link);
        }
      }, onError: (err) {
        print('Failed to handle incoming links: $err');
      });
    } catch (e) {
      print('Failed to handle initial link: $e');
    }
  }

  void _handleDeepLink(String link) {
    Uri uri = Uri.parse(link);
    if (uri.pathSegments.length == 2 &&
        uri.pathSegments[0] == 'play') {
      String uniqueToken = uri.pathSegments[1];
      Navigator.of(context).pushNamed('/invite', arguments: uniqueToken);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeState>(
      create: (_) => HomeState(),
      child: MaterialApp(
        title: 'bribe',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/invite': (context) => InviteScreen(
            uniqueToken: ModalRoute.of(context)!.settings.arguments as String,
          ),
        },
      ),
    );
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
    // トークンをストレージから取得（SharedPreferencesなどから取得する例）
    String jwtToken = await getTokenFromStorage(); // 仮の関数

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
            // ホーム画面に戻るロジック、通常はナビゲーションのスタックをクリアしてホーム画面をリロードする
            Navigator.pushReplacementNamed(context, '/');
          },
          child: const Text('ホームに戻る'),
        ),
      ],
    ),
  );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    final homeState = Provider.of<HomeState>(context);
    return Scaffold(
      appBar: AppBar(title: const Text("ホーム")),
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
    return _buildGameScreen(context);
  }

  // 申請管理画面（申請があり、まだ承認されていない場合）
  if (homeState.hasRequest && homeState.replyStatus == "none") {
    return MyRequestScreen();
  }

  // ルーム管理画面（ルームがあり、申請のステータスによって分岐）
  if (homeState.hasRoom) {
    switch (homeState.roomStatus) {
      case "sent":
        return _buildGameScreen(context); // 対戦が開始された場合
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