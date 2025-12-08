import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:convert';

// Diagnosis Mode screen - Symptom Checker with Flask Backend
class DiagnosisModeScreen extends StatefulWidget {
  const DiagnosisModeScreen({super.key});

  @override
  State<DiagnosisModeScreen> createState() => _DiagnosisModeScreenState();
}

class _DiagnosisModeScreenState extends State<DiagnosisModeScreen> {
  int _currentQuestionIndex = 0;
  final Map<String, dynamic> _answers = {};
  bool _showingResults = false;
  bool _isLoading = false;
  String? _diagnosisResult;
  String? _errorMessage;

  // Questions matching Flask backend exactly
  final List<DiagnosisQuestion> _questions = [
    DiagnosisQuestion(
      id: 'main_symptom',
      question: 'What is your main symptom or health concern?',
      type: QuestionType.text,
      placeholder: 'Describe your symptom (e.g., headache, fever, cough...)',
      required: true,
    ),
    DiagnosisQuestion(
      id: 'duration',
      question: 'When did this symptom start?',
      type: QuestionType.choice,
      options: [
        'Less than 24 hours ago',
        '1-3 days ago',
        '4-7 days ago',
        '1-4 weeks ago',
        'More than a month ago',
      ],
      required: true,
    ),
    DiagnosisQuestion(
      id: 'severity',
      question: 'How would you rate the severity?',
      subtitle: '1 = Mild, 10 = Severe',
      type: QuestionType.scale,
      min: 1,
      max: 10,
      required: true,
    ),
    DiagnosisQuestion(
      id: 'additional_symptoms',
      question: 'Are you experiencing any of these additional symptoms?',
      type: QuestionType.multiSelect,
      options: [
        'Fever',
        'Fatigue',
        'Nausea',
        'Vomiting',
        'Diarrhea',
        'Headache',
        'Cough',
        'Shortness of breath',
        'Dizziness',
        'Body aches',
        'Loss of appetite',
        'None of these',
      ],
      required: false,
    ),
    DiagnosisQuestion(
      id: 'age',
      question: 'What is your age?',
      type: QuestionType.number,
      placeholder: 'Enter your age',
      required: true,
    ),
    DiagnosisQuestion(
      id: 'chronic_conditions',
      question: 'Do you have any chronic medical conditions?',
      type: QuestionType.text,
      placeholder: 'e.g., diabetes, hypertension, asthma (or "None")',
      required: false,
    ),
    DiagnosisQuestion(
      id: 'medications',
      question: 'Are you currently taking any medications?',
      type: QuestionType.text,
      placeholder: 'e.g., aspirin, blood pressure meds (or "None")',
      required: false,
    ),
  ];

void _handleAnswer(dynamic answer) {
  setState(() {
    _answers[_questions[_currentQuestionIndex].id] = answer;

    // Check for emergency on main symptom
    if (_questions[_currentQuestionIndex].id == 'main_symptom') {
      String symptomText = answer.toString().toLowerCase();
      List<String> emergencyKeywords = [
        'chest pain', 'heart attack', 'stroke', 'can\'t breathe',
        'severe bleeding', 'unconscious', 'seizure', 'suicidal'
      ];
      
      for (String keyword in emergencyKeywords) {
        if (symptomText.contains(keyword)) {
          // Show emergency alert
          _showEmergencyAlert(keyword);
          return;
        }
      }
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
    } else {
      // All questions answered, get diagnosis
      _getDiagnosis();
    }
  });
}

void _showEmergencyAlert(String keyword) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.red, size: 32),
          SizedBox(width: 8),
          Text('EMERGENCY'),
        ],
      ),
      content: Text(
        '⚠️ Your symptom "$keyword" may require immediate medical attention.\n\n'
        'Please call emergency services (911) or go to the nearest emergency room immediately.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop(); // Go back to home
          },
          child: const Text('I Understand'),
        ),
      ],
    ),
  );
}

  void _goBack() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

Future<void> _getDiagnosis() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    // Send answers directly to get diagnosis (no session needed)
    final result = await ApiService.getDiagnosis(_answers);

    setState(() {
      if (result['status'] == 'error') {
        _errorMessage = result['message'] ?? 'Unknown error occurred';
      } else if (result['status'] == 'success') {
        _diagnosisResult = result['diagnosis'];
      } else {
        _errorMessage = result['message'] ?? 'Unknown error occurred';
      }
      _showingResults = true;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _errorMessage = 'Could not connect to server. Please try again.';
      _showingResults = true;
      _isLoading = false;
    });
  }
}

  void _restartDiagnosis() {
    setState(() {
      _currentQuestionIndex = 0;
      _answers.clear();
      _showingResults = false;
      _diagnosisResult = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF7F8FA),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Progress indicator
              if (!_showingResults && !_isLoading)
                _buildProgressIndicator(),

              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingView()
                    : _showingResults
                        ? _buildResultsView()
                        : _buildQuestionView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_showingResults || _currentQuestionIndex == 0) {
                Navigator.of(context).pop();
              } else {
                _goBack();
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFF7F8FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF141718),
                size: 24,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Symptom Checker',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF141718),
                fontSize: 24,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    double progress = (_currentQuestionIndex + 1) / _questions.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                style: TextStyle(
                  color: const Color(0xFF323142).withOpacity(0.7),
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF155DFC)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF155DFC).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF155DFC),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Analyzing your symptoms...',
            style: TextStyle(
              color: Color(0xFF141718),
              fontSize: 18,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a moment',
            style: TextStyle(
              color: const Color(0xFF323142).withOpacity(0.6),
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionView() {
    final question = _questions[_currentQuestionIndex];

    switch (question.type) {
      case QuestionType.text:
        return _TextQuestionView(
          question: question,
          initialValue: _answers[question.id]?.toString() ?? '',
          onSubmit: _handleAnswer,
        );
      case QuestionType.choice:
        return _ChoiceQuestionView(
          question: question,
          selectedValue: _answers[question.id],
          onSelect: _handleAnswer,
        );
      case QuestionType.scale:
        return _ScaleQuestionView(
          question: question,
          initialValue: _answers[question.id] ?? 5,
          onSubmit: _handleAnswer,
        );
      case QuestionType.number:
        return _NumberQuestionView(
          question: question,
          initialValue: _answers[question.id]?.toString() ?? '',
          onSubmit: _handleAnswer,
        );
      case QuestionType.multiSelect:
        return _MultiSelectQuestionView(
          question: question,
          initialValues: _answers[question.id] ?? [],
          onContinue: _handleAnswer,
        );
    }
  }

  Widget _buildResultsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Error or Diagnosis
          if (_errorMessage != null)
            _buildErrorCard()
          else if (_diagnosisResult != null)
            _buildDiagnosisCard(),

          const SizedBox(height: 24),

          // Disclaimer
          _buildDisclaimerCard(),

          const SizedBox(height: 24),

          // Action buttons
          _buildActionButtons(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF5350)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF5350), size: 48),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB71C1C),
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF155DFC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medical_information,
                  color: Color(0xFF155DFC),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Assessment Results',
                  style: TextStyle(
                    color: Color(0xFF141718),
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          // Display diagnosis - parse and format if JSON
          _buildFormattedDiagnosis(_diagnosisResult!),
        ],
      ),
    );
  }

  Widget _buildFormattedDiagnosis(String diagnosis) {
  try {
    // Extract JSON from response
    String jsonString = diagnosis;
    
    // Check if wrapped in markdown code blocks
    final jsonBlockMatch = RegExp(r'```json\s*([\s\S]*?)\s*```').firstMatch(diagnosis);
    if (jsonBlockMatch != null) {
      jsonString = jsonBlockMatch.group(1) ?? diagnosis;
    } else {
      // Try to find JSON object
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(diagnosis);
      if (jsonMatch != null) {
        jsonString = jsonMatch.group(0) ?? diagnosis;
      }
    }

    // Parse JSON
    final data = jsonDecode(jsonString);
    
    // Unwrap if has differential_diagnosis wrapper
    Map<String, dynamic> diagnosisData;
    if (data['differential_diagnosis'] != null) {
      diagnosisData = data['differential_diagnosis'];
    } else {
      diagnosisData = data;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Most Likely Conditions
        if (diagnosisData['most_likely_conditions'] != null)
          _buildMostLikelySection(diagnosisData['most_likely_conditions']),
        
        const SizedBox(height: 20),
        
        // Possible Conditions
        if (diagnosisData['possible_conditions'] != null)
          _buildPossibleSection(diagnosisData['possible_conditions']),
        
        const SizedBox(height: 20),
        
        // Serious Conditions
        if (diagnosisData['less_likely_but_serious'] != null)
          _buildSeriousSection(diagnosisData['less_likely_but_serious']),
        
        const SizedBox(height: 20),
        
        // Clinical Recommendation
        if (diagnosisData['clinical_recommendation'] != null)
          _buildRecommendationSection(diagnosisData['clinical_recommendation']),
        
        const SizedBox(height: 20),
        
        // What to Monitor
        if (diagnosisData['what_to_monitor'] != null)
          _buildMonitorSection(diagnosisData['what_to_monitor']),
      ],
    );
  } catch (e) {
    // If parsing fails, show as plain text
    print('Error parsing diagnosis: $e');
    return Text(
      diagnosis,
      style: const TextStyle(
        color: Color(0xFF323142),
        fontSize: 14,
        fontFamily: 'Poppins',
        height: 1.6,
      ),
    );
  }
}

Widget _buildMostLikelySection(List<dynamic> conditions) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFF0FFF4),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF28A745).withOpacity(0.3)),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF28A745), size: 24),
            SizedBox(width: 8),
            Text(
              'Most Likely (60-70%)',
              style: TextStyle(
                color: Color(0xFF28A745),
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...conditions.map((cond) => _buildConditionCard(
          cond['condition'] ?? 'Unknown',
          cond['why_it_matches'] ?? '',
          cond['self_care'] ?? '',
          cond['when_to_see_doctor'] ?? '',
          const Color(0xFF28A745),
        )),
      ],
    ),
  );
}

Widget _buildPossibleSection(List<dynamic> conditions) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFFFFBF0),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.3)),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFFF57C00), size: 24),
            SizedBox(width: 8),
            Text(
              'Possible (20-30%)',
              style: TextStyle(
                color: Color(0xFFF57C00),
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...conditions.map((cond) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cond['condition'] ?? 'Unknown',
                  style: const TextStyle(
                    color: Color(0xFFF57C00),
                    fontSize: 15,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (cond['explanation'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    cond['explanation'],
                    style: TextStyle(
                      color: const Color(0xFF323142).withOpacity(0.8),
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ],
            ),
          ),
        )),
      ],
    ),
  );
}

Widget _buildSeriousSection(List<dynamic> conditions) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFFFF5F5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFDC3545).withOpacity(0.3)),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.warning_amber, color: Color(0xFFDC3545), size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Serious to Rule Out',
                style: TextStyle(
                  color: Color(0xFFDC3545),
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...conditions.map((cond) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cond['condition'] ?? 'Unknown',
                  style: const TextStyle(
                    color: Color(0xFFDC3545),
                    fontSize: 15,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (cond['red_flags'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '🚩 ${cond['red_flags']}',
                    style: TextStyle(
                      color: const Color(0xFF323142).withOpacity(0.8),
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ],
            ),
          ),
        )),
      ],
    ),
  );
}

Widget _buildRecommendationSection(Map<String, dynamic> recommendation) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFE3F2FD),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.medical_services, color: Color(0xFF1976D2), size: 24),
            SizedBox(width: 8),
            Text(
              'Clinical Recommendation',
              style: TextStyle(
                color: Color(0xFF1976D2),
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recommendation['urgency_level'] != null)
          _buildInfoRow('Urgency', recommendation['urgency_level'], Icons.priority_high),
        if (recommendation['timeframe'] != null)
          _buildInfoRow('Timeframe', recommendation['timeframe'], Icons.schedule),
        if (recommendation['diagnostic_tests'] != null) ...[
          const SizedBox(height: 8),
          const Text(
            'Suggested Tests:',
            style: TextStyle(
              color: Color(0xFF1976D2),
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          ..._buildTestsList(recommendation['diagnostic_tests']),
        ],
      ],
    ),
  );
}

List<Widget> _buildTestsList(dynamic tests) {
  List<String> testList = [];
  if (tests is List) {
    testList = tests.map((t) => t.toString()).toList();
  } else if (tests is String) {
    testList = tests.split(',').map((t) => t.trim()).toList();
  }
  
  return testList.map((test) => Padding(
    padding: const EdgeInsets.only(left: 8, bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: Color(0xFF1976D2))),
        Expanded(
          child: Text(
            test,
            style: TextStyle(
              color: const Color(0xFF323142).withOpacity(0.8),
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    ),
  )).toList();
}

Widget _buildMonitorSection(Map<String, dynamic> monitor) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3)),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.visibility, color: Color(0xFFF57C00), size: 24),
            SizedBox(width: 8),
            Text(
              'What to Monitor',
              style: TextStyle(
                color: Color(0xFFF57C00),
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (monitor['warning_signs'] != null) ...[
          const Text(
            'Warning Signs:',
            style: TextStyle(
              color: Color(0xFFF57C00),
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          ..._buildWarningsList(monitor['warning_signs']),
        ],
        if (monitor['when_to_seek_immediate_care'] != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDC3545)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.emergency, color: Color(0xFFDC3545), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    monitor['when_to_seek_immediate_care'],
                    style: const TextStyle(
                      color: Color(0xFFDC3545),
                      fontSize: 13,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

List<Widget> _buildWarningsList(dynamic warnings) {
  List<String> warningList = [];
  if (warnings is List) {
    warningList = warnings.map((w) => w.toString()).toList();
  } else if (warnings is String) {
    warningList = warnings.split(',').map((w) => w.trim()).toList();
  }
  
  return warningList.map((warning) => Padding(
    padding: const EdgeInsets.only(left: 8, bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('⚠️ ', style: TextStyle(fontSize: 12)),
        Expanded(
          child: Text(
            warning,
            style: TextStyle(
              color: const Color(0xFF323142).withOpacity(0.8),
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    ),
  )).toList();
}

Widget _buildConditionCard(String condition, String whyMatches, String selfCare, String whenToSeeDoctor, Color color) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          condition,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        if (whyMatches.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            whyMatches,
            style: TextStyle(
              color: const Color(0xFF323142).withOpacity(0.8),
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
        ],
        if (selfCare.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.self_improvement, size: 16, color: Color(0xFF28A745)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Self-care: $selfCare',
                  style: const TextStyle(
                    color: Color(0xFF28A745),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ],
        if (whenToSeeDoctor.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.local_hospital, size: 16, color: Color(0xFFDC3545)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'See doctor if: $whenToSeeDoctor',
                  style: const TextStyle(
                    color: Color(0xFFDC3545),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

Widget _buildInfoRow(String label, String value, IconData icon) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1976D2)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Color(0xFF1976D2),
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: const Color(0xFF323142).withOpacity(0.8),
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildDisclaimerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB300)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF57C00), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medical Disclaimer',
                  style: TextStyle(
                    color: Color(0xFFE65100),
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This is for educational purposes only and does not replace professional medical advice. Always consult a healthcare provider.',
                  style: TextStyle(
                    color: const Color(0xFF5D4037).withOpacity(0.8),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // New Assessment button
        GestureDetector(
          onTap: _restartDiagnosis,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF155DFC), Color(0xFF1E6FFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF155DFC).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'New Assessment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Back to Chat button
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF155DFC)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, color: Color(0xFF155DFC), size: 20),
                SizedBox(width: 8),
                Text(
                  'Back to Chat',
                  style: TextStyle(
                    color: Color(0xFF155DFC),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// QUESTION TYPE ENUM
// ============================================================================

enum QuestionType { text, choice, scale, number, multiSelect }

// ============================================================================
// QUESTION MODEL
// ============================================================================

class DiagnosisQuestion {
  final String id;
  final String question;
  final String? subtitle;
  final QuestionType type;
  final List<String>? options;
  final String? placeholder;
  final int? min;
  final int? max;
  final bool required;

  DiagnosisQuestion({
    required this.id,
    required this.question,
    this.subtitle,
    required this.type,
    this.options,
    this.placeholder,
    this.min,
    this.max,
    this.required = true,
  });
}

// ============================================================================
// TEXT QUESTION VIEW
// ============================================================================

class _TextQuestionView extends StatefulWidget {
  final DiagnosisQuestion question;
  final String initialValue;
  final Function(String) onSubmit;

  const _TextQuestionView({
    required this.question,
    required this.initialValue,
    required this.onSubmit,
  });

  @override
  State<_TextQuestionView> createState() => _TextQuestionViewState();
}

class _TextQuestionViewState extends State<_TextQuestionView> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    String value = _controller.text.trim();
    if (value.isEmpty && widget.question.required) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your answer')),
      );
      return;
    }
    widget.onSubmit(value.isEmpty ? 'None' : value);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildQuestionCard(),
          const SizedBox(height: 24),
          _buildTextField(),
          const SizedBox(height: 24),
          _buildContinueButton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF7F8FA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF155DFC).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        widget.question.question,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF141718),
          fontSize: 20,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextField(
        controller: _controller,
        maxLines: 3,
        style: const TextStyle(
          color: Color(0xFF323142),
          fontSize: 16,
          fontFamily: 'Poppins',
        ),
        decoration: InputDecoration(
          hintText: widget.question.placeholder ?? 'Type your answer...',
          hintStyle: TextStyle(
            color: const Color(0xFF323142).withOpacity(0.4),
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return GestureDetector(
      onTap: _submit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF155DFC), Color(0xFF1E6FFF)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF155DFC).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Continue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CHOICE QUESTION VIEW
// ============================================================================

class _ChoiceQuestionView extends StatelessWidget {
  final DiagnosisQuestion question;
  final String? selectedValue;
  final Function(String) onSelect;

  const _ChoiceQuestionView({
    required this.question,
    required this.selectedValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildQuestionCard(),
          const SizedBox(height: 24),
          ...question.options!.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildOptionButton(option),
              )),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF7F8FA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF155DFC).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        question.question,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF141718),
          fontSize: 20,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildOptionButton(String option) {
    return GestureDetector(
      onTap: () => onSelect(option),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF155DFC).withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: const TextStyle(
                  color: Color(0xFF212121),
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF155DFC),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SCALE QUESTION VIEW
// ============================================================================

class _ScaleQuestionView extends StatefulWidget {
  final DiagnosisQuestion question;
  final int initialValue;
  final Function(int) onSubmit;

  const _ScaleQuestionView({
    required this.question,
    required this.initialValue,
    required this.onSubmit,
  });

  @override
  State<_ScaleQuestionView> createState() => _ScaleQuestionViewState();
}

class _ScaleQuestionViewState extends State<_ScaleQuestionView> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildQuestionCard(),
          const SizedBox(height: 40),
          _buildScaleValue(),
          const SizedBox(height: 24),
          _buildSlider(),
          const SizedBox(height: 16),
          _buildScaleLabels(),
          const SizedBox(height: 40),
          _buildContinueButton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF7F8FA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF155DFC).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.question.question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF141718),
              fontSize: 20,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (widget.question.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.question.subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF323142).withOpacity(0.6),
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScaleValue() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF155DFC), Color(0xFF1E6FFF)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF155DFC).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _value.toInt().toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildSlider() {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: const Color(0xFF155DFC),
        inactiveTrackColor: const Color(0xFFE0E0E0),
        thumbColor: const Color(0xFF155DFC),
        overlayColor: const Color(0xFF155DFC).withOpacity(0.2),
        trackHeight: 8,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
      ),
      child: Slider(
        value: _value,
        min: (widget.question.min ?? 1).toDouble(),
        max: (widget.question.max ?? 10).toDouble(),
        divisions: (widget.question.max ?? 10) - (widget.question.min ?? 1),
        onChanged: (value) {
          setState(() {
            _value = value;
          });
        },
      ),
    );
  }

  Widget _buildScaleLabels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Mild',
          style: TextStyle(
            color: const Color(0xFF323142).withOpacity(0.6),
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          'Severe',
          style: TextStyle(
            color: const Color(0xFF323142).withOpacity(0.6),
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return GestureDetector(
      onTap: () => widget.onSubmit(_value.toInt()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF155DFC), Color(0xFF1E6FFF)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF155DFC).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Continue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// NUMBER QUESTION VIEW
// ============================================================================

class _NumberQuestionView extends StatefulWidget {
  final DiagnosisQuestion question;
  final String initialValue;
  final Function(int) onSubmit;

  const _NumberQuestionView({
    required this.question,
    required this.initialValue,
    required this.onSubmit,
  });

  @override
  State<_NumberQuestionView> createState() => _NumberQuestionViewState();
}

class _NumberQuestionViewState extends State<_NumberQuestionView> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    int? value = int.tryParse(_controller.text);
    if (value == null && widget.question.required) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number')),
      );
      return;
    }
    widget.onSubmit(value ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildQuestionCard(),
          const SizedBox(height: 24),
          _buildNumberField(),
          const SizedBox(height: 24),
          _buildContinueButton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF7F8FA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF155DFC).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        widget.question.question,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF141718),
          fontSize: 20,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildNumberField() {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF323142),
          fontSize: 32,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: TextStyle(
            color: const Color(0xFF323142).withOpacity(0.3),
            fontSize: 32,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return GestureDetector(
      onTap: _submit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF155DFC), Color(0xFF1E6FFF)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF155DFC).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Continue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// MULTI-SELECT QUESTION VIEW
// ============================================================================

class _MultiSelectQuestionView extends StatefulWidget {
  final DiagnosisQuestion question;
  final List<String> initialValues;
  final Function(List<String>) onContinue;

  const _MultiSelectQuestionView({
    required this.question,
    required this.initialValues,
    required this.onContinue,
  });

  @override
  State<_MultiSelectQuestionView> createState() => _MultiSelectQuestionViewState();
}

class _MultiSelectQuestionViewState extends State<_MultiSelectQuestionView> {
  late List<String> _selectedOptions;

  @override
  void initState() {
    super.initState();
    _selectedOptions = List.from(widget.initialValues);
  }

  void _toggleOption(String option) {
    setState(() {
      if (_selectedOptions.contains(option)) {
        _selectedOptions.remove(option);
      } else {
        _selectedOptions.add(option);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildQuestionCard(),
          const SizedBox(height: 24),
          ...widget.question.options!.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMultiSelectOption(option),
              )),
          const SizedBox(height: 24),
          _buildContinueButton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF7F8FA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF155DFC).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.question.question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF141718),
              fontSize: 20,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that apply',
            style: TextStyle(
              color: const Color(0xFF323142).withOpacity(0.6),
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectOption(String option) {
    final isSelected = _selectedOptions.contains(option);

    return GestureDetector(
      onTap: () => _toggleOption(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF155DFC), Color(0xFF1E6FFF)],
                )
              : const LinearGradient(
                  colors: [Colors.white, Colors.white],
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE0E0E0),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF155DFC).withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : const Color(0xFF155DFC),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Color(0xFF155DFC), size: 16)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF212121),
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return GestureDetector(
      onTap: () => widget.onContinue(_selectedOptions),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF155DFC), Color(0xFF1E6FFF)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
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
              _selectedOptions.isEmpty
                  ? 'Skip'
                  : 'Continue (${_selectedOptions.length} selected)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

// Extension for regex matching
extension RegExpExtension on String {
  RegExpMatch? match(RegExp regex) => regex.firstMatch(this);
}
