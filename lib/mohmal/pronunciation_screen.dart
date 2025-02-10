// // lib/screens/pronunciation_screen.dart
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../models/level_ar.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:string_similarity/string_similarity.dart';

// class PronunciationScreen extends StatefulWidget {
//   final Letter letter;

//   PronunciationScreen({required this.letter});

//   @override
//   _PronunciationScreenState createState() => _PronunciationScreenState();
// }

// class _PronunciationScreenState extends State<PronunciationScreen> {
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

//     // تحقق من اللغات المدعومة
//     List<stt.LocaleName> locales = await speech.locales();
//     print('اللغات المدعومة:');
//     locales.forEach((locale) {
//       print('${locale.name} - ${locale.localeId}');
//     });
//   }

//   @override
//   void dispose() {
//     flutterTts.stop();
//     speech.stop(); // تأكد من أن هذا يتم فقط بعد إكمال الاستماع
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
//           print('النتيجة المسجلة: ${val.recognizedWords}'); // سجل النتيجة

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
//       print(
//           'النتيجة المسجلة فارغة!'); // إضافة هذه الرسالة للمساعدة في تحديد المشكلة
//       return; // أوقف العملية هنا إذا كانت النتيجة فارغة
//     }

//     final letterModel = Provider.of<LetterModel>(context, listen: false);

//     final similarity =
//         StringSimilarity.compareTwoStrings(normalizedResult, normalizedCorrect);
//     print('نسبة التشابه: $similarity');

//     if (similarity > 0.8) {
//       // يمكن تعديل النسبة حسب الحاجة
//       // النطق صحيح
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
//                   // توقف جميع العمليات قبل العودة
//                   speech.stop();
//                   flutterTts.stop();
//                   letterModel.updateLetterStatus(widget.letter, true);
//                   letterModel.proceedToNextLetter();
//                   Navigator.pop(context); // إغلاق الحوار
//                   Navigator.pop(context); // العودة إلى LetterGameScreen
//                 },
//                 child: Text('حسناً'),
//               ),
//             ],
//           ),
//         );
//       }
//     } else {
//       // النطق غير صحيح
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
//                   // لا نقوم بإعادة المحاولة تلقائيًا
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
//       letterModel.updateLetterStatus(widget.letter, false);

//       if (mounted) {
//         setState(() {
//           retryCount++;
//         });
//       }
//     }

//     // تأجيل إعادة تعيين resultText حتى بعد إغلاق الحوار
//     Future.delayed(Duration(milliseconds: 500), () {
//       if (mounted) {
//         setState(() {
//           resultText = '';
//         });
//       }
//     });
//   }

//   String normalizeText(String text) {
//     // إزالة الحركات (التشكيل)
//     final diacriticsRegExp = RegExp(r'[\u064B-\u0652]');
//     text = text.replaceAll(diacriticsRegExp, '');

//     // إزالة المسافات الزائدة من البداية والنهاية
//     text = text.trim();

//     return text;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final letter = widget.letter;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'نطق الحرف "${letter.character}"',
//           style: TextStyle(
//             color: Colors.orange,
//             fontSize: MediaQuery.of(context).size.width * 0.05,
//           ),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 0,
//         iconTheme: IconThemeData(color: Colors.orange),
//       ),
//       body: Center(
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Card(
//                 elevation: 2,
//                 margin: EdgeInsets.symmetric(
//                   horizontal: MediaQuery.of(context).size.width * 0.05,
//                   vertical: MediaQuery.of(context).size.height * 0.02,
//                 ),
//                 child: Container(
//                   width: MediaQuery.of(context).size.width * 0.8,
//                   height: MediaQuery.of(context).size.height * 0.3,
//                   alignment: Alignment.center,
//                   child: Text(
//                     letter.character,
//                     style: TextStyle(
//                       fontSize: MediaQuery.of(context).size.width * 0.25,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ),
//               SizedBox(height: MediaQuery.of(context).size.height * 0.03),
//               Text(
//                 'اسم الحرف: ${letter.name}',
//                 style: TextStyle(
//                   fontSize: MediaQuery.of(context).size.width * 0.06,
//                 ),
//               ),
//               SizedBox(height: MediaQuery.of(context).size.height * 0.05),
//               ElevatedButton.icon(
//                 onPressed: () {
//                   speakText(letter.character);
//                 },
//                 icon: Icon(
//                   Icons.volume_up,
//                   color: Colors.yellow,
//                   size: MediaQuery.of(context).size.width * 0.08,
//                 ),
//                 label: Text(
//                   'السماع مرة أخرى',
//                   style: TextStyle(
//                       fontSize: MediaQuery.of(context).size.width * 0.045),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue,
//                   padding: EdgeInsets.symmetric(
//                     vertical: MediaQuery.of(context).size.height * 0.02,
//                     horizontal: MediaQuery.of(context).size.width * 0.15,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//               ),
//               SizedBox(height: MediaQuery.of(context).size.height * 0.04),
//               ElevatedButton(
//                 onPressed: isListening
//                     ? null
//                     : () async {
//                         bool isConnected = await checkInternet();
//                         if (isConnected) {
//                           startListening(letter.name);
//                         } else {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                                 content: Text('⚠️ لا يوجد اتصال بالإنترنت')),
//                           );
//                         }
//                       },
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.mic,
//                       size: MediaQuery.of(context).size.width * 0.12,
//                       color: Colors.blueGrey,
//                     ),
//                     Text(
//                       'تسجيل',
//                       style: TextStyle(
//                         fontSize: MediaQuery.of(context).size.width * 0.04,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.orange,
//                   fixedSize: Size(
//                     MediaQuery.of(context).size.width * 0.25,
//                     MediaQuery.of(context).size.height * 0.15,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                 ),
//               ),
//               SizedBox(height: MediaQuery.of(context).size.height * 0.03),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   ElevatedButton.icon(
//                     onPressed: () {
//                       // استدعاء دالة الحرف التالي
//                     },
//                     icon: Icon(Icons.arrow_back),
//                     label: Text('التالي'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.grey[300],
//                       padding: EdgeInsets.symmetric(
//                         vertical: MediaQuery.of(context).size.height * 0.015,
//                         horizontal: MediaQuery.of(context).size.width * 0.1,
//                       ),
//                     ),
//                   ),
//                   ElevatedButton.icon(
//                     onPressed: () {
//                       // استدعاء دالة الحرف السابق
//                     },
//                     icon: Icon(Icons.arrow_forward),
//                     label: Text('السابق'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.grey[300],
//                       padding: EdgeInsets.symmetric(
//                         vertical: MediaQuery.of(context).size.height * 0.015,
//                         horizontal: MediaQuery.of(context).size.width * 0.1,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
