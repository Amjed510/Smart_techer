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
      ..strokeWidth = 12.0
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

class DrawingTestScreen extends StatefulWidget {
  const DrawingTestScreen({super.key});

  @override
  _DrawingTestScreenState createState() => _DrawingTestScreenState();
}

class _DrawingTestScreenState extends State<DrawingTestScreen> {
  List<Offset?> points = [];
  List? _outputs;
  bool _loading = false;
  late Interpreter _interpreter;
  List<String> _labels = [];
  static const int inputSize = 224;
  int batchSize = 1;
  int _currentLetterIndex = 0;
  bool _success = false;
  late FlutterTts flutterTts;
  int _correctCount = 0;
  int _attempts = 0;
  List<bool> _completedLetters = []; // قائمة لتتبع الحروف المكتملة

  static const String _progressKey = 'currentLetterIndex';
  static const String _scoreKey = 'correctCount';
  static const String _completedLettersKey = 'completedLetters';

  @override
  void initState() {
    super.initState();
    _loading = true;
    _loadProgress();
    loadModel().then((_) {
      setState(() {
        _loading = false;
        if (_labels.isNotEmpty) {
          _speakCurrentLetter();
          _completedLetters = List.generate(_labels.length, (index) => false);
          _loadCompletedLetters();
        }
      });
    });
    initTts();
  }

  Future<void> _loadCompletedLetters() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList(_completedLettersKey);
    if (completed != null) {
      setState(() {
        _completedLetters = completed.map((e) => e == 'true').toList();
      });
    }
  }

  Future<void> _saveCompletedLetters() async {
    final prefs = await SharedPreferences.getInstance();
    final completedStrings =
        _completedLetters.map((e) => e.toString()).toList();
    prefs.setStringList(_completedLettersKey, completedStrings);
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLetterIndex = prefs.getInt(_progressKey) ?? 0;
      _correctCount = prefs.getInt(_scoreKey) ?? 0;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_progressKey, _currentLetterIndex);
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

  Future<void> _speakCurrentLetter() async {
    if (_labels.isNotEmpty && _currentLetterIndex < _labels.length) {
      await Future.delayed(const Duration(milliseconds: 500));
      await flutterTts.speak(_labels[_currentLetterIndex]);
    }
  }

  Future<void> _speakMessage(String message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    await flutterTts.speak(message);
  }

  void _moveToPreviousLetter() {
    if (_currentLetterIndex > 0 && _completedLetters[_currentLetterIndex - 1]) {
      setState(() {
        _currentLetterIndex--;
        _saveProgress();
        points.clear();
        _outputs = null;
        _success = false;
        _attempts = 0;
        if (_labels.isNotEmpty) {
          _speakCurrentLetter();
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكنك الرجوع إلى حرف لم يتم حله بعد!'),
        ),
      );
    }
  }

  void _moveToNextLetter({bool fromCompletion = false}) {
    if (_currentLetterIndex < _labels.length - 1) {
      setState(() {
        if (fromCompletion && _currentLetterIndex < _labels.length - 1) {
          _completedLetters[_currentLetterIndex] = true;
          _saveCompletedLetters();
          _currentLetterIndex++;
        } else if (!fromCompletion &&
            _currentLetterIndex < _labels.length - 1 &&
            _completedLetters[_currentLetterIndex]) {
          _currentLetterIndex++;
        }
        _saveProgress();

        points.clear();
        _outputs = null;
        _success = false;
        _attempts = 0;

        if (!fromCompletion &&
            _labels.isNotEmpty &&
            _completedLetters[_currentLetterIndex]) {
          _speakCurrentLetter();
        }
        if (_currentLetterIndex >= _labels.length) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('تهانينا! 🎉'),
              content: Text(
                  'لقد أكملت جميع الحروف بنجاح!  عدد الحروف الصحيحة: $_correctCount'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _currentLetterIndex = 0;
                      _correctCount = 0;
                      _completedLetters =
                          List.generate(_labels.length, (index) => false);
                      _saveProgress();
                      _saveCompletedLetters();
                      _saveScore();
                    });
                  },
                  child: const Text('ابدأ من جديد'),
                ),
              ],
            ),
          );
        }
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تهانينا! 🎉'),
          content: Text(
              'لقد أكملت جميع الحروف بنجاح!  عدد الحروف الصحيحة: $_correctCount'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _currentLetterIndex = 0;
                  _correctCount = 0;
                  _completedLetters =
                      List.generate(_labels.length, (index) => false);
                  _saveProgress();
                  _saveCompletedLetters();
                  _saveScore();
                });
              },
              child: const Text('ابدأ من جديد'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> loadModel() async {
    try {
      _interpreter =
          await Interpreter.fromAsset('assets/model_unquant1.tflite');
      final labelData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelData.split('\n');
      print('Labels loaded: $_labels'); // إضافة طباعة للتأكد من التحميل
      print('Number of labels: ${_labels.length}');

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

      var output = List.generate(batchSize, (index) => List.filled(28, 0.0));
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
      var isCorrectLetter = topResult["index"] == _currentLetterIndex;
      var confidence = topResult["confidence"];

      setState(() {
        _loading = false;
      });

      _attempts++;
      if (confidence > 0.5 && isCorrectLetter) {
        _success = true;
        _correctCount++;
        _saveScore();

        _outputs = [
          {
            "label": _labels[_currentLetterIndex],
            "confidence": confidence,
            "isCorrect": true,
          }
        ];

        String stars = '';
        if (_attempts == 1) {
          stars = '⭐⭐⭐';
        } else if (_attempts == 2) {
          stars = '⭐⭐';
        } else {
          stars = '⭐';
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'أحسنت! $stars',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
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
                      'لقد رسمت حرف ${_labels[_currentLetterIndex]} بشكل صحيح',
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
                    _moveToNextLetter(fromCompletion: true);
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/pencil_icon.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 12),
            const Text(
              'اختبار رسم الحروف',
              style: TextStyle(
                color: Color(0xFF2C3E50),
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'التقدم: ${_currentLetterIndex + 1}/${_labels.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      Text(
                        'النقاط: $_correctCount',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _labels.isNotEmpty
                        ? (_currentLetterIndex + 1) / _labels.length
                        : 0,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF3498DB),
                    ),
                    borderRadius: BorderRadius.circular(10),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Current Letter Display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _labels.isNotEmpty && _currentLetterIndex < _labels.length
                        ? 'ارسم الحرف'
                        : 'جاري التحميل...',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _labels.isNotEmpty && _currentLetterIndex < _labels.length
                        ? "" //_labels[_currentLetterIndex]
                        : '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3498DB),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Drawing Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3498DB), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
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
            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed:
                            _labels.isNotEmpty ? _speakCurrentLetter : null,
                        icon: const Icon(Icons.volume_up,
                            color: Colors.white, size: 24),
                        label: const Text('استمع',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3498DB),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: points.isNotEmpty
                              ? () {
                                  setState(() {
                                    points.clear();
                                    _outputs = null;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.refresh,
                              color: Colors.white, size: 24),
                          label: const Text('إعادة',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE74C3C),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: points.isNotEmpty ? predictDrawing : null,
                          icon: const Icon(Icons.check,
                              color: Colors.white, size: 24),
                          label: const Text('تحقق',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2ECC71),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
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
