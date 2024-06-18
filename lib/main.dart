import 'dart:async';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'home_state.dart';
import 'screens/invitation.dart';
import 'screens/my_request.dart';
import 'screens/my_room.dart';
import 'screens/room_create.dart';
import 'screens/game.dart';


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
  // // FlutterError.onErrorを使用してエラーハンドリングを設定
  // FlutterError.onError = (FlutterErrorDetails details) {
  //   FlutterError.dumpErrorToConsole(details);
  //   // 一般的なエラーハンドリング
  //   if (details.exception is Error) {
  //     throw details.exception;
  //   }
  // };

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initUniLinks();
    });
  }

  Future<void> _initUniLinks() async {
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      print('Failed to handle initial link: $e');
    }
  }

  void _handleDeepLink(String link) {
    print('Deep link received: $link');
    Uri uri = Uri.parse(link);
    if (uri.pathSegments.length > 1 && uri.pathSegments[0] == 'play') {
      String uniqueToken = uri.pathSegments[1];
      print('Unique token: $uniqueToken');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(navigatorKey.currentContext!).pushNamed('/invite', arguments: uniqueToken);
      });
    } else {
      print('Invalid link format');
    }
  }

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeState>(
      create: (_) => HomeState(),
      child: MaterialApp(
        title: 'bribe',
        navigatorKey: navigatorKey,
        theme: ThemeData(
          fontFamily: 'NotoSansJP', // 日本語対応フォントファミリーの設定
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