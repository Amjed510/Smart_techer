import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DrawingPainter extends CustomPainter {
  final List<Offset?> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}

class NumberDrawingScreen extends StatefulWidget {
  const NumberDrawingScreen({super.key});

  @override
  _NumberDrawingScreenState createState() => _NumberDrawingScreenState();
}

class _NumberDrawingScreenState extends State<NumberDrawingScreen> {
  List<Offset?> points = [];
  List? _outputs;
  bool _loading = false;
  late Interpreter _interpreter;
  List<String> _labels = [];
  static const int inputSize = 244;
  int batchSize = 1;
  int _currentNumberIndex = 0;
  bool _success = false;
  late FlutterTts flutterTts;
  int _correctCount = 0;
  int _attempts = 0;
  List<bool> _completedNumbers = [];
  static const String _progressKey = 'drawingScreenNumberProgress';
  static const String _scoreKey = 'drawingScreenNumberScore';
  static const String _completedNumbersKey = 'drawingScreenCompletedNumbers';

  List<String> _encouragementMessages = [
    "أحسنت! استمر في التقدم",
    "ممتاز! أنت تتعلم بسرعة",
    "رائع! انتقل إلى الرقم التالي",
    "جميل جداً! واصل التقدم",
    "ما شاء الله! أداء رائع",
    "أنت موهوب جداً!",
    "استمر هكذا، أنت تتحسن",
    "كتابة جميلة! أحسنت",
  ];

  List<String> _instructionMessages = [
    "ارسم الرقم",
    "حاول رسم الرقم",
    "اكتب الرقم",
    "دعنا نتعلم كتابة رقم",
  ];

  @override
  void initState() {
    super.initState();
    _loading = true;
    _loadProgress();
    loadModel().then((value) {
      setState(() {
        _loading = false;
        if (_labels.isNotEmpty) {
          _speakInstructions();
          _completedNumbers = List.generate(_labels.length, (index) => false);
          _loadCompletedNumbers();
        }
      });
    });
    initTts();
  }

  Future<void> _loadCompletedNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList(_completedNumbersKey);
    if (completed != null) {
      setState(() {
        _completedNumbers = completed.map((e) => e == 'true').toList();
      });
    }
  }

  Future<void> _saveCompletedNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    final completedStrings =
        _completedNumbers.map((e) => e.toString()).toList();
    prefs.setStringList(_completedNumbersKey, completedStrings);
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentNumberIndex = prefs.getInt(_progressKey) ?? 0;
      _correctCount = prefs.getInt(_scoreKey) ?? 0;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_progressKey, _currentNumberIndex);
  }

  Future<void> _saveScore() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_scoreKey, _correctCount);
  }

  void initTts() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage("ar-SA");
    flutterTts.setSpeechRate(0.5);
    flutterTts.setPitch(1.0);
    flutterTts.setVolume(1.0);
  }

  Future<void> _speakInstructions() async {
    if (_labels.isEmpty) return;

    final random = Random();
    String instruction =
        _instructionMessages[random.nextInt(_instructionMessages.length)];
    await flutterTts.speak("$instruction ${_labels[_currentNumberIndex]}");
  }

  Future<void> _speakCurrentNumber() async {
    if (_labels.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      await flutterTts.speak(_labels[_currentNumberIndex]);
    }
  }

  Future<void> _speakMessage(String message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    await flutterTts.speak(message);
  }

  String _getRandomEncouragement() {
    final random = Random();
    return _encouragementMessages[
        random.nextInt(_encouragementMessages.length)];
  }

  void _moveToNextNumber() {
    setState(() {
      if (_currentNumberIndex < _labels.length - 1) {
        _currentNumberIndex++;
        _speakInstructions();
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تهانينا! '),
            content: const Text('لقد أكملت جميع الأرقام بنجاح!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _currentNumberIndex = 0;
                    _speakInstructions();
                  });
                },
                child: const Text('ابدأ من جديد'),
              ),
            ],
          ),
        );
      }
      points.clear();
      _outputs = null;
      _success = false;
    });
  }

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/numbers_model.tflite');
      final labelData = await rootBundle.loadString('assets/labelsNum.txt');
      _labels = labelData.split('\n');

      var inputShape = _interpreter.getInputTensor(0).shape;
      batchSize = inputShape[0];
      print('Batch size from model: $batchSize');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<void> predictDrawing() async {
    if (_labels.isEmpty) {
      print('Error: Labels not loaded yet.');
      return;
    }
    setState(() {
      _loading = true;
    });

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(300, 250);

      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );

      DrawingPainter(points).paint(canvas, size);

      final picture = recorder.endRecording();
      final image =
          await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) return;

      img.Image resizedImage =
          img.copyResize(originalImage, width: inputSize, height: inputSize);

      var inputArray = Float32List(batchSize * inputSize * inputSize * 3);

      for (var batch = 0; batch < batchSize; batch++) {
        var batchOffset = batch * inputSize * inputSize * 3;
        for (var y = 0; y < inputSize; y++) {
          for (var x = 0; x < inputSize; x++) {
            var pixel = resizedImage.getPixel(x, y);
            var pixelOffset = batchOffset + (y * inputSize + x) * 3;
            inputArray[pixelOffset] = (pixel.r.toDouble() - 127.5) / 127.5;
            inputArray[pixelOffset + 1] = (pixel.g.toDouble() - 127.5) / 127.5;
            inputArray[pixelOffset + 2] = (pixel.b.toDouble() - 127.5) / 127.5;
          }
        }
      }

      var output = List.generate(batchSize, (index) => List.filled(10, 0.0));
      _interpreter.run(
          inputArray.reshape([batchSize, inputSize, inputSize, 3]), output);

      var firstResult = output[0];
      var results = <Map<String, dynamic>>[];
      for (var i = 0; i < firstResult.length; i++) {
        results.add(
            {"index": i, "label": _labels[i], "confidence": firstResult[i]});
      }

      results.sort((a, b) => b["confidence"].compareTo(a["confidence"]));

      var topResult = results[0];
      var isCorrectNumber = topResult["index"] == _currentNumberIndex;
      var confidence = topResult["confidence"];

      setState(() {
        _loading = false;
      });

      _attempts++;
      if (confidence > 0.5 && isCorrectNumber) {
        _success = true;
        _correctCount++;
        _saveScore();

        String stars = '';
        if (_attempts == 1) {
          stars = '⭐⭐⭐';
        } else if (_attempts == 2) {
          stars = '⭐⭐';
        } else {
          stars = '⭐';
        }

        var message = _getRandomEncouragement();
        _outputs = [
          {
            "label": _labels[_currentNumberIndex],
            "confidence": confidence,
            "isCorrect": true,
            "message": message,
          }
        ];

        await _speakMessage(
            "$message! لقد رسمت رقم ${_labels[_currentNumberIndex]} بشكل صحيح");

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('أحسنت! $stars'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      'assets/correct_animation.json',
                      height: 100,
                      repeat: true,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'لقد رسمت رقم ${_labels[_currentNumberIndex]} بشكل صحيح',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('التالي'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (_currentNumberIndex < _labels.length - 1) {
                      _completedNumbers[_currentNumberIndex] = true;
                      _saveCompletedNumbers();
                      _currentNumberIndex++;
                      _saveProgress();
                      _speakInstructions();
                      setState(() {
                        points.clear();
                        _outputs = null;
                        _success = false;
                        _attempts = 0;
                      });
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('تهانينا! 🎉'),
                          content: Text(
                              'لقد أكملت جميع الأرقام بنجاح! عدد الأرقام الصحيحة: $_correctCount'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                setState(() {
                                  _currentNumberIndex = 0;
                                  _correctCount = 0;
                                  _completedNumbers = List.generate(
                                      _labels.length, (index) => false);
                                  _saveProgress();
                                  _saveCompletedNumbers();
                                  _saveScore();
                                });
                              },
                              child: const Text('ابدأ من جديد'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      } else {
        _success = false;
        var incorrectMessage = "حاول مرة أخرى!";
        _outputs = [
          {
            "label": _labels[topResult["index"]],
            "confidence": confidence,
            "isCorrect": false,
            "message": incorrectMessage,
          }
        ];

        await _speakMessage(incorrectMessage);

        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('حاول مرة أخرى 💪'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      'assets/incorrect_animation.json',
                      height: 100,
                      repeat: true,
                    ),
                    const SizedBox(height: 10),
                    Text(incorrectMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.orange,
                        )),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('حسناً'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      points.clear();
                      _outputs = null;
                    });
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error predicting drawing: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/pen.png',
              height: 30,
              width: 30,
            ),
            const SizedBox(width: 8),
            const Text(
              'رسم الأرقام',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.grey.shade100,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return Column(
              children: [
                const SizedBox(height: 20),
                Expanded(
                  child: FractionallySizedBox(
                    widthFactor: 0.6,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: _labels.isNotEmpty
                            ? Image.asset(
                                'assets/image_numbers/${_labels[_currentNumberIndex]}.png',
                                fit: BoxFit.contain,
                                errorBuilder: (BuildContext context,
                                    Object exception, StackTrace? stackTrace) {
                                  return Text(
                                    _labels[_currentNumberIndex],
                                    style: TextStyle(
                                      fontSize:
                                          orientation == Orientation.portrait
                                              ? screenWidth * 0.2
                                              : screenWidth * 0.15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  );
                                },
                              )
                            : const SizedBox(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  fit: FlexFit.loose,
                  child: Container(
                    height: screenHeight * 0.4,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: GestureDetector(
                        onPanStart: (details) {
                          setState(() {
                            points.add(details.localPosition);
                          });
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            points.add(details.localPosition);
                          });
                        },
                        onPanEnd: (details) {
                          setState(() {
                            points.add(null);
                          });
                        },
                        child: CustomPaint(
                          painter: DrawingPainter(points),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: points.isNotEmpty
                            ? () {
                                setState(() {
                                  points.clear();
                                  _outputs = null;
                                });
                              }
                            : null,
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 30,
                        ),
                        label: const Text('',
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF08080),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up,
                            color: Colors.blue, size: 35),
                        onPressed: _speakCurrentNumber,
                        tooltip: 'استمع مرة أخرى',
                      ),
                      ElevatedButton.icon(
                        onPressed: points.isNotEmpty ? predictDrawing : null,
                        icon: const Icon(Icons.check,
                            color: Colors.white, size: 30),
                        label: const Text('',
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF90EE90),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _interpreter.close();
    flutterTts.stop();
    super.dispose();
  }
}
