// // lib/screens/number_pronunciation_screen.dart
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../models/number_ar.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:string_similarity/string_similarity.dart';

// class NumberPronunciationScreen extends StatefulWidget {
//   final NumberItem numberItem;

//   NumberPronunciationScreen({required this.numberItem});

//   @override
//   _NumberPronunciationScreenState createState() =>
//       _NumberPronunciationScreenState();
// }

// class _NumberPronunciationScreenState extends State<NumberPronunciationScreen> {
//   late FlutterTts flutterTts;
//   late stt.SpeechToText speech;
//   bool isListening = false;
//   String resultText = '';
//   final int maxRetries = 5;
//   int retryCount = 0;

//   Timer? _listenTimer;

//   @override
//   void initState() {
//     super.initState();
//     flutterTts = FlutterTts();
//     speech = stt.SpeechToText();
//     initSpeech();
//   }

//   void initSpeech() async {
//     bool available = await speech.initialize(
//       onStatus: (val) {
//         print('الحالة: $val');
//         if (mounted) {
//           if (val == 'done' || val == 'notListening') {
//             setState(() => isListening = false);
//             _listenTimer?.cancel();
//           }
//         }
//       },
//       onError: (val) {
//         print('خطأ: ${val.errorMsg}');
//         if (mounted) {
//           setState(() => isListening = false);
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('حدث خطأ أثناء الاستماع: ${val.errorMsg}')),
//           );
//         }
//         _listenTimer?.cancel();
//       },
//     );

//     if (available) {
//       print('تم تهيئة speech_to_text بنجاح');
//     } else {
//       print('فشل في تهيئة speech_to_text');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('⚠️ فشل في تهيئة الاستماع الصوتي')),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     flutterTts.stop();
//     speech.stop();
//     _listenTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> speakText(String text) async {
//     await flutterTts.setLanguage("ar-SA");
//     await flutterTts.setSpeechRate(0.5);
//     await flutterTts.setPitch(1.0);

//     var result = await flutterTts.speak(text);
//     if (result == 1) {
//       print("تم النطق بنجاح");
//     } else {
//       print("فشل في النطق");
//     }
//   }

//   Future<bool> checkInternet() async {
//     try {
//       final result = await http
//           .get(Uri.parse('http://www.google.com'))
//           .timeout(Duration(seconds: 5));
//       return result.statusCode == 200;
//     } catch (_) {
//       return false;
//     }
//   }

//   Future<void> requestMicrophonePermission() async {
//     var status = await Permission.microphone.status;
//     if (!status.isGranted) {
//       status = await Permission.microphone.request();
//       if (!status.isGranted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('⚠️ يتطلب التطبيق إذن الوصول إلى الميكروفون')),
//         );
//       }
//     }
//   }

//   void startListening(String correctPronunciation) async {
//     await requestMicrophonePermission();

//     if (isListening) {
//       await speech.stop();
//       _listenTimer?.cancel();
//       if (mounted) {
//         setState(() => isListening = false);
//       }
//     }

//     if (speech.isAvailable) {
//       if (mounted) {
//         setState(() => isListening = true);
//       }
//       speech.listen(
//         onResult: (val) {
//           if (mounted) {
//             setState(() {
//               resultText = val.recognizedWords;
//             });
//           }
//           print('النتيجة المسجلة: ${val.recognizedWords}');

//           if (val.finalResult) {
//             speech.stop();
//             _listenTimer?.cancel();
//             if (mounted) {
//               setState(() => isListening = false);
//             }
//             comparePronunciation(correctPronunciation);
//           }
//         },
//         localeId: 'ar-SA',
//         listenFor: Duration(seconds: 5),
//         pauseFor: Duration(seconds: 3),
//         partialResults: false,
//         listenMode: stt.ListenMode.confirmation,
//       );

//       _listenTimer = Timer(Duration(seconds: 5), () async {
//         if (isListening) {
//           await speech.stop();
//           if (mounted) {
//             setState(() => isListening = false);
//           }
//           if (resultText.isEmpty) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('لم يتم التعرف على النطق.')),
//             );
//           }
//         }
//       });
//     } else {
//       if (mounted) {
//         setState(() => isListening = false);
//       }
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('⚠️ لا يمكن البدء في الاستماع')),
//       );
//     }
//   }

//   void comparePronunciation(String correctPronunciation) async {
//     String normalizedResult = normalizeText(resultText);
//     String normalizedCorrect = normalizeText(correctPronunciation);

//     print('النطق المسجل بعد التطبيع: $normalizedResult');
//     print('النطق الصحيح بعد التطبيع: $normalizedCorrect');

//     if (normalizedResult.isEmpty) {
//       print('النتيجة المسجلة فارغة!');
//       return;
//     }

//     final numberModel = Provider.of<NumberModelGreat>(context, listen: false);
//     final similarity =
//         StringSimilarity.compareTwoStrings(normalizedResult, normalizedCorrect);
//     print('نسبة التشابه: $similarity');

//     if (similarity > 0.8) {
//       await speakText('أحسنت، النطق صحيح!');
//       if (mounted) {
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text('✅ النطق صحيح'),
//             content: Text('أحسنت، النطق صحيح!'),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   speech.stop();
//                   flutterTts.stop();
//                   numberModel.updateNumberStatus(widget.numberItem, true);
//                   numberModel.proceedToNextNumber();
//                   Navigator.pop(context);
//                   Navigator.pop(context);
//                 },
//                 child: Text('حسناً'),
//               ),
//             ],
//           ),
//         );
//       }
//     } else {
//       await speakText('النطق غير صحيح، حاول مرة أخرى.');
//       if (mounted) {
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text('❌ النطق غير صحيح'),
//             content: Text('لقد قلت: $resultText'),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//                 child: Text('حاول مرة أخرى'),
//               ),
//               if (retryCount < maxRetries)
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   child: Text('إلغاء'),
//                 ),
//             ],
//           ),
//         );
//       }
//       numberModel.updateNumberStatus(widget.numberItem, false);
//       if (mounted) {
//         setState(() {
//           retryCount++;
//         });
//       }
//     }

//     Future.delayed(Duration(milliseconds: 500), () {
//       if (mounted) {
//         setState(() {
//           resultText = '';
//         });
//       }
//     });
//   }

//   String normalizeText(String text) {
//     final diacriticsRegExp = RegExp(r'[\u064B-\u0652]');
//     text = text.replaceAll(diacriticsRegExp, '');
//     return text.trim();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final numberItem = widget.numberItem;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('نطق الرقم "${numberItem.number}"'),
//       ),
//       body: Center(
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 numberItem.number.toString(),
//                 style: TextStyle(fontSize: 150, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 20),
//               Text(
//                 'اسم الرقم: ${numberItem.name}',
//                 style: TextStyle(fontSize: 24),
//               ),
//               SizedBox(height: 40),
//               ElevatedButton.icon(
//                 onPressed: () {
//                   speakText(numberItem.name);
//                 },
//                 icon: Icon(Icons.volume_up),
//                 label: Text('نطق الرقم'),
//                 style: ElevatedButton.styleFrom(
//                   minimumSize: Size(200, 50),
//                 ),
//               ),
//               SizedBox(height: 20),
//               ElevatedButton.icon(
//                 onPressed: isListening
//                     ? null
//                     : () async {
//                         bool isConnected = await checkInternet();
//                         if (isConnected) {
//                           startListening(numberItem.name);
//                         } else {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                                 content: Text('⚠️ لا يوجد اتصال بالإنترنت')),
//                           );
//                         }
//                       },
//                 icon: Icon(Icons.mic),
//                 label: Text(isListening ? 'جاري الاستماع...' : 'تحقق من النطق'),
//                 style: ElevatedButton.styleFrom(
//                   minimumSize: Size(200, 50),
//                 ),
//               ),
//               SizedBox(height: 20),
//               if (retryCount > 0 && retryCount < maxRetries)
//                 Text(
//                   'عدد المحاولات: $retryCount/$maxRetries',
//                   style: TextStyle(fontSize: 16, color: Colors.grey),
//                 ),
//               if (retryCount >= maxRetries)
//                 Text(
//                   '⚠️ لقد وصلت إلى الحد الأقصى من المحاولات.',
//                   style: TextStyle(fontSize: 16, color: Colors.red),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
