// // lib/screens/number_game_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../models/number_ar.dart';
// import 'number_pronunciation_screen.dart';

// class NumberGameScreen extends StatefulWidget {
//   @override
//   _NumberGameScreenState createState() => _NumberGameScreenState();
// }

// class _NumberGameScreenState extends State<NumberGameScreen> {
//   @override
//   Widget build(BuildContext context) {
//     final numberModel = Provider.of<NumberModelGreat>(context);
//     final levels = numberModel.levels;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('لعبة نطق الأرقام'),
//       ),
//       body: ListView.builder(
//         itemCount: levels.length,
//         itemBuilder: (context, levelIndex) {
//           final level = levels[levelIndex];
//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//                 child: Text(
//                   'المستوى ${level.levelNumber}',
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//               ),
//               GridView.builder(
//                 shrinkWrap: true,
//                 physics: NeverScrollableScrollPhysics(),
//                 padding: EdgeInsets.symmetric(horizontal: 16.0),
//                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 3,
//                   mainAxisSpacing: 10,
//                   crossAxisSpacing: 10,
//                   childAspectRatio: 1,
//                 ),
//                 itemCount: level.numbers.length,
//                 itemBuilder: (context, numberIndex) {
//                   final numberItem = level.numbers[numberIndex];
//                   return NumberCircle(
//                     numberItem: numberItem,
//                     onTap: () {
//                       if (numberItem.status == GameStatus.mastered) {
//                         return; // لا تفعل شيئاً إذا تم إتقان الرقم
//                       }
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) =>
//                               NumberPronunciationScreen(numberItem: numberItem),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// class NumberCircle extends StatelessWidget {
//   final NumberItem numberItem;
//   final VoidCallback onTap;

//   const NumberCircle({required this.numberItem, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         children: [
//           CircleAvatar(
//             radius: 30,
//             backgroundColor: Colors.blueAccent,
//             child: Text(
//               numberItem.number.toString(),
//               style: TextStyle(color: Colors.white, fontSize: 24),
//             ),
//           ),
//           SizedBox(height: 1),
//           // Stars
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: List.generate(3, (index) {
//               if (index < numberItem.stars) {
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

