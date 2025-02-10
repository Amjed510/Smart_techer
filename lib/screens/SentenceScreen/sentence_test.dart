import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:teatcher_smarter/providers/sentence_provider.dart';
import 'dart:math' as math;
import 'package:teatcher_smarter/widgets/result_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:teatcher_smarter/models_for_api/sentence_model.dart';
import 'package:teatcher_smarter/custom_widgets/general_custom_widgets.dart';

class SentenceTest extends StatefulWidget {
  final int level;

  const SentenceTest({Key? key, required this.level}) : super(key: key);

  @override
  State<SentenceTest> createState() => _SentenceTestState();
}

class _SentenceTestState extends State<SentenceTest> {
  late FlutterTts flutterTts;
  bool isSpeaking = false;
  bool isProcessing = false;
  int currentSentenceIndex = 0;
  bool isChecked = false;
  List<String> selectedWords = []; // تعديل selectedWords
  List<String> shuffledWords = []; // تعديل shuffledWords
  bool isInitialized = false;
  bool isTestCompleted = false;
  List<SentenceModel> _testSentences = [];

  // متغيرات الاختبار
  int correctAnswers = 0;
  int wrongAnswers = 0;
  bool canGoBack = false;
  Map<int, bool> answeredQuestions = {};

  // متغيرات حفظ التقدم
  int bestScore = 0;
  List<Map<String, dynamic>> testHistory = [];

  // الجمل التحفيزية
  List<String> correctMessages = [
    "أحسنتَ!",
    "رائع!",
    "أنت الأفضل!",
    "عمل ممتاز!",
    "ممتاز!"
  ];

  List<String> incorrectMessages = [
    "لا تقلق، حاول مرة أخرى.",
    "لا بأس عليك، استمر في المحاولة.",
    "حاول مجددًا، أنت قادر!",
    "لا تيأس، جرب مرة أخرى.",
    "أنت على الطريق الصحيح!"
  ];

  String? motivationalMessage;

  @override
  void initState() {
    super.initState();
    _initializeFlutterTts();
    _loadProgress();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _speakWelcomeMessage();
      await _initializeData();
    });
  }

  Future<void> _initializeFlutterTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("ar-SA");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);

    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
      });
    });
  }

  Future<void> speak(String text) async {
    if (isSpeaking) {
      await flutterTts.stop();
    }

    setState(() {
      isSpeaking = true;
      isProcessing = true;
    });

    await flutterTts.speak(text);

    setState(() {
      isProcessing = false;
    });
  }

  void _speakWelcomeMessage() {
    String levelName = '';
    switch (widget.level) {
      case 1:
        levelName = 'المبتدئ';
        break;
      case 2:
        levelName = 'المتوسط';
        break;
      case 3:
        levelName = 'المتقدم';
        break;
    }
    speak('مرحباً بك في اختبار كتابة الجمل في المستوى $levelName');
  }

  Future<void> _initializeData() async {
    final sentenceProvider = context.read<SentenceProvider>();
    // تحميل البيانات
    await sentenceProvider.loadLocalData();

    // فلترة الجمل حسب المستوى
    List<SentenceModel> filteredItems = sentenceProvider.items
        .where((item) => item.level == widget.level)
        .toList();

    // خلط ترتيب الجمل للاختبار
    filteredItems.shuffle();

    // تحديد عدد الجمل في الاختبار (مثلاً 10 جمل)
    final int testLength = math.min(10, filteredItems.length);
    filteredItems = filteredItems.take(testLength).toList();

    if (mounted && filteredItems.isNotEmpty) {
      setState(() {
        _testSentences = filteredItems;
        _initializeCurrentSentence();
        isInitialized = true;
      });
      await speak("قم بترتيب الجملة من الكلمات التالية");
    }
  }

  void _initializeCurrentSentence() {
    if (_testSentences.isEmpty) {
      setState(() {
        selectedWords = [];
        shuffledWords = [];
      });
      return;
    }

    setState(() {
      selectedWords = [];
      final sentence = _testSentences[currentSentenceIndex].text.trim();
      shuffledWords =
          sentence.split(' ').where((word) => word.isNotEmpty).toList();
      shuffledWords.shuffle();
    });
  }

  void _toggleWord(String word) {
    if (!answeredQuestions.containsKey(currentSentenceIndex)) {
      setState(() {
        if (selectedWords.contains(word)) {
          selectedWords.remove(word);
        } else {
          selectedWords.add(word);
        }
      });
    }
  }

  String _getGrade(double percentage) {
    if (percentage >= 90) return 'ممتاز';
    if (percentage >= 80) return 'جيد جداً';
    if (percentage >= 70) return 'جيد';
    if (percentage >= 60) return 'مقبول';
    return 'تحتاج إلى مزيد من التدريب';
  }

  Future<void> _checkAnswer() async {
    if (!isProcessing && !answeredQuestions.containsKey(currentSentenceIndex)) {
      setState(() {
        isProcessing = true;
      });

      String correctSentence = _testSentences[currentSentenceIndex].text.trim();
      String userSentence = selectedWords.join(' ').trim();
      bool isCorrect = correctSentence == userSentence;

      // تحديث الإحصائيات
      setState(() {
        if (isCorrect) {
          correctAnswers++;
        } else {
          wrongAnswers++;
        }
        answeredQuestions[currentSentenceIndex] = isCorrect;
      });

      await _showResultDialog(isCorrect);

      setState(() {
        isProcessing = false;
      });

      // التحقق مما إذا كان الاختبار قد انتهى
      if (currentSentenceIndex == _testSentences.length - 1) {
        setState(() {
          isTestCompleted = true;
        });
        await _showFinalResults();
      }
    }
  }

  Future<void> _showResultDialog(bool isCorrect) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResultDialog(
        isCorrect: isCorrect,
        message: isCorrect
            ? correctMessages[math.Random().nextInt(correctMessages.length)]
            : incorrectMessages[
                math.Random().nextInt(incorrectMessages.length)],
        onClose: () {
          Navigator.of(context).pop();
          if (!isTestCompleted) {
            nextSentence();
          }
        },
      ),
    );
  }

  void nextSentence() {
    if (currentSentenceIndex < _testSentences.length - 1) {
      setState(() {
        currentSentenceIndex++;
        _initializeCurrentSentence();
      });
      speak("قم بترتيب الجملة من الكلمات التالية");
    }
  }

  void previousSentence() {
    // لا يمكن العودة في وضع الاختبار
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // استخدام مفاتيح مختلفة للاختبار
      bestScore = prefs.getInt('test_bestScore_${widget.level}') ?? 0;

      // تحميل سجل الاختبارات السابقة
      final historyJson = prefs.getString('test_history_${widget.level}');
      if (historyJson != null) {
        final List<dynamic> decoded = json.decode(historyJson);
        testHistory = List<Map<String, dynamic>>.from(decoded);
      }
    });
  }

  Future<void> _saveProgress(double percentage) async {
    final prefs = await SharedPreferences.getInstance();

    // حفظ أفضل نتيجة للاختبار
    if ((percentage).round() > bestScore) {
      await prefs.setInt(
          'test_bestScore_${widget.level}', (percentage).round());
    }

    // حفظ سجل الاختبار الحالي
    final testResult = {
      'date': DateTime.now().toIso8601String(),
      'score': percentage,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'totalQuestions': correctAnswers + wrongAnswers,
    };

    testHistory.add(testResult);
    if (testHistory.length > 10) {
      // نحتفظ فقط بآخر 10 اختبارات
      testHistory.removeAt(0);
    }

    await prefs.setString(
        'test_history_${widget.level}', json.encode(testHistory));
  }

  Future<void> _showFinalResults() async {
    final totalQuestions = correctAnswers + wrongAnswers;
    final percentage = (correctAnswers / totalQuestions) * 100;
    final grade = _getGrade(percentage);

    // حفظ النتيجة
    await _saveProgress(percentage);

    // تحديث أفضل نتيجة إذا كانت النتيجة الحالية أفضل
    if ((percentage).round() > bestScore) {
      setState(() {
        bestScore = (percentage).round();
      });
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('نتيجة الاختبار', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'النتيجة النهائية',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'الإجابات الصحيحة: $correctAnswers',
              style: TextStyle(color: Colors.green),
              textAlign: TextAlign.center,
            ),
            Text(
              'الإجابات الخاطئة: $wrongAnswers',
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'النسبة المئوية: ${percentage.toStringAsFixed(1)}%',
              textAlign: TextAlign.center,
            ),
            if (bestScore > 0)
              Text(
                'أفضل نتيجة في الاختبار: $bestScore%',
                style: TextStyle(color: Colors.blue),
                textAlign: TextAlign.center,
              ),
            SizedBox(height: 10),
            Text(
              'التقدير: $grade',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: percentage >= 60 ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          if (testHistory.isNotEmpty)
            TextButton(
              onPressed: () => _showTestHistory(),
              child: Text('عرض سجل الاختبارات'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('إنهاء الاختبار'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTestHistory() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('سجل الاختبارات السابقة', textAlign: TextAlign.center),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: testHistory.length,
            itemBuilder: (context, index) {
              final test = testHistory[testHistory.length - 1 - index];
              final date = DateTime.parse(test['date']);
              final formattedDate = '${date.year}/${date.month}/${date.day}';
              return ListTile(
                title: Text('النتيجة: ${test['score'].toStringAsFixed(1)}%'),
                subtitle: Text('التاريخ: $formattedDate\n'
                    'الإجابات الصحيحة: ${test['correctAnswers']}\n'
                    'الإجابات الخاطئة: ${test['wrongAnswers']}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('اختبار الجمل'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        elevation: 0,
        title: Text(
          'اختبار الجمل',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // عداد الإجابات
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 4),
                Text('$correctAnswers',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.cancel, color: Colors.red),
                SizedBox(width: 4),
                Text('$wrongAnswers',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade100, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // استخدام custom widgets
                InstructionTextWidget(
                  title: 'قم بترتيب الجملة',
                  sentenceText: answeredQuestions[currentSentenceIndex] == true
                      ? _testSentences[currentSentenceIndex].text
                      : '',
                  titleColor: Colors.blue.shade900,
                  sentenceColor: Colors.green,
                  titleFontSize: 20,
                  sentenceFontSize: 24,
                ),
                SizedBox(height: 20),
                SortedSentenceWidget(
                  selectedWords: selectedWords,
                  textColor: Colors.black,
                  fontSize: 18,
                  placeholder: '____',
                ),
                ShuffledWordsWidget(
                  shuffledWords: shuffledWords,
                  selectedWords: selectedWords,
                  onWordTapped: _toggleWord,
                  buttonColor: Colors.blue,
                  selectedButtonColor: Colors.grey,
                  textColor: Colors.white,
                  fontSize: 20,
                ),
                SizedBox(height: 40),
                ListenButtonWidget(
                  isProcessing: isProcessing,
                  onPressed: () => speak("قم بترتيب الجملة من الكلمات التالية"),
                  buttonText: 'استمع',
                  icon: Icons.volume_up,
                  iconColor: Colors.blue,
                  textColor: Colors.blue,
                  buttonColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                SizedBox(height: 30),
                if (!answeredQuestions.containsKey(currentSentenceIndex))
                  CheckButtonWidget(
                    isProcessing: isProcessing,
                    isButtonEnabled: selectedWords.isNotEmpty,
                    onPressed: _checkAnswer,
                    buttonText: 'تحقق',
                    icon: Icons.check,
                    buttonColor: Colors.green,
                    textColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                SizedBox(height: 40),
                // التقدم في الاختبار
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text(
                        'السؤال ${currentSentenceIndex + 1} من ${_testSentences.length}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      SizedBox(height: 10),
                      LinearProgressIndicator(
                        value:
                            (currentSentenceIndex + 1) / _testSentences.length,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        minHeight: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }
}
