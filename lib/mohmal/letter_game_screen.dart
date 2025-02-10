// // lib/screens/letter_game_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../models/level_ar.dart';
// import 'pronunciation_screen.dart';
// import 'package:flutter_tts/flutter_tts.dart';

// class LetterGameScreen extends StatefulWidget {
//   @override
//   _LetterGameScreenState createState() => _LetterGameScreenState();
// }

// class _LetterGameScreenState extends State<LetterGameScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;
//   late ScrollController _scrollController;
//   late FlutterTts flutterTts;

//   @override
//   void initState() {
//     super.initState();
//     flutterTts = FlutterTts();

//     _controller = AnimationController(
//       duration: const Duration(seconds: 1),
//       vsync: this,
//     )..repeat(reverse: true);

//     _animation = Tween<double>(begin: 0.9, end: 1.0).animate(_controller);
//     _scrollController = ScrollController();

//     // Scroll to the top to start at level 1
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _scrollController.jumpTo(0); // Jump to the top
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _scrollController.dispose(); // Dispose the scroll controller
//     flutterTts.stop();
//     super.dispose();
//   }

//   Future<void> speakText(String text) async {
//     await flutterTts.setLanguage("ar-SA");
//     await flutterTts.setSpeechRate(0.5);
//     await flutterTts.setPitch(1.0);
//       await flutterTts.setVolume(1.0);

//     var result = await flutterTts.speak(text);
//     if (result == 1) {
//       print("تم النطق بنجاح");
//     } else {
//       print("فشل في النطق");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final letterModel = Provider.of<LetterModel>(context);
//     final levels = letterModel.levels;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(' نطق الحروف العربية'),
//       ),
//       body: SingleChildScrollView(
//         controller: _scrollController, // Attach the scroll controller
//         child: Row(
//           children: [
//             // Left image with animation
//             Expanded(
//               flex: 1,
//               child: ScaleTransition(
//                 scale: _animation,
//                 child: Image.asset('assets/images/ي.png', fit: BoxFit.cover),
//               ),
//             ),
//             // Center column with levels
//             Expanded(
//               flex: 2,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min, // Avoid using expanded height
//                 children: [
//                   // Header
//                   Container(
//                     height: 60,
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [Colors.blueAccent, Colors.green],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                       borderRadius:
//                           BorderRadius.vertical(bottom: Radius.circular(20)),
//                     ),
//                     child: Center(
//                         child: Text("الحروف العربية",
//                             style:
//                                 TextStyle(fontSize: 24, color: Colors.white))),
//                   ),
//                   // Levels
//                   Container(
//                     height: MediaQuery.of(context).size.height - 100,
//                     child: ListView.builder(
//                       itemCount: levels.length,
//                       itemBuilder: (context, levelIndex) {
//                         final level = levels[levelIndex];
//                         return Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Padding(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 16.0, vertical: 8.0),
//                               child: Text(
//                                 'المستوى ${level.levelNumber}',
//                                 style: TextStyle(
//                                     fontSize: 20, fontWeight: FontWeight.bold),
//                               ),
//                             ),
//                             GridView.builder(
//                               shrinkWrap: true,
//                               physics: NeverScrollableScrollPhysics(),
//                               padding: EdgeInsets.symmetric(horizontal: 16.0),
//                               gridDelegate:
//                                   SliverGridDelegateWithFixedCrossAxisCount(
//                                 crossAxisCount: 1,
//                                 mainAxisSpacing: 10,
//                                 crossAxisSpacing: 10,
//                                 childAspectRatio: 1,
//                               ),
//                               itemCount: level.letters.length,
//                               itemBuilder: (context, letterIndex) {
//                                 final letter = level.letters[letterIndex];
//                                 return LevelCircle(
//                                   letter: letter,
//                                   onTap: () {
//                                     if (letter.status == GameStatus.mastered) {
//                                       return; // لا تفعل شيئاً إذا تم إتقان الحرف
//                                     }

//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) =>
//                                             PronunciationScreen(letter: letter),
//                                       ),
//                                     );
//                                   },
//                                 );
//                               },
//                             ),
//                           ],
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             // Right image with animation
//             Expanded(
//               flex: 1,
//               child: ScaleTransition(
//                 scale: _animation,
//                 child: Image.asset('assets/images/أ.png', fit: BoxFit.cover),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class LevelCircle extends StatelessWidget {
//   final Letter letter;
//   final VoidCallback onTap;

//   const LevelCircle({required this.letter, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: LinearGradient(
//                 colors: [Colors.purple, Colors.pink],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black26,
//                   blurRadius: 8.0,
//                   offset: Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: CircleAvatar(
//               radius: 30,
//               backgroundColor: Colors.transparent,
//               child: Text(
//                 letter.character,
//                 style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 24),
//               ),
//             ),
//           ),
//           SizedBox(height: 5),
//           // Stars
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: List.generate(3, (index) {
//               if (index < letter.stars) {
//                 return Icon(Icons.star, color: Colors.orange, size: 16);
//               } else {
//                 return Icon(Icons.star_border, color: Colors.orange, size: 16);
//               }
//             }),
//           ),
//         ],
//       ),
//     );
//   }
// }
