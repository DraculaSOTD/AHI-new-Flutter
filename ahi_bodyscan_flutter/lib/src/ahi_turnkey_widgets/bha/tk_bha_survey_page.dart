//
//  AHI BHA Survey Page - Collects additional health data for comprehensive assessment
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../ahi_turnkey_models/bha/ahi_bha_model.dart';
import '../../../core/theme/app_colors.dart';

class TkBHASurveyPage extends StatefulWidget {
  final Function(List<BHASurveyResponse>) onSurveyCompleted;
  final VoidCallback? onSkip;

  const TkBHASurveyPage({
    super.key,
    required this.onSurveyCompleted,
    this.onSkip,
  });

  @override
  State<TkBHASurveyPage> createState() => _TkBHASurveyPageState();
}

class _TkBHASurveyPageState extends State<TkBHASurveyPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Map<String, dynamic> _responses = {};

  // Survey sections
  final List<_SurveySection> _surveySections = [
    _SurveySection(
      title: 'Sleep & Recovery',
      icon: '😴',
      questions: [
        _SurveyQuestion(
          id: 'sleep_hours',
          question: 'How many hours of sleep do you typically get per night?',
          type: _QuestionType.slider,
          minValue: 4,
          maxValue: 12,
          defaultValue: 8,
          unit: 'hours',
        ),
        _SurveyQuestion(
          id: 'sleep_quality',
          question: 'How would you rate your sleep quality?',
          type: _QuestionType.scale,
          scaleOptions: ['Very Poor', 'Poor', 'Fair', 'Good', 'Excellent'],
        ),
        _SurveyQuestion(
          id: 'sleep_difficulty',
          question: 'How often do you have trouble falling asleep?',
          type: _QuestionType.scale,
          scaleOptions: ['Never', 'Rarely', 'Sometimes', 'Often', 'Always'],
        ),
      ],
    ),
    _SurveySection(
      title: 'Stress & Mental Health',
      icon: '🧠',
      questions: [
        _SurveyQuestion(
          id: 'stress_level',
          question: 'How would you rate your current stress level?',
          type: _QuestionType.scale,
          scaleOptions: ['Very Low', 'Low', 'Moderate', 'High', 'Very High'],
        ),
        _SurveyQuestion(
          id: 'stress_management',
          question: 'How well do you manage stress?',
          type: _QuestionType.scale,
          scaleOptions: ['Very Poor', 'Poor', 'Fair', 'Good', 'Excellent'],
        ),
        _SurveyQuestion(
          id: 'mood_frequency',
          question: 'Over the past 2 weeks, how often have you felt down or hopeless?',
          type: _QuestionType.scale,
          scaleOptions: ['Not at all', 'Several days', 'More than half', 'Nearly every day'],
        ),
      ],
    ),
    _SurveySection(
      title: 'Physical Activity',
      icon: '🏃',
      questions: [
        _SurveyQuestion(
          id: 'exercise_frequency',
          question: 'How many days per week do you exercise?',
          type: _QuestionType.slider,
          minValue: 0,
          maxValue: 7,
          defaultValue: 3,
          unit: 'days/week',
        ),
        _SurveyQuestion(
          id: 'exercise_intensity',
          question: 'What is the typical intensity of your workouts?',
          type: _QuestionType.multiChoice,
          choices: ['Light (walking, yoga)', 'Moderate (jogging, cycling)', 'Vigorous (running, HIIT)', 'Mixed intensity'],
        ),
        _SurveyQuestion(
          id: 'daily_steps',
          question: 'Approximately how many steps do you take per day?',
          type: _QuestionType.multiChoice,
          choices: ['Less than 5,000', '5,000-7,500', '7,500-10,000', '10,000+'],
        ),
      ],
    ),
    _SurveySection(
      title: 'Nutrition & Lifestyle',
      icon: '🥗',
      questions: [
        _SurveyQuestion(
          id: 'water_intake',
          question: 'How many glasses of water do you drink daily?',
          type: _QuestionType.slider,
          minValue: 1,
          maxValue: 12,
          defaultValue: 6,
          unit: 'glasses',
        ),
        _SurveyQuestion(
          id: 'alcohol_frequency',
          question: 'How often do you consume alcohol?',
          type: _QuestionType.multiChoice,
          choices: ['Never', '1-2 times per month', '1-2 times per week', '3-4 times per week', 'Daily'],
        ),
        _SurveyQuestion(
          id: 'smoking_status',
          question: 'Do you smoke or use tobacco products?',
          type: _QuestionType.multiChoice,
          choices: ['Never smoked', 'Former smoker', 'Occasional smoker', 'Regular smoker'],
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Health Survey'),
            Text(
              'Page ${_currentPage + 1} of ${_surveySections.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.onSkip != null)
            TextButton(
              onPressed: widget.onSkip,
              child: const Text('Skip'),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildContent(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Progress Indicator
        _buildProgressIndicator(),
        
        // Survey Content
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: _surveySections.length,
            itemBuilder: (context, index) {
              return _buildSurveySection(_surveySections[index]);
            },
          ),
        ),
        
        // Navigation Buttons
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: List.generate(_surveySections.length, (index) {
              final isActive = index <= _currentPage;
              final isCurrent = index == _currentPage;
              
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index == _surveySections.length - 1 ? 0 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            '${((_currentPage + 1) / _surveySections.length * 100).round()}% Complete',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveySection(_SurveySection section) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(section.icon, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(
                  section.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, duration: 600.ms),
          
          const SizedBox(height: 24),
          
          // Questions
          ...section.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            
            return _buildQuestion(question)
                .animate(delay: (200 + index * 100).ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.3, duration: 500.ms);
          }),
        ],
      ),
    );
  }

  Widget _buildQuestion(_SurveyQuestion question) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.question,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildQuestionInput(question),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionInput(_SurveyQuestion question) {
    switch (question.type) {
      case _QuestionType.scale:
        return _buildScaleInput(question);
      case _QuestionType.multiChoice:
        return _buildMultiChoiceInput(question);
      case _QuestionType.slider:
        return _buildSliderInput(question);
    }
  }

  Widget _buildScaleInput(_SurveyQuestion question) {
    final currentValue = _responses[question.id] as int? ?? -1;
    
    return Column(
      children: List.generate(question.scaleOptions!.length, (index) {
        final isSelected = currentValue == index;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _responses[question.id] = index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Text(
              question.scaleOptions![index],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMultiChoiceInput(_SurveyQuestion question) {
    final currentValue = _responses[question.id] as int? ?? -1;
    
    return Column(
      children: List.generate(question.choices!.length, (index) {
        final isSelected = currentValue == index;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _responses[question.id] = index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question.choices![index],
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSliderInput(_SurveyQuestion question) {
    final currentValue = _responses[question.id] as double? ?? question.defaultValue;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${question.minValue.toInt()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${currentValue.toInt()} ${question.unit ?? ''}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              '${question.maxValue.toInt()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: Colors.grey[300],
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: currentValue,
            min: question.minValue,
            max: question.maxValue,
            divisions: (question.maxValue - question.minValue).toInt(),
            onChanged: (value) {
              setState(() {
                _responses[question.id] = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    final isLastPage = _currentPage == _surveySections.length - 1;
    final canProceed = _isSectionComplete(_surveySections[_currentPage]);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Previous Button
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('Previous'),
              ),
            ),
          
          if (_currentPage > 0) const SizedBox(width: 16),
          
          // Next/Complete Button
          Expanded(
            child: ElevatedButton(
              onPressed: canProceed
                  ? () {
                      if (isLastPage) {
                        _completeSurvey();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(isLastPage ? 'Complete Survey' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSectionComplete(_SurveySection section) {
    for (final question in section.questions) {
      if (!_responses.containsKey(question.id)) {
        return false;
      }
    }
    return true;
  }

  void _completeSurvey() {
    final List<BHASurveyResponse> responses = [];
    
    for (final section in _surveySections) {
      for (final question in section.questions) {
        final responseValue = _responses[question.id];
        if (responseValue != null) {
          // Convert response to score based on question type
          double? score;
          dynamic response = responseValue;
          
          switch (question.type) {
            case _QuestionType.scale:
              // Scale questions: convert to 0-10 scale
              score = (responseValue as int) / (question.scaleOptions!.length - 1) * 10;
              response = question.scaleOptions![responseValue];
              break;
            case _QuestionType.multiChoice:
              // Multi-choice: use index as response, calculate score based on context
              response = question.choices![responseValue as int];
              score = _calculateMultiChoiceScore(question.id, responseValue);
              break;
            case _QuestionType.slider:
              // Slider: normalize to 0-10 scale
              final normalizedValue = ((responseValue as double) - question.minValue) /
                                    (question.maxValue - question.minValue);
              score = normalizedValue * 10;
              response = responseValue;
              break;
          }
          
          responses.add(BHASurveyResponse(
            questionId: question.id,
            response: response,
            score: score,
          ));
        }
      }
    }
    
    widget.onSurveyCompleted(responses);
  }

  double _calculateMultiChoiceScore(String questionId, int responseIndex) {
    // Context-specific scoring for multi-choice questions
    switch (questionId) {
      case 'exercise_intensity':
        return [2.0, 5.0, 8.0, 10.0][responseIndex]; // Higher intensity = higher score
      case 'daily_steps':
        return [2.0, 5.0, 8.0, 10.0][responseIndex]; // More steps = higher score
      case 'alcohol_frequency':
        return [10.0, 8.0, 6.0, 3.0, 0.0][responseIndex]; // Less alcohol = higher score
      case 'smoking_status':
        return [10.0, 7.0, 3.0, 0.0][responseIndex]; // No smoking = higher score
      default:
        return responseIndex.toDouble(); // Default linear scoring
    }
  }
}

// Survey data structures
class _SurveySection {
  final String title;
  final String icon;
  final List<_SurveyQuestion> questions;

  _SurveySection({
    required this.title,
    required this.icon,
    required this.questions,
  });
}

class _SurveyQuestion {
  final String id;
  final String question;
  final _QuestionType type;
  final List<String>? scaleOptions;
  final List<String>? choices;
  final double minValue;
  final double maxValue;
  final double defaultValue;
  final String? unit;

  _SurveyQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.scaleOptions,
    this.choices,
    this.minValue = 0,
    this.maxValue = 10,
    this.defaultValue = 5,
    this.unit,
  });
}

enum _QuestionType {
  scale,
  multiChoice,
  slider,
}