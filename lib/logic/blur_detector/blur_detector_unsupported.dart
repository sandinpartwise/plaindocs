import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:plaindocs/logic/blur_detector/blur_detector_base.dart';

class BlurDetector implements BlurDetectorBase {

  @override
  double threshold;

  // Image must be at least 90% sharp to be considered not blurry
  BlurDetector({this.threshold = 0.90});

  @override
  Future<bool> isBlured(Uint8List bytes) async {
    throw UnimplementedError(
        'BlurDetector is not available on your current platform.');
  }
}

