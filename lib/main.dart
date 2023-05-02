import 'package:flutter/material.dart';
import 'package:fluttercalendar/homescreen.dart';
import 'package:fluttercalendar/calendar.dart';

import 'package:mysql1/mysql1.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final conn = await MySqlConnection.connect(ConnectionSettings(
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: 'root',
    db: 'my_store',
  ));
  runApp(MyApp(conn: conn));
}

class MyApp extends StatelessWidget {
  final MySqlConnection conn;

  MyApp({required this.conn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(conn: conn),
        '/home': (context) => HomePage(conn: conn),
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  final MySqlConnection conn;

  LoginPage({required this.conn});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late String _id;
  late String _username;
  late String _password;
  String _errorMessage = '';

  Future<void> _validateInputs() async {
    final results = await widget.conn.query(
      'SELECT id, username FROM user WHERE username = ? AND password = ?',
      [_username, _password],
    );

    if (results.isNotEmpty) {
      // Récupérer l'ID et le nom d'utilisateur
      final id = results.first['id'];
      final username = results.first['username'];

      // Stocker l'ID et le nom d'utilisateur dans les préférences partagées
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('id', id.toString());
      await prefs.setString('username', username);

      // Naviguer vers la page d'accueil
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        _errorMessage = 'Invalid username or password';
      });
    }
  }

  /* Future<void> _saveUserDataToSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('id', _id);
    await prefs.setString('username', _username);
    await prefs.setString('password', _password);
  } */

  Future<Map<String, String>> getUserDataFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('id') ?? '';
    final username = prefs.getString('username') ?? '';
    final password = prefs.getString('password') ?? '';
    return {'id': id, 'username': username, 'password': password};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Username'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _username = value!;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _password = value!;
                  },
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      _validateInputs();
                    }
                  },
                  child: Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// READ
Future<List<Map<String, dynamic>>> getItems(MySqlConnection conn) async {
  final results = await conn.query('SELECT * FROM user');
  return results.toList().map((r) => r.fields).toList();
}
