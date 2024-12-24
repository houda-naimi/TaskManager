import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('tasksBox');

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[200],
        textTheme: GoogleFonts.robotoTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo,
          titleTextStyle: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.indigo,
        ),
      ),
      home: TaskManagerHomePage(),
    );
  }
}

class TaskManagerHomePage extends StatefulWidget {
  @override
  _TaskManagerHomePageState createState() => _TaskManagerHomePageState();
}

class _TaskManagerHomePageState extends State<TaskManagerHomePage> {
  final Box tasksBox = Hive.box('tasksBox');
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _tasks = tasksBox.values.map((task) => Map<String, dynamic>.from(task)).toList();
  }

  void _addTask(Map<String, dynamic> newTask) {
    tasksBox.add(newTask);
    setState(() {
      _tasks.add(newTask);
      _listKey.currentState!.insertItem(_tasks.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Manager'),
        centerTitle: true,
      ),
      body: AnimatedList(
        key: _listKey,
        initialItemCount: _tasks.length,
        itemBuilder: (context, index, animation) {
          final task = _tasks[index];

          return FadeTransition(
            opacity: animation,
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: task['isDone'],
                      onChanged: (bool? value) {
                        tasksBox.putAt(
                          index,
                          {
                            "name": task['name'],
                            "isDone": value ?? false,
                            "isPriority": task['isPriority'],
                          },
                        );
                        setState(() {
                          _tasks[index]['isDone'] = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['name'],
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              decoration: task['isDone']
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              fontWeight: task['isPriority']
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: task['isPriority']
                                  ? Colors.red
                                  : Colors.black,
                            ),
                          ),
                          if (task['isPriority'])
                            Text(
                              "Prioritaire",
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _deleteTask(index);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTaskDialog(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _deleteTask(int index) {
    final removedTask = _tasks[index];
    tasksBox.deleteAt(index);
    setState(() {
      _tasks.removeAt(index);
      _listKey.currentState!.removeItem(
        index,
        (context, animation) => FadeTransition(
          opacity: animation,
          child: Card(
            child: ListTile(
              title: Text(removedTask['name']),
            ),
          ),
        ),
        duration: const Duration(milliseconds: 300),
      );
    });
  }

  void _showAddTaskDialog(BuildContext context) {
    String newTaskName = "";
    bool isPriority = false;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Ajouter une tâche",
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  onChanged: (value) {
                    newTaskName = value;
                  },
                  decoration: InputDecoration(
                    labelText: "Nom de la tâche",
                    labelStyle: TextStyle(color: Colors.indigo),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.indigo, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return SwitchListTile(
                      title: Text(
                        "Prioritaire",
                        style: GoogleFonts.roboto(fontSize: 16),
                      ),
                      activeColor: Colors.indigo,
                      value: isPriority,
                      onChanged: (bool value) {
                        setState(() {
                          isPriority = value;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text("Annuler"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (newTaskName.isNotEmpty) {
                          _addTask({
                            "name": newTaskName,
                            "isDone": false,
                            "isPriority": isPriority,
                          });
                        }
                        Navigator.of(context).pop();
                      },
                      child: Text("Ajouter"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
