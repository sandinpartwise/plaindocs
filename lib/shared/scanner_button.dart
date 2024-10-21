import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerButton extends StatelessWidget {
  const ScannerButton({super.key, required this.onDetect});

  final Function(String) onDetect;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showModalBottomSheet(
          context: context, 
          builder: (context) {
            return ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  MobileScanner(
                    onDetect: (value) {
                      onDetect(value.barcodes.first.displayValue.toString());
                      Navigator.of(context).pop();
                    },
                  ),
                  ScannerOverlay(),
                ],
              ),
            );
          }
        );
      }, 
      icon: Icon(Icons.qr_code),
    );
  }
}

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(
        Colors.transparent,
        BlendMode.dstOut,
      ),
      child: Stack(
        children: [
          Container(
            color: Colors.black.withOpacity(0.8),
          ),
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                backgroundBlendMode: BlendMode.srcOut
              ),
            ),
          )
        ],
      ),
    );
  }
}