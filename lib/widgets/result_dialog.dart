import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ResultDialog extends StatelessWidget {
  final bool isCorrect;
  final VoidCallback onClose;
  final String message;

  const ResultDialog({
    Key? key,
    required this.isCorrect,
    required this.onClose,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // صورة متحركة للصواب أو الخطأ
            Lottie.asset(
              isCorrect
                  ? 'assets/correct_animation.json'
                  : 'assets/incorrect_animation.json',
              width: 150,
              height: 150,
              repeat: false,
            ),
            SizedBox(height: 20),
            // رسالة النتيجة
            Text(
              message,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isCorrect ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            // زر الإغلاق
            ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCorrect ? Colors.green : Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                'حسناً',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}