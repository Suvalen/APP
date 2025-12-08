import 'package:flutter/material.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _ageController = TextEditingController();
  int _currentPage = 0;

  // Store user answers
  String? _whoAsking;
  String? _age;
  String? _gender;
  List<String> _conditions = [];

  final List<QuestionData> _questions = [
    QuestionData(
      question: 'Who are you asking for?',
      type: QuestionType.multipleChoice,
      options: ['Myself', 'Somebody else', 'Prefer not to say'],
    ),
    QuestionData(
      question: 'How old are you?',
      type: QuestionType.textInput,
      placeholder: 'Type your age...',
    ),
    QuestionData(
      question: 'What is your Gender',
      type: QuestionType.multipleChoice,
      options: ['Male', 'Female', 'Prefer not to say'],
    ),
    QuestionData(
      question: 'Select pre-existing conditions',
      type: QuestionType.multiSelect,
      options: [
        'Hypertension',
        'Diabetes',
        'Heart Diseases',
        'Stroke History',
        'Asthma',
        'Hyperlipidemia (High cholesterol)',
        'Allergies',
      ],
    ),
  ];

  void _handleAnswer(String answer) {
    setState(() {
      if (_currentPage == 0) {
        _whoAsking = answer;
      } else if (_currentPage == 2) {
        _gender = answer;
      }
    });

    // Move to next question or finish
    if (_currentPage < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // All questions answered, navigate to main app
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _handleTextSubmit() {
    if (_ageController.text.isNotEmpty) {
      setState(() {
        _age = _ageController.text;
      });
      _handleAnswer(_ageController.text);
    }
  }

  void _toggleCondition(String condition) {
    setState(() {
      if (_conditions.contains(condition)) {
        _conditions.remove(condition);
      } else {
        _conditions.add(condition);
      }
    });
  }

  void _handleMultiSelectContinue() {
    // Move to next question or finish
    if (_currentPage < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // All questions answered, navigate to main app
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                         MediaQuery.of(context).padding.top -
                         MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Header Image
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.28,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/FullLogo_Transparent.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Quick personal questions before you start',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF616161),
                        fontSize: 18,
                        fontFamily: 'Urbanist',
                        fontWeight: FontWeight.w400,
                        height: 1.60,
                        letterSpacing: 0.20,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Page Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _questions.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF155DFC)
                              : const Color(0xFFD9D9D9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Questions
                  SizedBox(
                    height: 460,
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        return _buildQuestionPage(_questions[index]);
                      },
                    ),
                  ),

                  const Spacer(),

                  // Bottom Text
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Text(
                      'Start chatting with Medi-Bot now.\nYou can ask me anything.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF616161),
                        fontSize: 18,
                        fontFamily: 'Urbanist',
                        fontWeight: FontWeight.w400,
                        height: 1.60,
                        letterSpacing: 0.20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionPage(QuestionData question) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        children: [
          // Question Label
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE8E8E8),
                  Color(0xFFD9D9D9),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              question.question,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF616161),
                fontSize: 15,
                fontFamily: 'Urbanist',
                fontWeight: FontWeight.w600,
                height: 1.60,
                letterSpacing: 0.18,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Question Content (Multiple Choice, Text Input, or Multi-Select)
          question.type == QuestionType.textInput
              ? _buildTextInputQuestion(question)
              : question.type == QuestionType.multiSelect
                  ? _buildMultiSelectQuestion(question)
                  : _buildMultipleChoiceQuestion(question),
        ],
      ),
    );
  }

  Widget _buildMultipleChoiceQuestion(QuestionData question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: const Color(0xFF171717),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Colors.white.withOpacity(0.23),
          ),
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          question.options?.length ?? 0,
          (index) => Padding(
            padding: EdgeInsets.only(
              bottom: index < (question.options?.length ?? 0) - 1 ? 22 : 0,
            ),
            child: _buildOptionButton(question.options![index]),
          ),
        ),
      ),
    );
  }

  Widget _buildTextInputQuestion(QuestionData question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: const Color(0xFF171717),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Colors.white.withOpacity(0.23),
          ),
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: ShapeDecoration(
          color: const Color(0xE52F2F2F),
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: 1,
              color: Color(0xFF7F7F7F),
            ),
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: question.placeholder ?? 'Type here...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF8E8E8E),
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _handleTextSubmit(),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _handleTextSubmit,
              child: Container(
                width: 42,
                height: 46,
                decoration: ShapeDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E6FFF),
                      Color(0xFF155DFC),
                    ],
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadows: [
                    BoxShadow(
                      color: const Color(0xFF155DFC).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectQuestion(QuestionData question) {
    return Column(
      children: [
        // Scrollable options container
        Container(
          width: double.infinity,
          height: 320,
          padding: const EdgeInsets.all(20),
          decoration: ShapeDecoration(
            color: const Color(0xFF171717),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                color: Colors.white.withOpacity(0.23),
              ),
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                question.options?.length ?? 0,
                (index) => Padding(
                  padding: EdgeInsets.only(
                    bottom: index < (question.options?.length ?? 0) - 1 ? 22 : 0,
                  ),
                  child: _buildMultiSelectOption(question.options![index]),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Continue button
        GestureDetector(
          onTap: _handleMultiSelectContinue,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: ShapeDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E6FFF),
                  Color(0xFF155DFC),
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shadows: [
                BoxShadow(
                  color: const Color(0xFF155DFC).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _conditions.isEmpty ? 'Skip' : 'Continue (${_conditions.length} selected)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Urbanist',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiSelectOption(String option) {
    final isSelected = _conditions.contains(option);

    return GestureDetector(
      onTap: () => _toggleCondition(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: ShapeDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E6FFF),
                    Color(0xFF155DFC),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3A3A3A),
                    Color(0xFF2E2E2E),
                  ],
                ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadows: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF155DFC).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Urbanist',
                  fontWeight: FontWeight.w700,
                  height: 1.60,
                  letterSpacing: 0.20,
                ),
              ),
            ),
            AnimatedScale(
              scale: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String option) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTapDown: (_) {
              // Trigger scale down animation
              setState(() {});
            },
            onTapUp: (_) {
              _handleAnswer(option);
            },
            onTapCancel: () {
              setState(() {});
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: ShapeDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3A3A3A),
                    Color(0xFF2E2E2E),
                  ],
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                shadows: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                option,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Urbanist',
                  fontWeight: FontWeight.w700,
                  height: 1.60,
                  letterSpacing: 0.20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum QuestionType {
  multipleChoice,
  textInput,
  multiSelect,
}

class QuestionData {
  final String question;
  final QuestionType type;
  final List<String>? options;
  final String? placeholder;

  QuestionData({
    required this.question,
    required this.type,
    this.options,
    this.placeholder,
  });
}
