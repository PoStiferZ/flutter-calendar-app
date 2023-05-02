import 'package:flutter/material.dart';
import 'package:fluttercalendar/main.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mysql1/mysql1.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttercalendar/calendar.dart';

void main() async {
  final conn = await MySqlConnection.connect(ConnectionSettings(
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: 'root',
    db: 'my_store',
  ));
  runApp(HomePage(conn: conn));
}

class HomePage extends StatelessWidget {
  final MySqlConnection conn;

  HomePage({Key? key, required this.conn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: HomeScreen(conn: conn),
        ),
        appBar: AppBar(
          title: Text('Accueil'),
          actions: [
            Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(Icons.person),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return MainApp(
                          conn: conn,
                        );
                      },
                    ),
                  );
                  // Naviguer vers la page de profil
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final MySqlConnection conn;

  HomeScreen({Key? key, required this.conn}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadUserDataFromSharedPreferences();
  }

  Future<void> _loadUserDataFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bonjour $_username !',
              style: TextStyle(fontSize: 24.0),
            ),
            // Ajouter d'autres éléments à la page d'accueil ici
          ],
        ),
      ),
    );
  }
}
