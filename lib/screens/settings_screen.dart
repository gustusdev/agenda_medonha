import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // Necessário para o Uint8List
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // --- FUNÇÃO PARA EXPORTAR (SALVAR .JSON) ---
  Future<void> _exportConfig(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Coleta os dados atuais do SharedPreferences
      final subjects = prefs.getString('subjects') ?? '[]';
      final registered = prefs.getString('registered_subjects') ?? '[]';

      // Cria o mapa do backup
      Map<String, dynamic> backup = {
        'subjects': jsonDecode(subjects),
        'registered_subjects': jsonDecode(registered),
        'export_date': DateTime.now().toIso8601String(),
      };

      // Converte para String e depois para Bytes (Obrigatório para Android/iOS)
      String jsonString = jsonEncode(backup);
      Uint8List bytes = Uint8List.fromList(utf8.encode(jsonString));

      // Abre o seletor de local para salvar
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Onde deseja salvar o backup?',
        fileName: 'backup_materias.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes, // Aqui resolvemos o erro "bytes are required"
      );

      if (outputFile != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Backup exportado com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao exportar: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- FUNÇÃO PARA IMPORTAR (LER .JSON) ---
  Future<void> _importConfig(BuildContext context) async {
    try {
      // Abre o seletor de arquivos
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        // Lê o conteúdo do arquivo selecionado
        File file = File(result.files.single.path!);
        String contents = await file.readAsString();
        Map<String, dynamic> data = jsonDecode(contents);

        // Validação básica da estrutura do arquivo
        if (data.containsKey('subjects') && data.containsKey('registered_subjects')) {
          final prefs = await SharedPreferences.getInstance();

          await prefs.setString('subjects', jsonEncode(data['subjects']));
          await prefs.setString('registered_subjects', jsonEncode(data['registered_subjects']));

          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Backup restaurado! Reinicie o app para aplicar."),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        } else {
          throw Exception("Arquivo de backup inválido.");
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao importar: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [

            // --- SEÇÃO DE APARÊNCIA ---
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                "APARÊNCIA DA AGENDA",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),

            // --- TEMA ---
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, child) {
                final isDark = currentMode == ThemeMode.dark;
                return ListTile(
                  leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                  title: const Text('Modo Escuro'),
                  trailing: Switch(
                    value: isDark,
                    activeColor: Colors.blueAccent,
                    onChanged: (bool value) async {
                      themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isDarkMode', value);
                    },
                  ),
                );
              },
            ),

            const Divider(),

            // --- SEÇÃO DE BACKUP ---
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                "BACKUP DE MATÉRIAS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.upload_file_rounded),
              title: const Text('Exportar Matérias'),
              subtitle: const Text('Salva em um arquivo json'),
              onTap: () => _exportConfig(context),
            ),

            ListTile(
              leading: const Icon(Icons.file_download_rounded),
              title: const Text('Importar Matérias'),
              subtitle: const Text('Carrega de um arquivo json'),
              onTap: () => _importConfig(context),
            ),

            const Divider(),

            // --- SEÇÃO DE SOBRE ---
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                "SOBRE O APLICATIVO",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),

            // --- SOBRE ---
            const ListTile(
              leading: Icon(Icons.code),
              title: Text('Desenvolvedor'),
              subtitle: Text('Augusto Rodrigues da Silva  🤓'),
            ),

            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Versão'),
              subtitle: Text('1.0.2'),
            ),
          ],
        ),
      ),
    );
  }
}