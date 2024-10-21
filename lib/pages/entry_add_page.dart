import 'package:flutter/material.dart';
import 'package:plaindocs/shared/scanner_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EntryAddPage extends StatefulWidget {
  const EntryAddPage({super.key});

  @override
  State<EntryAddPage> createState() => _EntryAddPageState();
}

class _EntryAddPageState extends State<EntryAddPage> {
  final TextEditingController qrCodeController = TextEditingController();
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  bool isInserting = false;

  @override
  void dispose() {
    qrCodeController.dispose();
    lengthController.dispose();
    widthController.dispose();
    heightController.dispose();
    super.dispose();
  }

  Future<void> insertEntry() async {
    if(isInserting) return;

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      isInserting = true;
    });

    final qrCode = qrCodeController.text;
    final length = double.tryParse(lengthController.text);
    final width = double.tryParse(widthController.text);
    final height = double.tryParse(heightController.text);

    if (qrCode.isEmpty || length == null || width == null || height == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields with valid values')),
      );
      setState(() {
        isInserting = false;
      });
      return;
    }

    try {
      await Supabase.instance.client.from('entries').insert({
        'qr_code': qrCode,
        'length': length,
        'width': width,
        'height': height,
      });

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add entry: $e')),
      );
      return;
    } finally {
      setState(() {
        isInserting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: qrCodeController,
              decoration: InputDecoration(
                labelText: 'Qr Code',
                suffixIcon: ScannerButton(
                  onDetect: (value) {
                    qrCodeController.text = value;
                  },
                )
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: lengthController,
              decoration: const InputDecoration(
                labelText: 'Length',
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: widthController,
              decoration: const InputDecoration(
                labelText: 'Width',
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: heightController,
              decoration: const InputDecoration(
                labelText: 'Height',
              ),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () async => await insertEntry(),
              child: isInserting == false ? const Text('Add') : CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
