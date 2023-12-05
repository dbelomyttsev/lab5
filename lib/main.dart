import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
//import 'package:open_file/open_file.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: JournalDownloader(),
      ),
    );
  }
}

class JournalDownloader extends StatefulWidget {
  @override
  JournalDownloaderState createState() => JournalDownloaderState();

}

class JournalDownloaderState extends State<JournalDownloader> {
  String _journalId = '';
  String _filePath = '';

  @override
  void initState() {
    super.initState();
    _showDialog(context);
  }

  Future<void> _clearPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> _showDialog(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isChecked = (prefs.getBool('isChecked') ?? false);

    if (!isChecked) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Инструкция'),
            content: Text('Нажмите "Скачать", чтобы загрузить журнал на устройство, "Смотреть", чтобы просмотреть загруженный файл и "Удалить", чтобы удалить его.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Больше не показывать'),
                onPressed: () {
                  prefs.setBool('isChecked', true);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      Fluttertoast.showToast(
          msg: "You've already checked the box. No dialog will be shown.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0
      );
    }
  }

  Future<void> _downloadJournal(String id) async {
    setState(() {
      _journalId = id;
    });

    final url = 'http://ntv.ifmo.ru/file/journal/$id.pdf';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200 && response.headers['content-type'] == 'application/pdf') {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$id.pdf');
      await file.writeAsBytes(response.bodyBytes);

      setState(() {
        _filePath = file.path;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Журнал не найден!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openJournal() async {
    if (_filePath.isNotEmpty) {
      try {
        await OpenFilex.open(_filePath, type: 'application/pdf');
      } catch (e) {
        print('Error opening file: $e');
      }
    }
  }

  Future<void> _deleteJournal() async {
    if (_filePath.isNotEmpty) {
      await File(_filePath).delete();
      setState(() {
        _filePath = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          onChanged: (value) {
            setState(() {
              _journalId = value;
            });
          },
        ),
        ElevatedButton(onPressed: () => _downloadJournal(_journalId), child: Text('Скачать')),
        if (_filePath.isNotEmpty) ...[
          ElevatedButton(
            onPressed: _openJournal,
            child: Text('Смотреть'),
          ),
          ElevatedButton(
            onPressed: _deleteJournal,
            child: Text('Удалить'),
          ),
        ],
        ElevatedButton(
          onPressed: _clearPreferences,
          child: Text('Сбросить настройки'),
        ),
      ],
    );
  }
}