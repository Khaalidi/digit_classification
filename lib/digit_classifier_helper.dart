import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class DigitClassifierHelper {
  static const _modelPath = "assets/models/mnist.tflite";
  late Interpreter _interpreter;
  late Tensor _inputTensor;
  late Tensor _outputTensor;

  Future<void> init() async {
    await _loadModel();
  }

  Future<void> _loadModel() async {
    final options = InterpreterOptions();
    // Load model from assets
    _interpreter = await Interpreter.fromAsset(_modelPath, options: options);
    _inputTensor = _interpreter.getInputTensors().first;
    _outputTensor = _interpreter.getOutputTensors().first;
  }

  Future<(int, double)> runInference(Uint8List inputImageData) async {
    // Resize image
    img.Image? image = img.decodeImage(inputImageData);
    img.Image? resizedImage = img.copyResize(image!,
        width: _inputTensor.shape[1], height: _inputTensor.shape[2]);

    // Prepare input
    final imageMatrix = List.generate(
      resizedImage.height,
      (y) => List.generate(
        resizedImage.width,
        (x) {
          final pixel = resizedImage.getPixel(x, y);
          // Value between 0 to 1 per channel
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        },
      ),
    );

    final input = [imageMatrix];
    final output = [List<double>.filled(_outputTensor.shape[1], 0.0)];

    _interpreter.run(input, output);
    List<double> result = output.first;

    // Finds the predicted number that corresponds to the highest confidence
    // level of the prediction.
    int predictedNumber = 0;
    double maxConfidence = result[0];
    for (int i = 1; i < result.length; i++) {
      if (result[i] > maxConfidence) {
        maxConfidence = result[i]*100;
        predictedNumber = i;
      }
    }
    return (predictedNumber, maxConfidence);
  }
}
