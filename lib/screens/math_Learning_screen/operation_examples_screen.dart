import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../providers/math_provider.dart';
import '../../models_for_api/math_model_api.dart';
import '../../custom_widgets/custom_app_bar.dart';
import '../../models/math_model.dart';

class OperationExamplesScreen extends StatefulWidget {
  final int operationType;
  final String operationLabel;
  final int level;

  const OperationExamplesScreen({
    Key? key,
    required this.operationType,
    required this.operationLabel,
    required this.level,
  }) : super(key: key);

  @override
  _OperationExamplesScreenState createState() => _OperationExamplesScreenState();
}

class _OperationExamplesScreenState extends State<OperationExamplesScreen> {
  int _currentStepIndex = 0;
  late FlutterTts flutterTts;
  bool _showExample = false;
  bool _isReading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _initTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mathProvider = context.read<MathProvider>();
      switch (widget.operationType) {
        case 0:
          mathProvider.filterByOperationAndLevel(Operation.addition, widget.level);
          break;
        case 1:
          mathProvider.filterByOperationAndLevel(Operation.subtraction, widget.level);
          break;
        case 2:
          mathProvider.filterByOperationAndLevel(Operation.multiplication, widget.level);
          break;
        case 3:
          mathProvider.filterByOperationAndLevel(Operation.division, widget.level);
          break;
      }
    });
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("ar-SA");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    
    flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isReading = false;
        });
      }
    });
  }

  Future<void> _speak(String text) async {
    setState(() {
      _isReading = true;
    });
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    flutterTts.stop();
    _scrollController.dispose();
    super.dispose();
  }

  void _nextStep() {
    final currentMath = context.read<MathProvider>().currentMath;
    if (currentMath != null && _currentStepIndex < currentMath.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      _speak(currentMath.steps[_currentStepIndex]);
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
      _speak(context.read<MathProvider>().currentMath!.steps[_currentStepIndex]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'تعلم ${widget.operationLabel}',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Consumer<MathProvider>(
        builder: (context, mathProvider, child) {
          if (mathProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentMath = mathProvider.currentMath;
          if (currentMath == null) {
            return const Center(child: Text('لا توجد أمثلة متاحة'));
          }

          if (!_showExample) {
            return _buildExamplesList(mathProvider);
          }

          return _buildExampleDetails(currentMath);
        },
      ),
    );
  }

  Widget _buildExamplesList(MathProvider mathProvider) {
    return Container(
      color: Colors.grey[100],
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mathProvider.filteredItems.length,
        itemBuilder: (context, index) {
          final example = mathProvider.filteredItems[index];
          return GestureDetector(
            onTap: () {
              mathProvider.setCurrentIndex(index);
              setState(() {
                _showExample = true;
                _currentStepIndex = 0;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _speak(mathProvider.currentMath!.steps[0]);
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.chevron_right),
                    Text(
                      '${example.num1}${example.operationSymbol}${example.num2}=?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExampleDetails(MathModelApi currentMath) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _showExample = false),
              ),
              Text(
                'مثال تعليمي:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${currentMath.num1}${currentMath.operationSymbol}${currentMath.num2}=?',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'خطوات الحل:',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentMath.steps.length,
              itemBuilder: (context, index) {
                final isCurrentStep = index == _currentStepIndex;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: isCurrentStep && _isReading ? Colors.blue : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          currentMath.steps[index],
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.5,
                            color: isCurrentStep && _isReading ? Colors.blue : Colors.black,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 95,
                child: ElevatedButton(
                  onPressed: _currentStepIndex > 0 ? _previousStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    disabledBackgroundColor: Colors.grey,
                    padding: const EdgeInsets.all(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.arrow_back, size: 16),
                      SizedBox(width: 4),
                      Text('السابق', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 95,
                child: ElevatedButton(
                  onPressed: () => _speak(currentMath.steps[_currentStepIndex]),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.all(8),
                  ),
                  child: Text(
                    _isReading ? 'جاري...' : 'استماع',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              SizedBox(
                width: 95,
                child: ElevatedButton(
                  onPressed: _currentStepIndex < currentMath.steps.length - 1 ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    disabledBackgroundColor: Colors.grey,
                    padding: const EdgeInsets.all(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('التالي', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
