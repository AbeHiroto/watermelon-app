import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InviteScreen extends StatefulWidget {
  final String uniqueToken;

  const InviteScreen({Key? key, required this.uniqueToken}) : super(key: key);

  @override
  _InviteScreenState createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final TextEditingController _nicknameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('対戦申請')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: 'ニックネーム',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => submitChallenge(context),
              child: const Text('対戦を申請する'),
            ),
          ],
        ),
      ),
    );
  }

  void submitChallenge(BuildContext context) async {
    if (_nicknameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('ニックネームを入力してください'),
      ));
      return;
    }

    var url = 'http://localhost:8080/challenger/create/${widget.uniqueToken}';
    var response = await http.post(Uri.parse(url), body: {
      'nickname': _nicknameController.text,  // ニックネームのデータを送信
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('申請が成功しました'),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('申請に失敗しました'),
      ));
    }
  }
}
