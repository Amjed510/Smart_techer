import 'package:flutter/material.dart';

/// ويدجت لعرض النص التعليمي وجملة المهمة
class InstructionTextWidget extends StatelessWidget {
  final String title;
  final String sentenceText;
  final Color titleColor;
  final Color sentenceColor;
  final double titleFontSize;
  final double sentenceFontSize;

  const InstructionTextWidget({
    Key? key,
    required this.title,
    required this.sentenceText,
    required this.titleColor,
    required this.sentenceColor,
    required this.titleFontSize,
    required this.sentenceFontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          if (sentenceText.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              sentenceText,
              style: TextStyle(
                fontSize: sentenceFontSize,
                fontWeight: FontWeight.bold,
                color: sentenceColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ويدجت لعرض الجملة المرتبة
class SortedSentenceWidget extends StatelessWidget {
  final List<String> selectedWords;
  final Color textColor;
  final double fontSize;
  final String placeholder;

  const SortedSentenceWidget({
    Key? key,
    required this.selectedWords,
    required this.textColor,
    required this.fontSize,
    required this.placeholder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        selectedWords.isEmpty ? placeholder : selectedWords.join(' '),
        style: TextStyle(fontSize: fontSize, color: textColor),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// ويدجت لعرض الكلمات المبعثرة
class ShuffledWordsWidget extends StatelessWidget {
  final List<String> shuffledWords;
  final List<String> selectedWords;
  final Function(String) onWordTapped;
  final Color buttonColor;
  final Color selectedButtonColor;
  final Color textColor;
  final double fontSize;

  const ShuffledWordsWidget({
    Key? key,
    required this.shuffledWords,
    required this.selectedWords,
    required this.onWordTapped,
    required this.buttonColor,
    required this.selectedButtonColor,
    required this.textColor,
    required this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: shuffledWords.map((word) {
        bool isSelected = selectedWords.contains(word);
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? selectedButtonColor : buttonColor,
          ),
          onPressed: () => onWordTapped(word),
          child: Text(
            word,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// ويدجت زر الاستماع
class ListenButtonWidget extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onPressed;
  final String buttonText;
  final IconData icon;
  final Color iconColor;
  final Color textColor;
  final Color buttonColor;
  final EdgeInsets padding;

  const ListenButtonWidget({
    Key? key,
    required this.isProcessing,
    required this.onPressed,
    required this.buttonText,
    required this.icon,
    required this.iconColor,
    required this.textColor,
    required this.buttonColor,
    required this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isProcessing ? null : onPressed,
      icon: Icon(icon, color: iconColor, size: 30),
      label: Text(buttonText, style: TextStyle(color: textColor, fontSize: 20)),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        padding: padding,
      ),
    );
  }
}

/// ويدجت زر التحقق
class CheckButtonWidget extends StatelessWidget {
  final bool isProcessing;
  final bool isButtonEnabled;
  final VoidCallback onPressed;
  final String buttonText;
  final IconData icon;
  final Color buttonColor;
  final Color textColor;
  final EdgeInsets padding;

  const CheckButtonWidget({
    Key? key,
    required this.isProcessing,
    required this.isButtonEnabled,
    required this.onPressed,
    required this.buttonText,
    required this.icon,
    required this.buttonColor,
    required this.textColor,
    required this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 50),
      child: ElevatedButton(
        onPressed: !isProcessing && isButtonEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          padding: padding,
          backgroundColor: buttonColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              buttonText,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(width: 10),
            Icon(icon, color: textColor),
          ],
        ),
      ),
    );
  }
}

/// ويدجت أزرار التنقل (السابق والتالي)
class NavigationButtonsWidget extends StatelessWidget {
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPreviousPressed;
  final VoidCallback onNextPressed;
  final String previousButtonText;
  final String nextButtonText;
  final IconData previousIcon;
  final IconData nextIcon;
  final Color activeColor;
  final Color inactiveColor;
  final EdgeInsets padding;

  const NavigationButtonsWidget({
    Key? key,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPreviousPressed,
    required this.onNextPressed,
    required this.previousButtonText,
    required this.nextButtonText,
    required this.previousIcon,
    required this.nextIcon,
    required this.activeColor,
    required this.inactiveColor,
    required this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 1,
            child: ElevatedButton(
              onPressed: hasPrevious ? onPreviousPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasPrevious ? activeColor : inactiveColor,
                padding: padding,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(previousIcon, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    previousButtonText,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 40),
          Flexible(
            flex: 1,
            child: ElevatedButton(
              onPressed: hasNext ? onNextPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasNext ? activeColor : inactiveColor,
                padding: padding,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    nextButtonText,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(nextIcon, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ويدجت لعرض الكلمة المجمعة
class AssembledWordWidget extends StatelessWidget {
  final String assembledWord;
  final Color textColor;
  final double fontSize;
  final String placeholder;

  const AssembledWordWidget({
    Key? key,
    required this.assembledWord,
    required this.textColor,
    required this.fontSize,
    required this.placeholder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        assembledWord.isEmpty ? placeholder : assembledWord,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

/// ويدجت لعرض الحرف
class LetterWidget extends StatelessWidget {
  final String letter;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color defaultColor;
  final double fontSize;

  const LetterWidget({
    Key? key,
    required this.letter,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
    required this.defaultColor,
    required this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : defaultColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}