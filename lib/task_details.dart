import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TaskDetails extends StatefulWidget {
  final Map<String, dynamic> task;
  final Function(Map<String, dynamic>) onSave;

  const TaskDetails({required this.task, required this.onSave, Key? key})
      : super(key: key);

  @override
  _TaskDetailsState createState() => _TaskDetailsState();
}

class _TaskDetailsState extends State<TaskDetails> {
  late String taskName;
  late bool isDone;
  late bool isPriority;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();

    taskName = widget.task['name'];
    isDone = widget.task['isDone'];
    isPriority = widget.task['isPriority'];
  }

  Future<void> _scheduleNotification(String taskName) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'important_task_channel',
      'Tâches importantes',
      channelDescription: 'Notifications pour les tâches importantes',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Tâche importante',
      'N\'oubliez pas : $taskName',
      platformChannelSpecifics,
    );
  }

  void _saveTask() {
    widget.onSave({
      "name": taskName,
      "isDone": isDone,
      "isPriority": isPriority,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la tâche'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: (value) => taskName = value,
              controller: TextEditingController(text: taskName),
              decoration: const InputDecoration(
                labelText: "Nom de la tâche",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: isDone,
              onChanged: (value) {
                setState(() {
                  isDone = value;
                });
              },
              title: const Text("Tâche terminée"),
            ),
            SwitchListTile(
              value: isPriority,
              onChanged: (value) {
                setState(() {
                  isPriority = value;
                });
              },
              title: const Text("Tâche prioritaire"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (isPriority) {
                  _scheduleNotification(taskName);
                }
              },
              child: const Text("Planifier une notification"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveTask,
              child: const Text("Sauvegarder"),
            ),
          ],
        ),
      ),
    );
  }
}
