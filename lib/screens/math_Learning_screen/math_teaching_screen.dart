import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../providers/math_provider.dart';
import '../../models_for_api/math_model_api.dart';
import '../../custom_widgets/custom_app_bar.dart';
import 'operation_examples_screen.dart';

class MathTeachingScreen extends StatefulWidget {
  final int level;
  const MathTeachingScreen({Key? key, required this.level}) : super(key: key);

  @override
  _MathTeachingScreenState createState() => _MathTeachingScreenState();
}

class _MathTeachingScreenState extends State<MathTeachingScreen> {
  late FlutterTts flutterTts;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("ar-SA");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'الحساب',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildOperationButton(
                context: context,
                label: 'الجمع',
                symbol: '+',
                operationType: 0,
              ),
              const SizedBox(height: 16),
              _buildOperationButton(
                context: context,
                label: 'الطرح',
                symbol: '-',
                operationType: 1,
              ),
              const SizedBox(height: 16),
              _buildOperationButton(
                context: context,
                label: 'الضرب',
                symbol: '×',
                operationType: 2,
              ),
              const SizedBox(height: 16),
              _buildOperationButton(
                context: context,
                label: 'القسمة',
                symbol: '÷',
                operationType: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOperationButton({
    required BuildContext context,
    required String label,
    required String symbol,
    required int operationType,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OperationExamplesScreen(
              operationType: operationType,
              operationLabel: label,
              level: widget.level,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    symbol,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
