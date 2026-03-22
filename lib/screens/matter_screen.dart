import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart'; // Importação necessária para o PointerDeviceKind

class MatterScreen extends StatefulWidget {
  const MatterScreen({super.key});

  @override
  State<MatterScreen> createState() => _MatterScreenState();
}

class _MatterScreenState extends State<MatterScreen> {
  List<Subject> _subjects = [];
  List<Map<String, String>> _registeredSubjects = [];

  final List<String> _days = [
    'Segunda-feira', 'Terça-feira', 'Quarta-feira',
    'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'
  ];

  final Color _accentColor = const Color(0xFF64B5F6);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? subjectsJson = prefs.getString('subjects');
    final String? registeredJson = prefs.getString('registered_subjects');

    setState(() {
      if (subjectsJson != null) {
        final List<dynamic> subjectsList = jsonDecode(subjectsJson);
        _subjects = subjectsList.map((json) => Subject.fromJson(json)).toList();
      }
      if (registeredJson != null) {
        _registeredSubjects = List<Map<String, String>>.from(
            jsonDecode(registeredJson).map((item) => Map<String, String>.from(item))
        );
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subjects', jsonEncode(_subjects.map((s) => s.toJson()).toList()));
    await prefs.setString('registered_subjects', jsonEncode(_registeredSubjects));
  }

  List<Subject> _getSubjectsForDay(String day) {
    final daySubjects = _subjects.where((s) => s.dayOfWeek == day).toList();
    daySubjects.sort((a, b) => a.time.compareTo(b.time));
    return daySubjects;
  }

  void _showManageBaseSubjectsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              Container(
                width: 45,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[400]?.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 24),
              const Text("Minhas Matérias",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                "${_registeredSubjects.length} disciplinas no total",
                style: TextStyle(color: Colors.grey[500], fontSize: 13, letterSpacing: 0.5),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _registeredSubjects.isEmpty
                    ? Center(
                  child: Text("Nenhuma matéria cadastrada.",
                      style: TextStyle(color: Colors.grey[400])),
                )
                    : ListView.builder(
                  itemCount: _registeredSubjects.length,
                  padding: const EdgeInsets.only(bottom: 20),
                  itemBuilder: (context, i) {
                    final name = _registeredSubjects[i]['name']!;
                    final teacher = _registeredSubjects[i]['teacher']!;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.04)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      letterSpacing: -0.3),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  teacher.isEmpty ? "Sem professor" : teacher,
                                  style: TextStyle(
                                      color: _accentColor.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: Icon(Icons.edit, color: _accentColor),
                                onPressed: () => _addOrEditBaseDialog(setModalState, index: i),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () {
                                  String nameToRemove = _registeredSubjects[i]['name']!;
                                  setState(() {
                                    _registeredSubjects.removeAt(i);
                                    _subjects.removeWhere((s) => s.name == nameToRemove);
                                  });
                                  setModalState(() {});
                                  _saveData();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 58),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                onPressed: () => _addOrEditBaseDialog(setModalState),
                icon: const Icon(Icons.add_rounded, size: 24),
                label: const Text("CADASTRAR",
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addOrEditBaseDialog(Function setModalState, {int? index}) {
    final String oldName = index != null ? _registeredSubjects[index]['name']! : '';
    final n = TextEditingController(text: index != null ? _registeredSubjects[index]['name'] : '');
    final p = TextEditingController(text: index != null ? _registeredSubjects[index]['teacher'] : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(index == null ? "Nova Matéria" : "Editar Matéria"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _buildAdaptiveTextField(n, 'Nome', Icons.book_rounded),
          const SizedBox(height: 12),
          _buildAdaptiveTextField(p, 'Professor(a)', Icons.person_rounded),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (n.text.isEmpty) return;
              setState(() {
                String newName = n.text.trim();
                String newTeacher = p.text.trim();

                if (index == null) {
                  _registeredSubjects.add({'name': newName, 'teacher': newTeacher});
                } else {
                  _registeredSubjects[index] = {'name': newName, 'teacher': newTeacher};
                  for (var subject in _subjects) {
                    if (subject.name == oldName) {
                      subject.name = newName;
                      subject.teacher = newTeacher;
                    }
                  }
                }
              });
              setModalState(() {});
              _saveData();
              Navigator.pop(context);
            },
            child: const Text("Salvar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _addOrEditSubject({Subject? subject, required String dayContext}) {
    if (_registeredSubjects.isEmpty && subject == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cadastre uma matéria no fim da página!")));
      return;
    }

    Map<String, String>? selectedMateria;
    final timeController = TextEditingController(text: subject?.time);

    timeController.addListener(() {
      String text = timeController.text;
      String digitsOnly = text.replaceAll(':', '');
      if (digitsOnly.length == 3 && !text.contains(':')) {
        String newText = '${digitsOnly.substring(0, 2)}:${digitsOnly.substring(2)}';
        timeController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.fromPosition(TextPosition(offset: newText.length)),
        );
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(subject == null ? 'Nova aula: $dayContext' : 'Editar horário', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (subject == null)
                DropdownButtonFormField<Map<String, String>>(
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                  ),
                  hint: const Text("Selecione a Matéria"),
                  items: _registeredSubjects.map((m) => DropdownMenuItem(value: m, child: Text(m['name']!))).toList(),
                  onChanged: (val) => selectedMateria = val,
                )
              else
                Text(subject.name, style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              _buildAdaptiveTextField(timeController, 'Horário (ex: 19:00)', Icons.access_time_rounded, isTime: true),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _accentColor, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    if (timeController.text.trim().isEmpty) return;
                    if (subject == null && selectedMateria == null) return;
                    setState(() {
                      if (subject == null) {
                        _subjects.add(Subject(
                            id: DateTime.now().toString(),
                            name: selectedMateria!['name']!,
                            teacher: selectedMateria!['teacher']!,
                            dayOfWeek: dayContext,
                            time: timeController.text.trim()
                        ));
                      } else {
                        subject.time = timeController.text.trim();
                      }
                    });
                    _saveData();
                    Navigator.pop(context);
                  },
                  child: Text(subject == null ? 'Adicionar' : 'Salvar'),
                ),
              ]),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdaptiveTextField(TextEditingController controller, String label, IconData icon, {bool isTime = false}) {
    return TextField(
      controller: controller,
      keyboardType: isTime ? TextInputType.datetime : TextInputType.text,
      inputFormatters: isTime ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9:]'))] : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _accentColor, size: 20),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Aplicamos o ScrollConfiguration globalmente nesta tela
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse, // Habilita o scroll com o mouse (clicar e arrastar)
            PointerDeviceKind.trackpad,
          },
        ),
        child: SafeArea(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(), // Garante que a física de scroll esteja ativa
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: _days.length + 1,
            itemBuilder: (context, index) {
              if (index == _days.length) {
                return SizedBox(
                  width: 170,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: _accentColor.withOpacity(0.3), blurRadius: 15, spreadRadius: -5)],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _showManageBaseSubjectsSheet,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.settings),
                            SizedBox(width: 8),
                            Text("Matérias", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, height: 1.1)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              final currentDay = _days[index];
              final subjectsForDay = _getSubjectsForDay(currentDay);

              return Container(
                width: 300,
                margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _accentColor.withOpacity(0.5), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(currentDay.toUpperCase(), style: TextStyle(fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.w900, color: _accentColor)),
                  ),
                  Expanded(
                    child: subjectsForDay.isEmpty
                        ? Center(child: Text("Nenhuma aula", style: TextStyle(color: Colors.grey[500], fontSize: 16)))
                        : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: subjectsForDay.length,
                      itemBuilder: (context, i) {
                        final item = subjectsForDay[i];
                        return Card(
                          elevation: 0,
                          color: _accentColor.withOpacity(0.08),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${item.time} • ${item.teacher}", style: const TextStyle(fontSize: 12)),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') _addOrEditSubject(subject: item, dayContext: currentDay);
                                if (value == 'delete') {
                                  setState(() => _subjects.remove(item));
                                  _saveData();
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text("Editar")),
                                const PopupMenuItem(value: 'delete', child: Text("Remover", style: TextStyle(color: Colors.redAccent))),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  InkWell(
                    onTap: () => _addOrEditSubject(dayContext: currentDay),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                    child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Icon(Icons.add_circle_outline_rounded, color: _accentColor, size: 32)
                    ),
                  ),
                ]),
              );
            },
          ),
        ),
      ),
    );
  }
}