import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teatcher_smarter/custom_widgets/custom_app_bar.dart';
import 'package:teatcher_smarter/models_for_api/word_model.dart';
import 'package:teatcher_smarter/providers/word_provider.dart';
import 'package:teatcher_smarter/providers/word_progress_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';

import 'package:teatcher_smarter/widgets/result_dialog.dart';
import 'package:teatcher_smarter/custom_widgets/general_custom_widgets.dart';

class WordTestScreen extends StatefulWidget {
  final int level;

  const WordTestScreen({Key? key, required this.level}) : super(key: key);

  @override
  _WordTestScreenState createState() => _WordTestScreenState();
}

class _WordTestScreenState extends State<WordTestScreen> {
  late WordsProvider wordsProvider;
  late FlutterTts flutterTts;
  WordModel? currentWord;
  List<String> shuffledLetters = [];
  String assembledWord = '';
  bool isProcessing = false;
  bool isWordModified = false;
  bool isSpeaking = false;
  Set<String> selectedLetters = {};
  int score = 0;
  int totalQuestions = 0;

  @override
  void initState() {
    super.initState();
    wordsProvider = Provider.of<WordsProvider>(context, listen: false);
    _initializeWords();
    _initializeFlutterTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakWelcomeMessage();
    });
  }

  void _initializeWords() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await wordsProvider.loadLocalData();
      await wordsProvider.fetchAndSyncData();
      wordsProvider.filterByLevel(widget.level);
      if (mounted) {
        setState(() {
          currentWord = wordsProvider.currentWord;
          if (currentWord != null) {
            _initializeShuffledLetters(currentWord!.text);
          }
        });
      }
    });
  }

  Future<void> _initializeFlutterTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("ar-SA");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    flutterTts.awaitSpeakCompletion(true);
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
      isProcessing = true;
      isSpeaking = true;
    });
    await flutterTts.speak(text);
    setState(() {
      isProcessing = false;
      isSpeaking = false;
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
    speak('مرحباً بك في اختبار كتابة الكلمات في المستوى $levelName');
  }

  void _initializeShuffledLetters(String word) {
    if (word.isNotEmpty) {
      setState(() {
        shuffledLetters = List.from(word.split(''))..shuffle();
        assembledWord = '';
        selectedLetters.clear();
        isWordModified = false;
      });
    }
  }

  void _handleLetterTap(String letter) {
    setState(() {
      if (selectedLetters.contains(letter)) {
        selectedLetters.remove(letter);
        int lastIndex = assembledWord.lastIndexOf(letter);
        if (lastIndex != -1) {
          assembledWord = assembledWord.substring(0, lastIndex) +
              assembledWord.substring(lastIndex + 1);
        }
      } else {
        selectedLetters.add(letter);
        assembledWord += letter;
      }
      isWordModified = assembledWord.isNotEmpty;
    });
  }

  void _checkAnswer() async {
    if (assembledWord.isEmpty) return;

    setState(() {
      isProcessing = true;
    });

    if (currentWord != null) {
      bool isCorrect = assembledWord == currentWord!.text;

      // عرض الـ Dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ResultDialog(
          isCorrect: isCorrect,
          message: isCorrect ? "أحسنت!" : "حاول مرة أخرى",
          onClose: () {
            Navigator.of(context).pop();
            if (isCorrect) {
              wordsProvider.markWordAsCompleted(currentWord!);
              setState(() {
                score++;
              });
              // الانتقال إلى الكلمة التالية تلقائياً عند الإجابة الصحيحة
              if (wordsProvider.hasNextWord()) {
                wordsProvider.nextWord();
                setState(() {
                  currentWord = wordsProvider.currentWord;
                  if (currentWord != null) {
                    _initializeShuffledLetters(currentWord!.text);
                  }
                });
              } else {
                // إذا كانت آخر كلمة، نعرض نتيجة الاختبار
                _showTestResult();
              }
            } else {
              setState(() {
                assembledWord = '';
                selectedLetters.clear();
              });
            }
            totalQuestions++;
            setState(() {
              isProcessing = false;
              isWordModified = false;
            });
          },
        ),
      );

      if (isCorrect) {
        await speak("أحسنت!");
      } else {
        await speak("حاول مرة أخرى");
      }
    }
  }

  void _resetShuffledLetters() {
    if (currentWord != null) {
      _initializeShuffledLetters(currentWord!.text);
    }
  }

  void _showTestResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('نتيجة الاختبار'),
        content: Text(
          'لقد أكملت الاختبار!\nالنتيجة: $score/$totalQuestions',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _restartTest();
            },
            child: const Text('إعادة الاختبار'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('العودة للقائمة'),
          ),
        ],
      ),
    );
  }

  void _restartTest() {
    wordsProvider.filterByLevel(widget.level);
    if (currentWord != null) {
      _initializeShuffledLetters(currentWord!.text);
    }
    setState(() {
      score = 0;
      totalQuestions = 0;
      isProcessing = false;
      isWordModified = false;
      assembledWord = '';
      selectedLetters.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<WordsProvider, WordProgressProvider>(
      builder: (context, wordsProvider, progressProvider, child) {
        // تحديث currentWord عندما يتغير في Provider
        if (currentWord != wordsProvider.currentWord) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                currentWord = wordsProvider.currentWord;
                if (currentWord != null) {
                  _initializeShuffledLetters(currentWord!.text);
                }
              });
            }
          });
        }

        if (currentWord == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final wordProgress = progressProvider.getWordProgress(currentWord!.id);
        final attempts = progressProvider.getWordAttempts(currentWord!.id);
        final successRate =
            progressProvider.getWordSuccessRate(currentWord!.id);
        final isMastered = progressProvider.isWordMastered(currentWord!.id);

        return Scaffold(
          appBar: CustomAppBar(
            title: 'اختبار الكلمات - المستوى ${widget.level + 1}',
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.grey.shade100, Colors.white],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('المحاولات'),
                                  Text('$attempts'),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text('نسبة النجاح'),
                                  Text(
                                      '${(successRate * 100).toStringAsFixed(1)}%'),
                                ],
                              ),
                              if (isMastered)
                                const Icon(Icons.star, color: Colors.amber),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'النتيجة: $score/$totalQuestions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      if (currentWord!.image.isNotEmpty)
                        Container(
                          height: 180,
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.memory(
                              base64.decode(currentWord!.image),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      AssembledWordWidget(
                        assembledWord: assembledWord,
                        textColor: Colors.black87,
                        fontSize: 32,
                        placeholder: '____',
                      ),
                      SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: shuffledLetters.map((letter) {
                          bool isSelected = selectedLetters.contains(letter);
                          return LetterWidget(
                            letter: letter,
                            isSelected: isSelected,
                            onTap: () => _handleLetterTap(letter),
                            selectedColor: Colors.grey.shade400,
                            defaultColor: Colors.blue,
                            fontSize: 24,
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 20),

                      //    زر الاستماع
                      ListenButtonWidget(
                        isProcessing: isProcessing,
                        onPressed: () {
                          if (currentWord != null) {
                            speak(currentWord!.text);
                          }
                        },
                        buttonText: 'استمع',
                        icon: Icons.volume_up,
                        iconColor: Colors.blue,
                        textColor: Colors.blue,
                        buttonColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                      ),
                      SizedBox(height: 20),
                      CheckButtonWidget(
                        isProcessing: isProcessing,
                        isButtonEnabled: assembledWord.isNotEmpty,
                        onPressed: _checkAnswer,
                        buttonText: 'تحقق',
                        icon: Icons.check,
                        buttonColor: Colors.green,
                        textColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      SizedBox(height: 20),
                      NavigationButtonsWidget(
                        hasPrevious: wordsProvider.hasPreviousWord(),
                        hasNext: wordsProvider.hasNextWord() &&
                            currentWord != null &&
                            wordsProvider.isWordCompleted(currentWord!),
                        onPreviousPressed: () {
                          wordsProvider.previousWord();
                          setState(() {
                            currentWord = wordsProvider.currentWord;
                            if (currentWord != null) {
                              _initializeShuffledLetters(currentWord!.text);
                            }
                          });
                        },
                        onNextPressed: () {
                          wordsProvider.nextWord();
                          setState(() {
                            currentWord = wordsProvider.currentWord;
                            if (currentWord != null) {
                              _initializeShuffledLetters(currentWord!.text);
                            }
                          });
                        },
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
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }
}