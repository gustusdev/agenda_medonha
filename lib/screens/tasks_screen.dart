import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import 'package:intl/intl.dart';

class Task {
  String id;
  String subjectName;
  String title;
  DateTime deadline;
  String content;

  Task({required this.id, required this.subjectName, required this.title, required this.deadline, this.content = ""});

  Map<String, dynamic> toJson() => {
    'id': id, 'subjectName': subjectName, 'title': title, 'deadline': deadline.toIso8601String(), 'content': content,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    subjectName: json['subjectName'],
    title: json['title'],
    deadline: DateTime.parse(json['deadline']),
    content: json['content'] ?? "",
  );
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Task> _tasks = [];
  List<Subject> _subjects = [];
  Timer? _timer;
  final Color _accentColor = const Color(0xFF64B5F6);

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? subjectsJson = prefs.getString('subjects');
    if (subjectsJson != null) {
      _subjects = (jsonDecode(subjectsJson) as List).map((s) => Subject.fromJson(s)).toList();
    }
    final String? tasksJson = prefs.getString('tasks');
    if (tasksJson != null) {
      setState(() {
        _tasks = (jsonDecode(tasksJson) as List).map((t) => Task.fromJson(t)).toList();
        _tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasks', jsonEncode(_tasks.map((t) => t.toJson()).toList()));
  }

  DateTime _getClosestOccurrence(String subjectName) {
    final weekDaysMap = {
      'Segunda-feira': 1, 'Terça-feira': 2, 'Quarta-feira': 3,
      'Quinta-feira': 4, 'Sexta-feira': 5, 'Sábado': 6, 'Domingo': 7,
    };

    final occurrences = _subjects.where((s) => s.name == subjectName).toList();
    if (occurrences.isEmpty) return DateTime.now().add(const Duration(days: 1));

    DateTime now = DateTime.now();
    List<DateTime> potentialDates = [];

    for (var occ in occurrences) {
      int targetWeekday = weekDaysMap[occ.dayOfWeek] ?? 1;
      List<String> timeParts = occ.time.split(':');
      int hour = timeParts.length == 2 ? int.parse(timeParts[0]) : 23;
      int minute = timeParts.length == 2 ? int.parse(timeParts[1]) : 59;

      int diff = targetWeekday - now.weekday;
      if (diff < 0 || (diff == 0 && (now.hour > hour || (now.hour == hour && now.minute >= minute)))) {
        diff += 7;
      }
      potentialDates.add(DateTime(now.year, now.month, now.day, hour, minute).add(Duration(days: diff)));
    }

    potentialDates.sort((a, b) => a.compareTo(b));
    return potentialDates.first;
  }

  String _getTimeRemaining(DateTime deadline) {
    Duration diff = deadline.difference(DateTime.now());
    if (diff.isNegative) return "EXPIRADO";
    return "${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  void _showTaskModal({Task? taskToEdit}) {
    final titleController = TextEditingController(text: taskToEdit?.title);
    final contentController = TextEditingController(text: taskToEdit?.content);
    DateTime selectedDateTime = taskToEdit?.deadline ?? DateTime.now();

    final uniqueNames = _subjects.map((s) => s.name).toSet().toList();
    String? selectedName = taskToEdit?.subjectName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(taskToEdit == null ? "Nova Tarefa" : "Editar Tarefa", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedName,
                  dropdownColor: Theme.of(context).cardColor,
                  decoration: _inputStyle("Matéria", Icons.school),
                  items: uniqueNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        selectedName = val;
                        selectedDateTime = _getClosestOccurrence(val);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildField(titleController, "Título", Icons.edit_note),
                const SizedBox(height: 16),
                ListTile(
                  tileColor: Colors.grey.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: Icon(Icons.calendar_today, color: _accentColor),
                  title: Text(DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR').format(selectedDateTime)),
                  onTap: () async {
                    DateTime? date = await showDatePicker(context: context, initialDate: selectedDateTime, firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (date != null) {
                      TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(selectedDateTime));
                      if (time != null) setModalState(() => selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildField(contentController, "Descrição", Icons.description, maxLines: 3),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _accentColor, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 50)),
                  onPressed: () {
                    if (titleController.text.isEmpty || selectedName == null) return;
                    setState(() {
                      if (taskToEdit == null) {
                        _tasks.add(Task(id: DateTime.now().toString(), subjectName: selectedName!, title: titleController.text, deadline: selectedDateTime, content: contentController.text));
                      } else {
                        taskToEdit.title = titleController.text;
                        taskToEdit.subjectName = selectedName!;
                        taskToEdit.deadline = selectedDateTime;
                        taskToEdit.content = contentController.text;
                      }
                      _tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
                    });
                    _saveTasks(); Navigator.pop(context);
                  },
                  child: Text(taskToEdit == null ? "CRIAR" : "SALVAR"),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accentColor,
        onPressed: () => _showTaskModal(),
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
      body: _tasks.isEmpty
          ? const Center(child: Text("Nenhuma tarefa pendente"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          bool isExpired = task.deadline.isBefore(DateTime.now());
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias, // Mantém o conteúdo dentro do arredondamento
            child: ExpansionTile(
              // --- REMOVE AS LINHAS/DIVISORES AO EXPANDIR ---
              shape: const Border(),
              collapsedShape: const Border(),
              // ----------------------------------------------
              title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(task.subjectName),
              leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined, color: isExpired ? Colors.redAccent : _accentColor, size: 20),
                  Text(_getTimeRemaining(task.deadline), style: TextStyle(color: isExpired ? Colors.redAccent : _accentColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.content.isEmpty ? "Sem descrição." : task.content, style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(icon: Icon(Icons.edit, color: _accentColor), onPressed: () => _showTaskModal(taskToEdit: task)),
                          IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () { setState(() => _tasks.removeAt(index)); _saveTasks(); }),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label, prefixIcon: Icon(icon, color: _accentColor),
      filled: true, fillColor: Colors.grey.withOpacity(0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(controller: controller, maxLines: maxLines, decoration: _inputStyle(label, icon));
  }
}