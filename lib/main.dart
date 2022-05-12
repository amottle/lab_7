import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

void main() {
  HttpOverrides.global = SecHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (BuildContext context) => const HomePage1(title: 'Новости КубГАУ'),
      },
    );
  }
}

class HomePage1 extends StatefulWidget {
  const HomePage1({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomePage1> createState() => Page1();
}

class Page1 extends State<HomePage1> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title:
              Text(widget.title, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
        body: FutureBuilder<List<TheInfo>>(
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('Произошла ошибка при запросе', style: TextStyle(fontSize: 40, color: Colors.black45), textAlign: TextAlign.center),);
            } else if (snapshot.hasData) {
              return ShownInfo(infoList: snapshot.data!);
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
          future: convertInfo(http.Client()),
        ));
  }
}




class ShownInfo extends StatelessWidget {
  const ShownInfo({Key? key, required this.infoList}) : super(key: key);

  final List<TheInfo> infoList;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.all(20),
          //color: const Color.fromRGBO(255, 255, 255, 0.9),
          shadowColor: Colors.grey,
          elevation: 10,
          child: Card(
            margin: const EdgeInsets.all(10),
            elevation: 0,
            child: Column(
              children: [
                Image.network(infoList[index].photo_url.replaceFirst('//', '//old.')),
                Text(infoList[index].date.toString()),
                Container(height: 20),
                Text(infoList[index].PREVIEW_TEXT),
                Container(height: 10),
                Text(Bidi.stripHtmlIfNeeded(infoList[index].text)),
              ],
            ),
          ),
        );
      },
    );
  }
}



Future<List<TheInfo>> convertInfo(http.Client client) async {
  final response = await client.get(Uri.parse(
      'https://old.kubsau.ru/api/getNews.php?key=6df2f5d38d4e16b5a923a6d4873e2ee295d0ac90'));
  return compute(parseInfo, response.body);
}

List<TheInfo> parseInfo(String replyBody) {
  final parsed = jsonDecode(replyBody).cast<Map<String, dynamic>>();
  return parsed.map<TheInfo>((json) => TheInfo.converter(json)).toList();
}



class TheInfo {
  final String ID;
  final String date;
  final String title;
  final String PREVIEW_TEXT;
  final String photo_url;
  final String page_url;
  final String text;
  final String lastDate;

  TheInfo({
    required this.ID,
    required this.date,
    required this.title,
    required this.PREVIEW_TEXT,
    required this.photo_url,
    required this.page_url,
    required this.text,
    required this.lastDate,
  });

  factory TheInfo.converter(Map<String, dynamic> json) {
    return TheInfo(
      ID: json['ID'] as String,
      date: json['ACTIVE_FROM'] as String,
      title: json['TITLE'] as String,
      PREVIEW_TEXT: json['PREVIEW_TEXT'] as String,
      photo_url: json['PREVIEW_PICTURE_SRC'] as String,
      page_url: json['DETAIL_PAGE_URL'] as String,
      text: json['DETAIL_TEXT'] as String,
      lastDate: json['LAST_MODIFIED'] as String,
    );
  }
}


class SecHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}