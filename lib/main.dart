import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:plaindocs/pages/entry_add_page.dart';
import 'package:plaindocs/pages/entry_details_page.dart';
import 'package:plaindocs/logic/models/entry.dart';
import 'package:plaindocs/shared/scanner_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'logic/blur_detector/blur_detector.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://frcqpsxnkubiafcpmjsl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZyY3Fwc3hua3ViaWFmY3BtanNsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjgzNzI0MzAsImV4cCI6MjA0Mzk0ODQzMH0.iDhPwjiylfx9xbu7FyMqtcv6Cg_U5Nm59jcM4e3Q4_I',
  );
  
  runApp(const MyApp());
}

final BlurDetector blurDetector = BlurDetector();

final ThemeData myTheme = ThemeData(
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.blueGrey,
  ).copyWith(
    inversePrimary: Colors.blueGrey,
  ),
  appBarTheme: const AppBarTheme(
    color: Colors.blueGrey,
    foregroundColor: Colors.white
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: const BorderSide(color: Colors.grey),
    ),
  ),
  textButtonTheme: const TextButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll<Color>(Colors.blueGrey),
      foregroundColor: WidgetStatePropertyAll<Color>(Colors.white),
      minimumSize: WidgetStatePropertyAll<Size>(Size(double.infinity, 36)),
    ),
  ),
  elevatedButtonTheme: const ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll<Color>(Colors.blueGrey),
      foregroundColor: WidgetStatePropertyAll<Color>(Colors.white),
    ),
  ),
  cardTheme: CardTheme(
    color: Colors.blueGrey[50],
  ),
  dividerTheme: const DividerThemeData(
    color: Colors.grey,
  ),
  progressIndicatorTheme: ProgressIndicatorThemeData(
    color: Colors.blueGrey.shade100,
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: myTheme,
      home: const MyHomePage(title: 'PlainDocs'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Entry> entries = [];
  List<Entry> filteredEntries = [];
  late StreamSubscription entriesSubscription;
  TextEditingController searchController = TextEditingController();

  Future<List<Entry>> getEntries() async {
    try {
      final entries = await Supabase.instance.client.from('entries').select('*');

      return entries.map((e) => Entry.fromJson(e)).toList();
    } catch(e) { 
      log('Error: $e');
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
    searchController.addListener(filterEntries);
  }

  @override
  void dispose() {
    entriesSubscription.cancel();
    searchController.dispose();
    super.dispose();
  }

  void fetchData() async {
    // final fetchedEntries = await getEntries();
    // setState(() {
    //   entries = fetchedEntries;
    // });

    Supabase.instance.client.from('entries').stream(primaryKey: ['id']).listen(
      (event) {
        entries = event.map((e) => Entry.fromJson(e)).toList();
        filterEntries();
      }
    );
  }

  void filterEntries() {
    setState(() {
      filteredEntries = entries.where((e) => e.qrCode.contains(searchController.text)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Search',
                  suffixIcon: ScannerButton(
                    onDetect: (value) {
                      searchController.text = value;
                    }
                  )
                )
              ),
              SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  itemCount: filteredEntries.length,
                  itemBuilder: (context, index) {
                    final entry = filteredEntries[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (_) => EntryDetailsPage(entry.id!)
                          )
                        );
                      },
                      child: Card(
                        child: ListTile(
                          title: Text('${entry.qrCode}'),
                          subtitle: Text('Length: ${entry.length} | Width: ${entry.width} | Heigth: ${entry.height}'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (_) => EntryAddPage()
              )
            );
          },
          tooltip: 'Add',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
