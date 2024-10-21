import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageDisplayPage extends StatefulWidget {
  final Uint8List image;

  const ImageDisplayPage({super.key, required this.image});

  @override
  _ImageDisplayPageState createState() => _ImageDisplayPageState();
}

class _ImageDisplayPageState extends State<ImageDisplayPage> {

  String? dropdownValue;
  bool isLoading = false;
  Map<String, dynamic>? aiResponse;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Display'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              SizedBox(
                height: 300,
                child: Image.memory(widget.image),
              ),
              SizedBox(height: 10),
              DropdownMenu(
                dropdownMenuEntries: const [
                  DropdownMenuEntry(
                    value: 'identify', 
                    label: 'Identify'
                  ),
                  DropdownMenuEntry(
                    value: 'license-plate', 
                    label: 'License Plate'
                  ),
                ],
                onSelected: (value) {
                  dropdownValue = value;
                },
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () async {
        
                  setState(() {
                    aiResponse = null;
                    isLoading = true;
                  });
        
                  try {
                    final response = await Supabase.instance.client.functions.invoke('analyze-image',
                      headers: {
                        'Content-Type': 'application/json',
                      },                
                      body: {
                        'image': widget.image,
                        'type': dropdownValue
                    });
                    final decodedJson = jsonDecode(response.data) as Map<String, dynamic>;
        
                    setState(() {
                      aiResponse = decodedJson;
                    });
                  } catch(e) {
                    log('Error: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to analyze image')),
                    );
                  } finally {
                    setState(() {
                      isLoading = false;
                    });
                  }
                },
                child: isLoading ? CircularProgressIndicator() : Text('Analyze')
              ),
              SizedBox(height: 10),
              if (aiResponse != null && dropdownValue != null)
                AiResponseDisplay(aiResponse: aiResponse!, type: dropdownValue!),
              
            ],
          ),
        ),
      ),
    );
  }
}

class AiResponseDisplay extends StatelessWidget {
  const AiResponseDisplay({super.key, required this.aiResponse, required this.type});

  final String type;
  final Map<String, dynamic> aiResponse;

  @override
  Widget build(BuildContext context) {

    if(type == 'identify') {
      final listOfItems = (aiResponse['data'] as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
      
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: listOfItems.length,
        itemBuilder: (context, index) {
          final item = listOfItems[index];
          return Card(
            child: ListTile(
              title: Text(
                item['object'].toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(item['description'].toString()),
              trailing: Text(
                item['number'].toString(),
                style: const TextStyle(
                  fontSize: 20.0,
                ),
              ),
            ),
          );
        },
      );
    } else if(type == 'license-plate') {
      final text = aiResponse['data'].toString();
      return Card(
        child: ListTile(
          title: Text(text)
        ),
      );
    } else {
      return Text('Unknown type');
    }
  }
}