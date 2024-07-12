import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:html' as html;
import 'package:shared_preferences/shared_preferences.dart';

class InviteScreen extends StatefulWidget {
  final String uniqueToken;

  const InviteScreen({Key? key, required this.uniqueToken}) : super(key: key);

  @override
  _InviteScreenState createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  bool _isLoading = false;
  String roomCreator = '';
  String roomTheme = '';

  @override
  void initState() {
    super.initState();
    fetchRoomInfo();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> fetchRoomInfo() async {
    // ここで setState は呼ばない
    _isLoading = true;
    // setState(() {
    //   _isLoading = true;
    // });

    // ここでユーザー情報を取得し、対戦申請がすでにあるかを確認する
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken') ?? '';

    // 　 　＿＿＿　　　／￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣
    // 　／´∀｀;::::＼ ＜ おれの名はテレホマン。さすがにここは直さんといかんだろ。
    // /　　　　/::::::::::|　 ＼＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿
    // | ./|　　/:::::|::::::|
    // | |｜／::::::::|::::::| 

    if (jwtToken.isNotEmpty) {
      final userInfoResponse = await http.get(
        Uri.parse('https://abehiroto.com:10443/home'), // ユーザー情報を取得するエンドポイント
        //Uri.parse('http://localhost:8080/home'), // ユーザー情報を取得するエンドポイント
        headers: {'Authorization': 'Bearer $jwtToken'},
      );

      if (userInfoResponse.statusCode == 200) {
        final userInfo = jsonDecode(userInfoResponse.body);
        if (userInfo['hasRequest'] == true) {
          // 対戦申請がすでにある場合はリダイレクト
          // VPS用
          html.window.location.href = 'https://abehiroto.com/wmapp';

          // 以下解決につながらず
          // // ローカルテスト用
          // html.window.location.href = '/';
          // 非同期でリダイレクトを実行
          // Future.delayed(Duration(milliseconds: 100), () {
          //   html.window.location.href = '/';
          // });
          // await Future.delayed(Duration(milliseconds: 100));
          //   html.window.location.href = '/';
          // return;
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to fetch user info.'),
        ));
        return;
      }
    }

    // 　 　＿＿＿　　　／￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣
    // 　／´∀｀;::::＼ ＜ おれの名はテレホマン。さすがにここは直さんといかんだろ。
    // /　　　　/::::::::::|　 ＼＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿
    // | ./|　　/:::::|::::::|
    // | |｜／::::::::|::::::| 

    final response = await http.get(
      Uri.parse('https://abehiroto.com:10443/play/${widget.uniqueToken}'),
      //Uri.parse('http://localhost:8080/play/${widget.uniqueToken}'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          roomCreator = data['roomCreator'];
          roomTheme = data['roomTheme'];
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('ルーム情報の取得に失敗しました。'),
      ));
    }
    // if (response.statusCode == 200) {
    //   final data = jsonDecode(response.body);
    //   setState(() {
    //     roomCreator = data['roomCreator'];
    //     roomTheme = data['roomTheme'];
    //     _isLoading = false;
    //   });
    // } else {
    //   setState(() {
    //     _isLoading = false;
    //   });
    //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //     content: Text('ルーム情報の取得に失敗しました。'),
    //   ));
    // }
  }

  Future<void> submitChallenge(BuildContext context) async {
    if (_nicknameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Enter Your Nickname'),
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    String jwtToken = prefs.getString('jwtToken') ?? '';

    final headers = {'Content-Type': 'application/json'};
    if (jwtToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $jwtToken';
    }

       // 　 　＿＿＿　　　／￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣
      // 　／´∀｀;::::＼ ＜ おれの名はテレホマン。さすがにここは直さんといかんだろ。
      // /　　　　/::::::::::|　 ＼＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿
      // | ./|　　/:::::|::::::|
      // | |｜／::::::::|::::::|

    try {
      final response = await http.post(
        Uri.parse('https://abehiroto.com:10443/challenger/create/${widget.uniqueToken}'),
        //Uri.parse('http://localhost:8080/challenger/create/${widget.uniqueToken}'),
        headers: headers,
        body: jsonEncode({
          'nickname': _nicknameController.text,
          'subscriptionStatus': 'paid', // 課金ステータスが必要であれば設定
        }),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      // 新しいJWTトークンがレスポンスに含まれている場合、それを保存し、再度リクエストを送信
      if (data.containsKey('newToken')) {
        await prefs.setString('jwtToken', data['newToken']);
        print('Saved newToken: ${data['newToken']}');
        await submitChallenge(context); // 新しいトークンで再度リクエストを送信
        return;
      }

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Request sent successfully'),
        ));
        // 対戦申請後にホーム画面に遷移…ではなく画面遷移はfetchRoomInfo関数に任せてここは単にリロード
        //Navigator.pushReplacementNamed(context, '/');
        html.window.location.reload(); //ブラウザのリロード
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Fail to Send Request. Status Code: ${response.statusCode}, Message: ${data['error']}'),
        ));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error Occurred: $e'),
      ));
    }
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

  // InviteScreenの余白設定
  Widget buildLayout(BuildContext context, Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double height = constraints.maxHeight;
        double width = constraints.maxWidth;
        bool needsHorizontalPadding = (width / height) > 0.60;
        bool needsVerticalPadding = (height / width) > 1.8;

        return Container(
          decoration: needsHorizontalPadding
              ? BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/backpattern.png"), // パターン画像
                    fit: BoxFit.none, // オリジナルサイズのまま表示
                    repeat: ImageRepeat.repeat, // 画像を繰り返して表示
                  ),
                )
              : null,
          child: Center(
            child: AspectRatio(
              aspectRatio: 0.60, // 縦横比を0.60に設定
              child: Container(
                color: Colors.white, // 背景の白色
                margin: needsVerticalPadding
                    ? const EdgeInsets.symmetric(vertical: 0.0)
                    : EdgeInsets.zero,
                padding: needsHorizontalPadding
                    ? const EdgeInsets.symmetric(horizontal: 0.0)
                    : EdgeInsets.zero,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: IconButton(
          icon: Icon(Icons.info_outline),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Obsessed with Watermelon'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('This App is not too political🍉'),
                      SizedBox(height: 8),
                      Text('© 2024 Hiroto Abe. All rights reserved.'),
                    ],
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: Text('Close'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.warning_amber_outlined),
            onPressed: _showResetConfirmationDialog,
          ),
        ],
      ),
      body: buildLayout(
        context,
        Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/invitation.png', // 画面全体の背景画像
                fit: BoxFit.cover,
              ),
            ),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 100),
                        TextField(
                          controller: _nicknameController,
                          decoration: InputDecoration(
                            labelText: 'Your Nickname',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => submitChallenge(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 0, 38, 70), // ボタンの背景色
                            foregroundColor: Colors.white, // 文字の色
                          ),
                          child: Text('Submit to $roomCreator'),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
