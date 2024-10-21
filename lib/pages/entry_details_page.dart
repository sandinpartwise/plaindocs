import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plaindocs/logic/models/entry.dart';
import 'package:plaindocs/logic/models/file_record.dart';
import 'package:plaindocs/main.dart';
import 'package:plaindocs/pages/image_display_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EntryDetailsPage extends StatefulWidget {
  const EntryDetailsPage(this.id, {super.key});

  final int id;

  @override
  State<EntryDetailsPage> createState() => _EntryDetailsPageState();
}

class _EntryDetailsPageState extends State<EntryDetailsPage> {
  bool isLoading = false;
  late Entry entry;
  List<FileRecord> fileRecords = [];
  late StreamSubscription fileRecordsSubscription;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  void dispose() {
    fileRecordsSubscription.cancel();
    super.dispose();
  }

  Future<Entry> getEntry() async {
    final entry = await Supabase.instance.client.from('entries').select('*').eq('id', widget.id).single();
    return Entry.fromJson(entry);
  }

  void fetchData() async {
    setState(() {
      isLoading = true;
    });

    final e = await getEntry();
    setState(() {
      entry = e;
    });

    fileRecordsSubscription = Supabase.instance.client.from('file_records').stream(primaryKey: ['id']).eq('entry_id', widget.id).listen(
      (event) async {
        final listOfFutures = event.map((e) async {
          final fr = FileRecord.fromJson(e);
          fr.bytes = await getImage('${fr.entryId}/${fr.name}');
          return fr;
        });

        final records = await Future.wait(listOfFutures);

        setState(() {
          fileRecords = records;
        });
      }
    );

    setState(() {
      isLoading = false;
    });
  }

  final Map<String, Uint8List> imageCache = {};

  Future<Uint8List?> getImage(String path) async {
    if (imageCache.containsKey(path)) {
      return imageCache[path];
    }

    try {
      final image = await Supabase.instance.client.storage.from('media').download(path);
      imageCache[path] = image;
      return image;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry Details'),
      ),
      body: isLoading ?  const Center(child: CircularProgressIndicator()) : Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            DetailText('Qr Code', entry.qrCode),
            SizedBox(height: 10),
            
            Row(
              children: [
                Flexible(child: DetailText('Length', entry.length.toString())),
                SizedBox(width: 10),
                Flexible(child: DetailText('Width', entry.width.toString())),
                SizedBox(width: 10),
                Flexible(child: DetailText('Height', entry.height.toString())),
              ],
            ),
            SizedBox(height: 10),
            Divider(),
            SizedBox(height: 10),
            Flexible(
              child: GridView.builder(
                itemCount: fileRecords.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                ),
                itemBuilder: (context, index) {
                  if(fileRecords[index].bytes == null) {
                    return Icon(Icons.image_not_supported);
                  } else {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (_) => ImageDisplayPage(image: fileRecords[index].bytes!)
                          )
                        );
                      },
                      child: Image.memory(fileRecords[index].bytes!)
                    );
                  }
                },
              )
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final imagePicker = ImagePicker();

          bool isBlured = true;
          XFile? image;

          while(isBlured) {
            image = await imagePicker.pickImage(source: ImageSource.camera);
            if(image == null) {
              break;
            } else {
              isBlured = await blurDetector.isBlured(await image.readAsBytes());
            }
            if(isBlured) {
              isBlured = await showResponseDialog(
                context: context,
                title: 'Image is blurry',
                content: 'Do you want to try again?',
                positiveButtonText: 'Yes',
                negativeButtonText: 'Use anyway'
              ) ?? true;
            }
          }

          if(image != null) {
            final bytes = await image.readAsBytes();

            await Supabase.instance.client.storage.from('media').uploadBinary('${widget.id}/${image.name}', bytes);

            await Supabase.instance.client.from('file_records').insert({
              'name': image.name,
              'entry_id': widget.id
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }


  Future<bool?> showResponseDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String positiveButtonText,
    required String negativeButtonText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text(
                positiveButtonText,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(
                negativeButtonText,
              ),
            ),
          ],
        );
      },
    );
  }
}

class DetailText extends StatelessWidget {
  const DetailText(this.title, this.text, {super.key});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(5),
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(text),
        ],
      ),
    );
  }
}