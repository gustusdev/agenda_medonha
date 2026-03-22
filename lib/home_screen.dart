import 'package:flutter/material.dart';
import 'screens/tasks_screen.dart';
import 'screens/matter_screen.dart';
import 'screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    TasksScreen(),
    MatterScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda Medonha')),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tarefas'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Matérias'), // Ícone atualizado
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Configurações'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}