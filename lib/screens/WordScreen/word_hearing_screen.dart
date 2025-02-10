import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:teatcher_smarter/custom_widgets/custom_app_bar.dart';
import 'package:teatcher_smarter/providers/word_provider.dart';

class WordHearingScreen extends StatefulWidget {
  final int level;

  const WordHearingScreen({Key? key, required this.level}) : super(key: key);

  @override
  State<WordHearingScreen> createState() => _WordHearingScreenState();
}

class _WordHearingScreenState extends State<WordHearingScreen> {
  late FlutterTts flutterTts;
  bool isSpeaking = false;
  int currentIndex = 0;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _initializeFlutterTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakWelcomeMessage();
      _initializeWords();
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
    });

    await flutterTts.speak(text);
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
    speak('مرحباً بك في اختبار الاستماع للكلمات في المستوى $levelName');
  }

  Future<void> _initializeWords() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final wordsProvider = Provider.of<WordsProvider>(context, listen: false);
      await wordsProvider.loadLocalData();
      if (wordsProvider.items.isEmpty) {
        await wordsProvider.fetchAndSyncData();
      }
      if (mounted && wordsProvider.items.isNotEmpty) {
        await speakCurrentWord();
      }
    });
  }

  Future<void> speakCurrentWord() async {
    if (!mounted) return;

    final wordsProvider = Provider.of<WordsProvider>(context, listen: false);
    final levelWords = wordsProvider.items
        .where((word) => word.level == widget.level)
        .toList();

    if (levelWords.isEmpty || currentIndex >= levelWords.length) return;

    setState(() {
      isSpeaking = true;
    });

    await flutterTts.speak("الكلمة هي ${levelWords[currentIndex].text}");
    await flutterTts.awaitSpeakCompletion(true);

    if (mounted) {
      setState(() {
        isSpeaking = false;
      });
    }
  }

  void previousWord() {
    setState(() {
      if (currentIndex > 0) {
        currentIndex--;
        speakCurrentWord();
      }
    });
  }

  void nextWord() {
    final wordsProvider = Provider.of<WordsProvider>(context, listen: false);
    final levelWords = wordsProvider.items
        .where((word) => word.level == widget.level)
        .toList();

    setState(() {
      if (currentIndex < levelWords.length - 1) {
        currentIndex++;
        speakCurrentWord();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'استماع الكلمات'),
      body: Consumer<WordsProvider>(
        builder: (context, wordsProvider, child) {
          final levelWords = wordsProvider.items
              .where((word) => word.level == widget.level)
              .toList();

          if (wordsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (levelWords.isEmpty) {
            return const Center(
                child: Text('لا توجد كلمات متاحة لهذا المستوى'));
          }

          final currentWord = levelWords[currentIndex];
          final wordImage = currentWord.image != null
              ? base64Decode(currentWord.image!)
              : null;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey.shade100,
                  Colors.white,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Progress indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'الكلمة ${currentIndex + 1} من ${levelWords.length}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Word image
                  if (wordImage != null)
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.memory(
                          wordImage,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),

                  // Word text
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      currentWord.text,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildNavigationButton(
                        icon: Icons.arrow_back_ios,
                        onPressed: currentIndex > 0 ? previousWord : null,
                      ),
                      const SizedBox(width: 20),
                      _buildSpeakButton(
                        isSpeaking: isSpeaking,
                        onPressed: isSpeaking ? null : () => speakCurrentWord(),
                      ),
                      const SizedBox(width: 20),
                      _buildNavigationButton(
                        icon: Icons.arrow_forward_ios,
                        onPressed: currentIndex < levelWords.length - 1
                            ? nextWord
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed != null ? Colors.blue : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(15),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        iconSize: 30,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildSpeakButton({
    required bool isSpeaking,
    VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed != null ? Colors.grey.shade100 : Colors.blue.shade100,
        borderRadius: BorderRadius.circular(15),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: IconButton(
        icon: Icon(
          isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
          color: Colors.blue,
        ),
        onPressed: onPressed,
        iconSize: 35,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }
}
