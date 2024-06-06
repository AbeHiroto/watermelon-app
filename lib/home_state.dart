import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
