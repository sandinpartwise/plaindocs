import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:plaindocs/logic/blur_detector/blur_detector_base.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class BlurDetector implements BlurDetectorBase {
  late final Interpreter _interpreter;
  late final List<String> _labels;

  @override
  double threshold;

  bool _isInitialized = false;

  // Image must be at least 90% sharp to be considered not blurry
  BlurDetector({this.threshold = 0.90}) {
    _loadModel().then((value) {
      _isInitialized = true;
    });
  }

  Future<void> _loadModel() async {
    log('Loading the model...');
    final options = InterpreterOptions();
    _interpreter = await Interpreter.fromAsset('assets/tflite/model.tflite', options: options);
    _labels = await _loadLabels('assets/tflite/labels.txt');
    log('Model loaded');
  }

  Future<List<String>> _loadLabels(String labelsPath) async {
    final labelTxt = await rootBundle.loadString(labelsPath);
    return labelTxt.split('\n');
  }

  Future<Map<String, dynamic>> classify(Uint8List bytes) async {
    if (!_isInitialized) {
      return {};
    }

    // Preprocess the image
    var inputImage = _preprocessImage(bytes);

    // Define the input and output tensors
    var output = List.filled(2, 0.0).reshape([1, 2]); // Output shape is [1, 2]

    // Run inference
    _interpreter.run(inputImage, output);


    // Get the result
    var result = output[0];
    var confidence = result[1] > threshold ? result[1] : result[0];
    var label = result[1] > threshold ? _labels[1] : _labels[0];

    return {
      'confidence': confidence * 100,
      'label': label,
    };
  }

  @override
  Future<bool> isBlured(Uint8List bytes) async {
    var result = await classify(bytes);
    return result['label'] == 'BLUR';
  }

  /// Preprocess the image: Resize, normalize, and convert to Float32List
  List<List<List<List<double>>>> _preprocessImage(Uint8List bytes) {
    // Decode the image from bytes
    img.Image image = img.decodeImage(Uint8List.fromList(bytes))!;

    // Resize to 600x600 as expected by the model
    img.Image resizedImage = img.copyResize(image, width: 600, height: 600);

    // Convert the resized image to a Float32List and normalize pixel values
    return _imageTo4DTensor(resizedImage);
  }

  /// Convert the image to a 4D tensor of shape [1, 600, 600, 3]
  List<List<List<List<double>>>> _imageTo4DTensor(img.Image image) {
    List<List<List<List<double>>>> tensor = [
      List.generate(
        image.height,
        (y) => List.generate(
          image.width,
          (x) {
            var pixel = image.getPixel(x, y); // Get the pixel at (x, y)
            return [
              pixel.r / 255.0,  // Normalize red channel
              pixel.g / 255.0,  // Normalize green channel
              pixel.b / 255.0,  // Normalize blue channel
            ];
          },
        ),
      ),
    ];

    return tensor; // Shape [1, 600, 600, 3]
  }
}

