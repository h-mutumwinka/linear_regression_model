import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const StudentScoreApp());
}

class StudentScoreApp extends StatelessWidget {
  const StudentScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Score Predictor',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0B1020),
        fontFamily: 'Times New Roman',
      ),
      home: const PredictionPage(),
    );
  }
}

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final _formKey = GlobalKey<FormState>();

  final _attendanceController = TextEditingController();
  final _sleepHoursController = TextEditingController();
  final _previousScoresController = TextEditingController();
  final _tutoringSessionsController = TextEditingController();
  final _physicalActivityController = TextEditingController();
   
   //this is api call
  static const String _apiBaseUrl = 'https://student-score-hbkk.onrender.com';

  bool _isLoading = false;
  String _resultMessage = 'Enter values and tap Predict.';
  bool _isError = false;

  @override
  void dispose() {
    _attendanceController.dispose();
    _sleepHoursController.dispose();
    _previousScoresController.dispose();
    _tutoringSessionsController.dispose();
    _physicalActivityController.dispose();
    super.dispose();
  }

  String? _rangeValidator(String? value, String label, double min, double max) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return '$label must be a number';
    if (parsed < min || parsed > max) {
      return '$label must be between $min and $max';
    }
    return null;
  }

  Future<void> _predict() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      setState(() {
        _isError = true;
        _resultMessage = 'Please fix validation errors before predicting.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isError = false;
      _resultMessage = 'Predicting...';
    });

    final payload = {
      'Attendance': double.parse(_attendanceController.text.trim()),
      'Sleep_Hours': double.parse(_sleepHoursController.text.trim()),
      'Previous_Scores': double.parse(_previousScoresController.text.trim()),
      'Tutoring_Sessions': double.parse(_tutoringSessionsController.text.trim()),
      'Physical_Activity': double.parse(_physicalActivityController.text.trim()),
    };

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _isError = false;
          _resultMessage =
              'Predicted Exam Score: ${data['predicted_exam_score']}';
        });
      } else {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        final detail = responseBody['detail'] ?? 'Prediction request failed.';
        setState(() {
          _isError = true;
          _resultMessage = 'Error: $detail';
        });
      }
    } catch (error) {
      setState(() {
        _isError = true;
        _resultMessage = 'Network error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1020), Color(0xFF111827), Color(0xFF1F2937)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x331E3A8A),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Student Exam Predictor',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xE61F2937),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x335E6A85)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildNumberField(
                          controller: _attendanceController,
                          label: 'Attendance (%)',
                          min: 0,
                          max: 100,
                        ),
                        const SizedBox(height: 12),
                        _buildNumberField(
                          controller: _sleepHoursController,
                          label: 'Sleep Hours',
                          min: 0,
                          max: 24,
                        ),
                        const SizedBox(height: 12),
                        _buildNumberField(
                          controller: _previousScoresController,
                          label: 'Previous Scores',
                          min: 0,
                          max: 100,
                        ),
                        const SizedBox(height: 12),
                        _buildNumberField(
                          controller: _tutoringSessionsController,
                          label: 'Tutoring Sessions',
                          min: 0,
                          max: 20,
                        ),
                        const SizedBox(height: 12),
                        _buildNumberField(
                          controller: _physicalActivityController,
                          label: 'Physical Activity',
                          min: 0,
                          max: 10,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _predict,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Predict',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _isError
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isError
                                  ? const Color(0xFFFCA5A5)
                                  : const Color(0xFF86EFAC),
                            ),
                          ),
                          child: Text(
                            _resultMessage,
                            style: TextStyle(
                              color: _isError
                                  ? const Color(0xFF7F1D1D)
                                  : const Color(0xFF14532D),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required double min,
    required double max,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFFD1D5DB),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: const Color(0xCC111827),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x335E6A85)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.6),
        ),
      ),
      validator: (value) => _rangeValidator(value, label, min, max),
    );
  }
}
