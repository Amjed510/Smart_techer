// // lib/screens/main_menu.dart
// import 'package:flutter/material.dart';
// import 'package:test_ai_12/screens/geometry_teaching_screen.dart';
// import 'package:test_ai_12/screens/home_game.dart';
// import 'package:test_ai_12/screens/home_screen.dart';
// import 'package:test_ai_12/screens/letter_game_screen.dart';
// import 'package:test_ai_12/screens/math_screen.dart';
// import 'package:test_ai_12/screens/math_teaching_screen.dart';
// import 'package:test_ai_12/screens/number_game_screen.dart';
// import 'package:test_ai_12/screens/number_screen.dart';
// import 'package:test_ai_12/screens/sentence_screen.dart';

// class MainMenu extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     // قائمة الأيقونات والصفحات المرتبطة بها
//     final List<MenuItem> menuItems = [
//       MenuItem(
//         title: 'نطق الحروف',
//         icon: Icons.record_voice_over,
//         destination: HomeScreen(),
//       ),
//       MenuItem(
//         title: 'تركيب الكلمات',
//         icon: Icons.spellcheck,
//         destination: HomeGame(),
//       ),
//       MenuItem(
//         title: 'تركيب الجمل',
//         icon: Icons.text_fields,
//         destination: SentenceScreen(),
//       ),
//        MenuItem(
//         title: 'نطق الأرقام',
//         icon: Icons.looks_one,
//         destination: NumberScreen(), // إضافة هذا السطر
//       ),
//        MenuItem(
//         title: 'تعليم العمليات الحسابية',
//         icon: Icons.school,
//         destination: MathTeachingScreen(), // إضافة MathTeachingScreen
//       ),
//       MenuItem(
//         title: 'العمليات الحسابية',
//         icon: Icons.calculate,
//         destination: MathScreen(), // إضافة هذا السطر
//       ),
//       MenuItem(
//         title: 'نـطق الحرووف',
//         icon: Icons.text_fields,
//         destination: LetterGameScreen(),
//       ),
//       MenuItem(
//         title: 'صفحة مستقبلية 4',
//         icon: Icons.star_border,
//         destination: NumberGameScreen(),
//       ),
//       MenuItem(
//         title: 'صفحة مستقبلية 5',
//         icon: Icons.star_border,
//         destination: GeometryTeachingScreen(),
//       ),
//     ];

//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text('الواجهة الرئيسية'),
//         ),
//         body: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: GridView.builder(
//             itemCount: menuItems.length,
//             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2, // عدد الأعمدة في الشبكة
//               childAspectRatio: 1, // نسبة العرض إلى الارتفاع
//               crossAxisSpacing: 10, // المسافة الأفقية بين العناصر
//               mainAxisSpacing: 10, // المسافة الرأسية بين العناصر
//             ),
//             itemBuilder: (context, index) {
//               final item = menuItems[index];
//               return GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => item.destination),
//                   );
//                 },
//                 child: Card(
//                   elevation: 4,
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(item.icon, size: 50),
//                       SizedBox(height: 10),
//                       Text(
//                         item.title,
//                         style: TextStyle(fontSize: 18),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }

// class MenuItem {
//   final String title;
//   final IconData icon;
//   final Widget destination;

//   MenuItem({
//     required this.title,
//     required this.icon,
//     required this.destination,
//   });
// }

// class PlaceholderScreen extends StatelessWidget {
//   final String title;

//   PlaceholderScreen({required this.title});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('$title'),
//       ),
//       body: Center(
//         child: Text(
//           'هذه الصفحة مخصصة لإضافة محتوى مستقبلي.',
//           style: TextStyle(fontSize: 24),
//           textAlign: TextAlign.center,
//         ),
//       ),
//     );
//   }
// }
