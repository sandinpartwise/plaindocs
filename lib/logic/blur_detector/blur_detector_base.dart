import 'dart:typed_data';

abstract class BlurDetectorBase {
  abstract double threshold;
  Future<bool> isBlured(Uint8List bytes);
}