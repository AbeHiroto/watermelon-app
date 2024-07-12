import 'dart:async';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'home_state.dart';
import 'screens/invitation.dart';


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
          'Please wait a moment...',
          style: TextStyle(color: Colors.white),
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

      // 　 　＿＿＿　　　／￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣
      // 　／´∀｀;::::＼ ＜ おれの名はテレホマン。さすがにここは直さんといかんだろ。
      // /　　　　/::::::::::|　 ＼＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿
      // | ./|　　/:::::|::::::|
      // | |｜／::::::::|::::::|

  void _handleDeepLink(String link) {
    print('Deep link received: $link');
    Uri uri = Uri.parse(link);
    print('URI Path: ${uri.path}');
    print('URI Path Segments: ${uri.pathSegments}');
    if (uri.pathSegments.length > 2 && uri.pathSegments[1] == 'play') {
      String uniqueToken = uri.pathSegments[2];
      print('Unique token: $uniqueToken');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(navigatorKey.currentContext!).pushNamed('/invite', arguments: uniqueToken);
      });
    } else {
      print('Invalid link format');
    }
  }

  // //本番環境ではパスセグメントの構造が異なるため上のように更新
  // void _handleDeepLink(String link) {
  //   print('Deep link received: $link');
  //   Uri uri = Uri.parse(link);
  //   if (uri.pathSegments.length > 1 && uri.pathSegments[0] == 'play') {
  //     String uniqueToken = uri.pathSegments[1];
  //     print('Unique token: $uniqueToken');
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       Navigator.of(navigatorKey.currentContext!).pushNamed('/invite', arguments: uniqueToken);
  //     });
  //   } else {
  //     print('Invalid link format');
  //   }
  // }

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeState>(
      create: (_) => HomeState(),
      child: MaterialApp(
        title: 'Obsessed with Watermelon',
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