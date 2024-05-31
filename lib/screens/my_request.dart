import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MyRequestScreen extends StatefulWidget {
  const MyRequestScreen({Key? key}) : super(key: key);

  @override
  _MyRequestScreenState createState() => _MyRequestScreenState();
}

class _MyRequestScreenState extends State<MyRequestScreen> {
  Future<List<dynamic>>? _requestInfo;

  @override
  void initState() {
    super.initState();
    _requestInfo = fetchRequestInfo();
  }

  Future<List<dynamic>> fetchRequestInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken') ?? '';

    final response = await http.get(
      Uri.parse('http://localhost:8080/request/info'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['requests'];
    } else {
      throw Exception('Failed to load request info');
    }
  }

  Future<void> disableMyRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken') ?? '';

    final response = await http.delete(
      Uri.parse('http://localhost:8080/request/disable'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Requests successfully disabled')),
      );
      setState(() {
        _requestInfo = fetchRequestInfo();  // Refresh the list
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to disable requests')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Request'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _requestInfo,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(snapshot.data![index]['challengerNickname']),
                  subtitle: Text('Room: ${snapshot.data![index]['roomCreator']} - Theme: ${snapshot.data![index]['roomTheme']}'),
                  trailing: Text(snapshot.data![index]['status']),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: disableMyRequest,
        tooltip: 'Disable My Request',
        child: Icon(Icons.cancel),
      ),
    );
  }
}
