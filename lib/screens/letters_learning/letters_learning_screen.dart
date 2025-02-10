// lib/screens/letters_learning_screen.dart
import 'package:flutter/material.dart';
import 'package:teatcher_smarter/custom_widgets/CustomPositionedElements.dart';
import 'package:teatcher_smarter/screens/letters_learning/drawing_screen.dart';
import 'package:teatcher_smarter/screens/letters_learning/drawing_test_screen.dart';

import '../../custom_widgets/custom_app_bar.dart';
import '../../custom_widgets/menu_item_widget.dart';
import 'letter_pronunciation_screen.dart';


class LettersLearningScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'تعلم الأحرف',
        onBackPressed: () => Navigator.pop(context),
        icon_theme: Colors.orange,
      ),
      body: Stack(
        children: [
          // الأيقونات الجانبية العائمة

          // المحتوى الرئيسي
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MenuItemWidget(
                      iconPath: 'assets/icons/pronounce.png',
                      title: 'نطق الأحرف',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    Letterpronunciationscreen()));
                      },
                    ),
                    SizedBox(height: 20),
                    MenuItemWidget(
                      iconPath: 'assets/icons/draw.png',
                      title: 'رسم الأحرف',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DrawingScreen()));
                      },
                    ),
                    SizedBox(height: 20),
                    MenuItemWidget(
                      iconPath: 'assets/icons/testing.png',
                      title: 'اختبار',
                      onTap: () {
                       Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DrawingTestScreen()));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          CustomPositionedElements.starIconTopRight(),
          CustomPositionedElements.taaIconTopRight(),
          CustomPositionedElements.khaIconRightMiddle(),
          CustomPositionedElements.haaIconBottomRight(),
          CustomPositionedElements.fourIconTopLeft(),
          CustomPositionedElements.dashIconTopLeft(),
          CustomPositionedElements.seenIconMiddleLeft(),
          CustomPositionedElements.noonIconBottomLeft(),
          CustomPositionedElements.starIconBottomLeft(),
        ],
      ),
    );
  }
}
