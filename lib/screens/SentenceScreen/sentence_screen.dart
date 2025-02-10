import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teatcher_smarter/custom_widgets/custom_app_bar.dart';
import 'package:teatcher_smarter/providers/sentence_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math';

import 'package:teatcher_smarter/providers/sentence_progress_provider.dart';
import 'package:teatcher_smarter/widgets/result_dialog.dart';
import 'package:teatcher_smarter/custom_widgets/general_custom_widgets.dart'; // استيراد ملف custom widgets

class SentenceScreen extends StatefulWidget {
  final int level;

  const SentenceScreen({Key? key, required this.level}) : super(key: key);

  @override
  _SentenceScreenState createState() => _SentenceScreenState();
}

class _SentenceScreenState extends State<SentenceScreen> {
  late SentenceProvider sentenceProvider;
  late SentenceProgressProvider progressProvider;
  late FlutterTts flutterTts;
  bool isSpeaking = false;
  bool isProcessing = false;
  int currentSentenceIndex = 0;
  bool isChecked = false;
  List<String> selectedWords = [];
  List<String> shuffledWords = [];
  bool isInitialized = false;

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
    sentenceProvider = Provider.of<SentenceProvider>(context, listen: false);
    progressProvider =
        Provider.of<SentenceProgressProvider>(context, listen: false);

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
    speak('مرحباً بك في تركيب الجمل في المستوى $levelName');
  }

  Future<void> _initializeData() async {
    await sentenceProvider.loadLocalData();
    await sentenceProvider.fetchAndSyncData();
    sentenceProvider.filterSentencesByLevel(widget.level);

    final lastSentenceId =
        await progressProvider.getLastAccessedSentence(widget.level);
    if (lastSentenceId != null) {
      final index = sentenceProvider.items
          .indexWhere((sentence) => sentence.id == lastSentenceId);
      if (index != -1) {
        currentSentenceIndex = index;
      }
    }

    if (mounted) {
      setState(() {
        _initializeCurrentSentence();
        isInitialized = true;
      });
    }
  }

  void _initializeCurrentSentence() {
    if (sentenceProvider.items.isEmpty) {
      setState(() {
        selectedWords = [];
        shuffledWords = [];
      });
      return;
    }

    final progressProvider =
        Provider.of<SentenceProgressProvider>(context, listen: false);
    final currentSentence = sentenceProvider.items[currentSentenceIndex];
    final isCompleted =
        progressProvider.isSentenceCompleted(currentSentence.id);

    // إذا كانت الجملة غير مكتملة، اعرض حقول فارغة
    if (!isCompleted) {
      setState(() {
        selectedWords = [];
        final sentence = currentSentence.text.trim();
        shuffledWords =
            sentence.split(' ').where((word) => word.isNotEmpty).toList();
        shuffledWords.shuffle();
      });
    } else {
      // إذا كانت الجملة مكتملة، اعرض الحل
      setState(() {
        final sentence = currentSentence.text.trim();
        selectedWords =
            sentence.split(' ').where((word) => word.isNotEmpty).toList();
        shuffledWords = [];
      });
    }
  }

  void _toggleWord(String word) {
    setState(() {
      if (selectedWords.contains(word)) {
        selectedWords.remove(word);
      } else {
        selectedWords.add(word);
      }
    });
  }

  Future<void> checkSentence() async {
    final originalSentence = sentenceProvider.items[currentSentenceIndex].text
        .trim(); // إزالة المسافات
    final userSentence = selectedWords.join(' ').trim();

    // استخدام ResultDialog لعرض النتيجة
    bool isCorrect = originalSentence == userSentence;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResultDialog(
        isCorrect: isCorrect,
        message: isCorrect
            ? correctMessages[Random().nextInt(correctMessages.length)]
            : incorrectMessages[Random().nextInt(incorrectMessages.length)],
        onClose: () {
          Navigator.of(context).pop();
          if (isCorrect) {
            // تحديث تقدم الجملة عند الإجابة الصحيحة
            progressProvider.updateSentenceProgress(
              sentenceId: sentenceProvider.items[currentSentenceIndex].id,
              isCorrect: true,
              level: widget.level,
            );

            // الانتقال إلى الجملة التالية تلقائياً
            if (currentSentenceIndex < sentenceProvider.items.length - 1) {
              nextSentence();
            }
          } else {
            setState(() {
              _initializeCurrentSentence();
            });
          }
        },
      ),
    );

    setState(() {
      isChecked = true;
      motivationalMessage = isCorrect
          ? correctMessages[Random().nextInt(correctMessages.length)]
          : incorrectMessages[Random().nextInt(incorrectMessages.length)];
      isProcessing = false;
    });

    if (isCorrect) {
      await speak("أحسنت!");
    } else {
      await speak("حاول مرة أخرى");
    }
  }

  // العثور على الجملة غير المكتملة التالية
  int _findNextUncompletedSentence() {
    final progressProvider =
        Provider.of<SentenceProgressProvider>(context, listen: false);
    for (int i = currentSentenceIndex + 1;
        i < sentenceProvider.items.length;
        i++) {
      if (!progressProvider.isSentenceCompleted(sentenceProvider.items[i].id)) {
        return i;
      }
    }
    return -1;
  }

  // التحقق مما إذا كان يمكن الانتقال إلى الجملة التالية
  bool get hasNextSentence {
    if (sentenceProvider.items.isEmpty ||
        currentSentenceIndex >= sentenceProvider.items.length - 1) {
      return false;
    }

    final progressProvider =
        Provider.of<SentenceProgressProvider>(context, listen: false);
    final currentSentenceCompleted = progressProvider
        .isSentenceCompleted(sentenceProvider.items[currentSentenceIndex].id);

    return currentSentenceCompleted;
  }

  void nextSentence() async {
    if (!hasNextSentence || sentenceProvider.items.isEmpty) return;

    final nextIndex = currentSentenceIndex + 1;
    if (nextIndex >= sentenceProvider.items.length) return;

    final progressProvider =
        Provider.of<SentenceProgressProvider>(context, listen: false);
    final nextSentence = sentenceProvider.items[nextIndex];
    await progressProvider.saveLastAccessedSentence(
        nextSentence.id, widget.level);

    setState(() {
      currentSentenceIndex = nextIndex;
      _initializeCurrentSentence();
    });
    await speak("قم بترتيب الجملة: ${nextSentence.text}");
  }

  void previousSentence() async {
    if (sentenceProvider.items.isEmpty) return;

    final prevIndex = _findPreviousCompletedSentence();
    if (prevIndex != -1) {
      final progressProvider =
          Provider.of<SentenceProgressProvider>(context, listen: false);
      final prevSentence = sentenceProvider.items[prevIndex];
      await progressProvider.saveLastAccessedSentence(
          prevSentence.id, widget.level);

      setState(() {
        currentSentenceIndex = prevIndex;
        _initializeCurrentSentence();
      });
      await speak("قم بترتيب الجملة: ${prevSentence.text}");
    }
  }

  // العثور على الجملة المكتملة السابقة
  int _findPreviousCompletedSentence() {
    final progressProvider =
        Provider.of<SentenceProgressProvider>(context, listen: false);
    for (int i = currentSentenceIndex - 1; i >= 0; i--) {
      if (progressProvider.isSentenceCompleted(sentenceProvider.items[i].id)) {
        return i;
      }
    }
    return -1;
  }

  void _checkAnswer() async {
    if (!isProcessing) {
      setState(() {
        isProcessing = true;
      });

      bool isCorrect = _validateAnswer();

      // تحديث تقدم المستخدم وحفظ آخر موقع
      final progressProvider =
          Provider.of<SentenceProgressProvider>(context, listen: false);
      final currentSentence = sentenceProvider.items[currentSentenceIndex];
      await progressProvider.updateSentenceProgress(
        sentenceId: currentSentence.id,
        isCorrect: isCorrect,
        level: widget.level,
      );

      // عرض رسالة النتيجة
      _showResultDialog(isCorrect);

      // إذا كانت الإجابة صحيحة، انتقل إلى الجملة غير المكتملة التالية
      if (isCorrect) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          final nextIndex = _findNextUncompletedSentence();
          if (nextIndex != -1) {
            final nextSentence = sentenceProvider.items[nextIndex];
            await progressProvider.saveLastAccessedSentence(
                nextSentence.id, widget.level);

            setState(() {
              currentSentenceIndex = nextIndex;
              _initializeCurrentSentence();
            });
            await speak("قم بترتيب الجملة: ${nextSentence.text}");
          } else {
            // إذا لم تكن هناك جمل غير مكتملة، اعرض رسالة تهنئة
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('أحسنت! لقد أكملت جميع الجمل في هذا المستوى'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        }
      }

      setState(() {
        isProcessing = false;
      });
    }
  }

  bool _validateAnswer() {
    final originalSentence =
        sentenceProvider.items[currentSentenceIndex].text.trim();
    final userSentence = selectedWords.join(' ').trim();
    return originalSentence == userSentence;
  }

  void _showResultDialog(bool isCorrect) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResultDialog(
        isCorrect: isCorrect,
        message: isCorrect
            ? correctMessages[Random().nextInt(correctMessages.length)]
            : incorrectMessages[Random().nextInt(incorrectMessages.length)],
        onClose: () {
          Navigator.of(context).pop();
          if (isCorrect &&
              currentSentenceIndex < sentenceProvider.items.length - 1) {
            // الانتقال إلى الجملة التالية تلقائياً بعد الإجابة الصحيحة
            nextSentence();
          } else {
            setState(() {
              _initializeCurrentSentence();
            });
          }
        },
      ),
    );
  }

  // عرض قائمة الجمل المكتملة
  void _showCompletedSentencesDialog() async {
    final progressProvider =
        Provider.of<SentenceProgressProvider>(context, listen: false);
    final completedSentences =
        await progressProvider.getCompletedSentences(widget.level);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('الجمل المكتملة', textAlign: TextAlign.center),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sentenceProvider.items.length,
            itemBuilder: (context, index) {
              final sentence = sentenceProvider.items[index];
              final isCompleted = completedSentences.contains(sentence.id);

              return ListTile(
                title: Text(
                  sentence.text,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: isCompleted ? Colors.green : Colors.grey,
                  ),
                ),
                leading: isCompleted
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : Icon(Icons.radio_button_unchecked, color: Colors.grey),
                onTap: isCompleted
                    ? () {
                        Navigator.pop(context);
                        setState(() {
                          currentSentenceIndex = index;
                          _initializeCurrentSentence();
                        });
                        speak("قم بترتيب الجملة: ${sentence.text}");
                      }
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized || sentenceProvider.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('تركيب الجمل'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: !isInitialized
              ? const CircularProgressIndicator()
              : const Text('لا توجد جمل متاحة لهذا المستوى'),
        ),
      );
    }

    final progressProvider = Provider.of<SentenceProgressProvider>(context);
    final isCurrentSentenceCompleted = progressProvider
        .isSentenceCompleted(sentenceProvider.items[currentSentenceIndex].id);
    final hasNextCompleted = hasNextSentence;
    final hasPreviousCompleted = _findPreviousCompletedSentence() != -1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        elevation: 0,
        title: Text(
          'تركيب الجمل',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // إضافة زر لعرض الجمل المكتملة
          IconButton(
            icon: Icon(Icons.list, color: Colors.black87),
            onPressed: _showCompletedSentencesDialog,
          ),
        ],
      ),
      body: Consumer<SentenceProvider>(
        builder: (context, provider, child) {
          if (provider.items.isEmpty) {
            return const Center(child: Text('لا توجد جمل متاحة'));
          }

          return Container(
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
                    // استخدام الـ custom widgets
                    InstructionTextWidget(
                      title: 'قم بترتيب الجملة',
                      sentenceText: provider.items[currentSentenceIndex].text,
                      titleColor: Colors.blue.shade900,
                      sentenceColor: Colors.grey.shade600,
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
                      selectedWords:
                          selectedWords, // مرر selectedWords من SentenceScreen
                      onWordTapped: _toggleWord,
                      buttonColor: Colors.blue,
                      selectedButtonColor: Colors.grey,
                      textColor: Colors.white,
                      fontSize: 20,
                    ),
                    SizedBox(height: 40),
                    ListenButtonWidget(
                      isProcessing: isProcessing,
                      onPressed: () =>
                          speak(provider.items[currentSentenceIndex].text),
                      buttonText: 'استمع',
                      icon: Icons.volume_up,
                      iconColor: Colors.blue,
                      textColor: Colors.blue,
                      buttonColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    SizedBox(height: 30),
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
                    NavigationButtonsWidget(
                      hasPrevious: hasPreviousCompleted,
                      hasNext: hasNextCompleted,
                      onPreviousPressed: previousSentence,
                      onNextPressed: nextSentence,
                      previousButtonText: 'السابق',
                      nextButtonText: 'التالي',
                      previousIcon: Icons.arrow_back_ios,
                      nextIcon: Icons.arrow_forward_ios,
                      activeColor: Colors.blue,
                      inactiveColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 10),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }
}
