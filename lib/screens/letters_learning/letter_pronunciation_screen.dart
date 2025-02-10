import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/letter_model.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:string_similarity/string_similarity.dart';

class Letterpronunciationscreen extends StatefulWidget {
  @override
  _LetterpronunciationscreenState createState() =>
      _LetterpronunciationscreenState();
}

class _LetterpronunciationscreenState extends State<Letterpronunciationscreen> {
  late FlutterTts flutterTts;
  late stt.SpeechToText speech;
  bool isListening = false;
  String resultText = '';

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    speech = stt.SpeechToText();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    String language = "ar-YE";
    await flutterTts.setLanguage(language);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> speakText(String text) async {
    await flutterTts.speak(text);
  }

  void startListening(String correctPronunciation) async {
    if (speech.isListening) {
      await speech.stop();
      setState(() => isListening = false);
    }

    bool available = await speech.initialize(
      onStatus: (val) {
        if (val == 'notListening') {
          setState(() => isListening = false);
        }
      },
      onError: (val) {
        setState(() => isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الاستماع: ${val.errorMsg}')),
        );
      },
    );

    if (available) {
      setState(() => isListening = true);
      speech.listen(
        onResult: (val) {
          setState(() {
            resultText = val.recognizedWords;
          });

          if (val.finalResult) {
            speech.stop();
            comparePronunciation(correctPronunciation);
          }
        },
        localeId: 'ar-YE',
      );
    }
  }

  void comparePronunciation(String correctPronunciation) async {
    String normalizedResult = resultText.trim().toLowerCase();
    String normalizedCorrect = correctPronunciation.trim().toLowerCase();
    double similarity =
        StringSimilarity.compareTwoStrings(normalizedResult, normalizedCorrect);

    if (similarity > 0.8) {
      await speakText('أحسنت، النطق صحيح!');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('✅ النطق صحيح'),
          content: Text('أحسنت، النطق صحيح!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('حسناً'),
            ),
          ],
        ),
      );
    } else {
      await speakText('النطق غير صحيح، حاول مرة أخرى.');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('❌ النطق غير صحيح'),
          content: Text('لقد قلت: $resultText'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('حاول مرة أخرى'),
            ),
          ],
        ),
      );
    }

    setState(() {
      resultText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final letterModel = Provider.of<LetterModel1>(context);

    // الحصول على عرض وارتفاع الشاشة
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double fontSize = screenWidth * 0.2;

    return Scaffold(
      appBar: AppBar(
        title: Text('نطق الأحرف', style: TextStyle(color: Colors.orange)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.orange),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_forward, color: Colors.orange),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.1,
                    vertical: screenHeight * 0.02),
                child: Container(
                  width: screenWidth * 0.8,
                  alignment: Alignment.center,
                  child: Text(
                    letterModel.currentLetter,
                    style: TextStyle(
                      fontSize: fontSize + 60,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              ElevatedButton.icon(
                onPressed: () {
                  speakText(letterModel.currentLetter);
                },
                icon: Icon(Icons.refresh, color: Colors.yellow),
                label: Text(
                  'السماع مرة أخرى',
                  style: TextStyle(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.02,
                    horizontal: screenWidth * 0.1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.05),
              ElevatedButton(
                onPressed: () async {
                  var status = await Permission.microphone.status;
                  if (!status.isGranted) {
                    await Permission.microphone.request();
                    status = await Permission.microphone.status;
                    if (!status.isGranted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '⚠️ يتطلب التطبيق إذن الوصول إلى الميكروفون')),
                      );
                      return;
                    }
                  }
                  startListening(letterModel.currentLetterName);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic,
                        size: screenHeight * 0.07, color: Colors.blueGrey),
                    Text('تسجيل',
                        style: TextStyle(
                          fontSize: screenHeight * 0.02,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  fixedSize: Size(screenWidth * 0.25, screenHeight * 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      letterModel.nextLetter();
                    },
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back_ios, color: Colors.black),
                        Text(
                          "التالي",
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.grey[300],
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                        horizontal: screenWidth * 0.08,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      letterModel.previousLetter();
                    },
                    child: Row(
                      children: [
                        Text(
                          "السابق",
                          style: TextStyle(color: Colors.black),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.black),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.grey[300],
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                        horizontal: screenWidth * 0.08,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
