import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teatcher_smarter/custom_widgets/CustomPositionedElements.dart';
import 'package:teatcher_smarter/screens/NumberScreen/NumberDrawingScreen.dart';
import 'package:teatcher_smarter/screens/NumberScreen/number_screen.dart';
import '../../custom_widgets/custom_app_bar.dart';
import '../../custom_widgets/menu_item_widget.dart';

class NumbersLearningScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'تعلم الأرقام',
        onBackPressed: () => Navigator.pop(context),
        icon_theme: Colors.orange,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MenuItemWidget(
                      iconPath: 'assets/icons/number_icon/pron_number.svg',
                      title: 'نطق الأرقام',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => NumberScreen()));
                      },
                    ),
                    SizedBox(height: 20),
                    MenuItemWidget(
                      iconPath: 'assets/icons/number_icon/draw_number.svg',
                      title: 'رسم الأرقام',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => NumberDrawingScreen()));
                      },
                    ),
                    SizedBox(height: 20),
                    MenuItemWidget(
                      iconPath: 'assets/icons/testing.png',
                      title: 'اختبار',
                      onTap: () {
                        print('تم النقر على اختبار');
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
