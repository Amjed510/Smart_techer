// // lib/models/number_ar.dart
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:test_ai_12/models/database_helper_number.dart';

// enum GameStatus { notStarted, inProgress, mastered }

// class NumberItem {
//   final int number;
//   final String name;
//   int stars;
//   int attempts;
//   GameStatus status;

//   NumberItem({
//     required this.number,
//     required this.name,
//     this.stars = 0,
//     this.attempts = 0,
//     this.status = GameStatus.notStarted,
//   });

//   // تحويل الكائن إلى خريطة لتخزينه في قاعدة البيانات
//   Map<String, dynamic> toMap() {
//     return {
//       'number': number,
//       'name': name,
//       'stars': stars,
//       'attempts': attempts,
//       'status': status.index,
//     };
//   }

//   // إنشاء كائن `NumberItem` من خريطة مسترجعة من قاعدة البيانات
//   factory NumberItem.fromMap(Map<String, dynamic> map) {
//     return NumberItem(
//       number: map['number'],
//       name: map['name'],
//       stars: map['stars'],
//       attempts: map['attempts'],
//       status: GameStatus.values[map['status']],
//     );
//   }
// }

// class NumberLevel {
//   final int levelNumber;
//   final List<NumberItem> numbers;

//   NumberLevel({
//     required this.levelNumber,
//     required this.numbers,
//   });
// }

// class NumberModelGreat with ChangeNotifier {
//   List<NumberLevel> _levels = [];
//   int _currentLevel = 0;
//   int _currentNumberIndex = 0;

//   bool _isCompleted = false;
//   bool get isCompleted => _isCompleted;

//   DatabaseHelpernum _dbHelper =
//       DatabaseHelpernum(); // تأكد من تعديل DatabaseHelper للتعامل مع الأرقام

//   NumberModelGreat() {
//     _initializeLevels();
//     loadData();
//   }

//   List<NumberLevel> get levels => _levels;
//   int get currentLevel => _currentLevel;
//   int get currentNumberIndex => _currentNumberIndex;
//   NumberItem get currentNumber =>
//       _levels[_currentLevel].numbers[_currentNumberIndex];

//   void _initializeLevels() {
//     _levels = [];
//     int levelCount = 1;
//     for (int i = 1; i <= 100; i += 10) {
//       List<NumberItem> numbers = [];
//       for (int j = i; j < i + 10; j++) {
//         numbers.add(NumberItem(number: j, name: _numberToArabic(j)));
//       }
//       _levels.add(NumberLevel(levelNumber: levelCount, numbers: numbers));
//       levelCount++;
//     }
//   }

//   String _numberToArabic(int number) {
//     // دالة لتحويل الرقم إلى نص عربي
//     // يمكنك استخدام حزمة أو كتابة دالة تحويل خاصة
//     // هنا سنستخدم قائمة بسيطة للأرقام من 1 إلى 100
//     List<String> numbersInArabic = [
//       '',
//       'واحد',
//       'اثنان',
//       'ثلاثة',
//       'أربعة',
//       'خمسة',
//       'ستة',
//       'سبعة',
//       'ثمانية',
//       'تسعة',
//       'عشرة',
//       'أحد عشر',
//       'اثنا عشر',
//       'ثلاثة عشر',
//       'أربعة عشر',
//       'خمسة عشر',
//       'ستة عشر',
//       'سبعة عشر',
//       'ثمانية عشر',
//       'تسعة عشر',
//       'عشرون',
//       'واحد وعشرون',
//       // أكمل حتى 100...
//     ];

//     if (number <= 21) {
//       return numbersInArabic[number];
//     } else {
//       return number.toString();
//     }
//   }

//   Future<void> saveProgress() async {
//     for (var level in _levels) {
//       for (var numberItem in level.numbers) {
//         await _dbHelper.insertNumber(numberItem);
//       }
//     }
//   }

//   Future<void> loadData() async {
//     List<NumberItem> numbersFromDB = await _dbHelper.getNumbers();

//     // تحديث الأرقام في المستويات بناءً على البيانات المسترجعة
//     for (var numberItem in numbersFromDB) {
//       for (var level in _levels) {
//         for (var i = 0; i < level.numbers.length; i++) {
//           if (level.numbers[i].number == numberItem.number) {
//             level.numbers[i] = numberItem;
//           }
//         }
//       }
//     }

//     // استرجاع المستوى الحالي ومؤشر الرقم الحالي من SharedPreferences
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     _currentLevel = prefs.getInt('currentNumberLevel') ?? 0;
//     _currentNumberIndex = prefs.getInt('currentNumberIndex') ?? 0;

//     notifyListeners();
//   }

//   void updateNumberStatus(NumberItem numberItem, bool isCorrect) {
//     if (isCorrect) {
//       numberItem.attempts++;
//       if (numberItem.attempts <= 2) {
//         numberItem.stars = 3;
//       } else if (numberItem.attempts == 3) {
//         numberItem.stars = 2;
//       } else if (numberItem.attempts >= 4) {
//         numberItem.stars = 1;
//       }
//       numberItem.status = GameStatus.mastered;
//     } else {
//       numberItem.attempts++;
//       if (numberItem.attempts >= 5) {
//         numberItem.stars = 1;
//         numberItem.status = GameStatus.mastered;
//       }
//     }

//     _dbHelper.updateNumber(numberItem);
//     saveProgress();
//     notifyListeners();
//   }

//   bool canProceed() {
//     return currentNumber.status == GameStatus.mastered;
//   }

//   void proceedToNextNumber() {
//     if (canProceed()) {
//       if (_currentNumberIndex < _levels[_currentLevel].numbers.length - 1) {
//         _currentNumberIndex++;
//       } else {
//         if (_currentLevel < _levels.length - 1) {
//           _currentLevel++;
//           _currentNumberIndex = 0;
//         } else {
//           // تم إتمام جميع المستويات
//           _isCompleted = true;
//         }
//       }

//       saveProgress();
//       notifyListeners();
//     }
//   }
// }
