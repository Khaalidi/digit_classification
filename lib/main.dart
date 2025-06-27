import 'dart:ui' as ui;
import 'digit_classifier_helper.dart';
import 'sketcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() {
  runApp(const MyHomePage());
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Offset?> _points = <Offset?>[];
  final GlobalKey _globalKey = GlobalKey();
  late DigitClassifierHelper _digitClassifierHelper;
  int? _predictedNumber;
  double? _predictedConfidence;
  int _inferenceTime = 0;

  @override
  void initState() {
    _digitClassifierHelper = DigitClassifierHelper();
    _digitClassifierHelper.init();
    super.initState();
  }

  Future<void> _predictNumber() async {
    // capture sketch area
    RenderRepaintBoundary boundary =
        _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final inputImageData = byteData?.buffer.asUint8List();

    final stopwatch = Stopwatch()..start();
    final (number, confidence) =
        await _digitClassifierHelper.runInference(inputImageData!);
    stopwatch.stop();

    setState(() {
      _predictedNumber = number;
      _predictedConfidence = confidence;
      _inferenceTime = stopwatch.elapsedMilliseconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Digit Classification"),
      ),
      body: Center(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: sketchArea(),
            ),
            Expanded(
                child: Align(
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Spacer(),
                  const Text("Predicted number:"),
                  if (_predictedNumber != null && _predictedConfidence != null)
                    Text(
                        "$_predictedNumber (${_predictedConfidence?.toStringAsFixed(1)}%)",),
                  const Spacer(),
                  Text("Inference Time: $_inferenceTime (ms)"),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: TextButton(
                        onPressed: () {
                          // clear drawing here
                          setState(() {
                            _points = [];
                          });
                        },
                        child: const Text("Clear")),
                  )
                ],
              ),
            ))
          ],
        ),
      ),
    ));
  }

  Widget sketchArea() {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return GestureDetector(
        onPanUpdate: (DragUpdateDetails details) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          Offset point = details.localPosition;

          // prevent draw outside sketch area
          double x = point.dx.clamp(0, width);
          double y = point.dy.clamp(0, height);
          point = Offset(x, y);
          setState(() {
            _points = List.from(_points)..add(point);
          });
        },
        onPanEnd: (DragEndDetails details) {
          _points.add(null);
          _predictNumber();
        },


        onPanStart: (DragStartDetails details) {
          final point = details.localPosition;
          setState(() {
            _points = [point];
          });
        },
        child: RepaintBoundary(
            key: _globalKey,
            child: Container(
                color: Colors.black,
                child: CustomPaint(
                  painter: Sketcher(_points),
                ))),
      );
    });
  }
}
