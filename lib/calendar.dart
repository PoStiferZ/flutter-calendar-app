import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mysql1/mysql1.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final conn = await MySqlConnection.connect(ConnectionSettings(
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: 'root',
    db: 'my_store',
  ));
  runApp(MainApp(conn: conn));
}

class MainApp extends StatelessWidget {
  final MySqlConnection conn;

  const MainApp({Key? key, required this.conn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: CalendarScreen(conn: conn),
        ),
      ),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  final MySqlConnection conn;

  const CalendarScreen({Key? key, required this.conn}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<String>> _events = {};

  final _titleController = TextEditingController();
  final _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getData();
    _loadUserDataFromSharedPreferences();
  }

  Future<void> _addNewItem() async {
    final newValues = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ajouter'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(hintText: 'Nom du cours'),
              ),
              TextField(
                controller: _dateController,
                decoration: InputDecoration(
                  hintText: 'Date',
                  icon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1950),
                      //DateTime.now() - not to allow to choose before today.
                      lastDate: DateTime(2100));

                  if (pickedDate != null) {
                    print(
                        pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
                    String formattedDate =
                        DateFormat('yyyy-MM-dd').format(pickedDate);
                    print(
                        formattedDate); //formatted date output using intl package =>  2021-03-16
                    setState(
                      () {
                        _dateController.text =
                            formattedDate; //set output date to TextField value.
                      },
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Sauvegarder'),
              onPressed: () async {
                final title = _titleController.text;
                final date = DateFormat('yyyy-MM-dd')
                    .parse(_dateController.text)
                    .toUtc()
                    .add(Duration(days: 1));
                if (title != null) {
                  await addItem(widget.conn, title, date);
                  setState(() {
                    getData();
                    _titleController.clear();
                    _dateController.clear();
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  void getData() async {
    final items = await getItems(widget.conn);
    setState(
      () {
        _events = {};
        for (var item in items) {
          DateTime date = item['date'];
          String title = item['title'];
          String id = item['id'].toString();

          if (_events[date] == null) {
            _events[date] = ['$id,$title'];
          } else {
            _events[date]!.add('$id,$title');
          }
        }
      },
    );
  }

  String _username = '';

  Future<void> _loadUserDataFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          child: Text("Bonjour $_username"),
        ),
        Container(
          child: Align(
            alignment: Alignment.center,
            child: IconButton(
              icon: Icon(Icons.add),
              onPressed: _addNewItem,
            ),
          ),
        ),
        Container(
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 01, 01),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: (day) {
              return _events[day] ?? [];
            },
          ),
        ),
        _events[_selectedDay]?.isNotEmpty == true
            ? Expanded(
                child: ListView.builder(
                  itemCount: _events[_selectedDay]?.length ?? 0,
                  itemBuilder: (context, index) {
                    final event = _events[_selectedDay]![index];
                    final parts = event.split(',');
                    final id = int.parse(parts[0]);
                    final title = parts[1];

                    final date = DateFormat('yyyy-MM-dd').format(_selectedDay);
                    return Container(
                      color: Colors.blue.shade200,
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  id.toString(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            color: Colors.white,
                            onPressed: () async {
                              final newValues = await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  final titleController = TextEditingController(
                                    text: title,
                                  );
                                  final idController = TextEditingController(
                                    text: id.toString(),
                                  );
                                  final dateController = TextEditingController(
                                    text: date,
                                  );
                                  return AlertDialog(
                                    title: const Text('Modifier'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        /* TextField(
                                          controller: idController,
                                          decoration: const InputDecoration(
                                              hintText: 'ID'),
                                        ), */
                                        TextField(
                                          controller: titleController,
                                          decoration: const InputDecoration(
                                              hintText: 'Titre'),
                                        ),
                                        TextField(
                                          controller: dateController,
                                          decoration: const InputDecoration(
                                              hintText: 'Date'),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        child: const Text('Annuler'),
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                      ElevatedButton(
                                        child: const Text('Sauvegarder'),
                                        onPressed: () =>
                                            Navigator.of(context).pop(
                                          {
                                            'id': int.parse(idController.text),
                                            'title': titleController.text,
                                            'date': DateFormat('yyyy-MM-dd')
                                                .parse(dateController.text)
                                                .toUtc()
                                                .add(
                                                  Duration(days: 1),
                                                )
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (newValues['title'] != "") {
                                final id = newValues['id'];
                                final title = newValues['title'];
                                final date = newValues['date'];

                                await updateItem(widget.conn, id, title, date);
                                setState(
                                  () {
                                    getData();
                                  },
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            color: Colors.white,
                            onPressed: () async {
                              await deleteItem(widget.conn, id);
                              setState(() {
                                getData();
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            : Container(
                margin: const EdgeInsets.only(top: 35),
                child: const Text(
                  "Aucun évènement à ce jour",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ],
    );
  }
}

// READ
Future<List<Map<String, dynamic>>> getItems(MySqlConnection conn) async {
  final results = await conn.query('SELECT id, title, date FROM tb_item');
  return results.toList().map((r) => r.fields).toList();
}

// CREATE
Future<void> addItem(MySqlConnection conn, String title, DateTime date) async {
  await conn
      .query('INSERT INTO tb_item (title, date) VALUES (?, ?)', [title, date]);
}

// UPDATE
Future<void> updateItem(
    MySqlConnection conn, int id, String title, DateTime date) async {
  await conn.query(
      'UPDATE tb_item SET title = ?, date = ? WHERE id = ?', [title, date, id]);
}

// DELETE
Future<void> deleteItem(MySqlConnection conn, int id) async {
  await conn.query('DELETE FROM tb_item WHERE id = ?', [id]);
}
