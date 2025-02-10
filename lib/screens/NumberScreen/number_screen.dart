import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teatcher_smarter/custom_widgets/custom_app_bar.dart';
import '../../models/number_model.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class NumberScreen extends StatefulWidget {
  @override
  _NumberScreenState createState() => _NumberScreenState();
}

class _NumberScreenState extends State<NumberScreen> {
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
    await flutterTts.setLanguage("ar-SA");
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

    bool available = await speech.initialize();
    if (available) {
      setState(() => isListening = true);
      speech.listen(
        onResult: (val) {
          setState(() {
            resultText = val.recognizedWords;
          });

          if (val.finalResult) {
            speech.stop();
            // يمكنك هنا إضافة منطق للتحقق من النطق
          }
        },
        localeId: 'ar-SA',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberModel = Provider.of<NumberModel>(context);

    // الحصول على عرض وارتفاع الشاشة
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'نطق الأرقام',
        onBackPressed: () => Navigator.pop(context),
        icon_theme: Colors.orange,
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
                    numberModel.currentNumber.toString(),
                    style: TextStyle(
                      fontSize: screenWidth * 0.40,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              ElevatedButton.icon(
                onPressed: () {
                  speakText(numberModel.currentNumberName);
                },
                icon: Icon(Icons.volume_up, color: Colors.white),
                label: Text(
                  'نطق الرقم',
                  style: TextStyle(
                      color: Colors.white,
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
                  startListening(numberModel.currentNumberName);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic,
                        size: screenHeight * 0.07, color: Colors.white),
                    Text('تسجيل',
                        style: TextStyle(
                          fontSize: screenHeight * 0.02,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
              Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        numberModel.nextNumber();
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Colors.grey[300],
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                          horizontal: screenWidth * 0.08,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.arrow_back_ios),
                          Text("التالي"),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        numberModel.previousNumber();
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Colors.grey[300],
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                          horizontal: screenWidth * 0.08,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("السابق"),
                          Icon(Icons.arrow_forward_ios)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
