/// Decision Companion - Onboarding Screen
/// Creative, story-driven onboarding with illustrations

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import '../../core/services/local_storage_service.dart';
import '../../injection_container.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _floatingController;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Every Choice\nMatters',
      subtitle:
          'From small daily decisions to life-changing moments, we\'re here to help you think it through.',
      illustration: _IllustrationType.crossroads,
      backgroundColor: const Color(0xFFF0F7FF),
      accentColor: const Color(0xFF4A90D9),
    ),
    OnboardingPage(
      title: 'Organize Your\nThoughts',
      subtitle:
          'Break down complex decisions into clear factors, weigh what matters most to you.',
      illustration: _IllustrationType.organize,
      backgroundColor: const Color(0xFFFFF5F0),
      accentColor: const Color(0xFFE07B54),
    ),
    OnboardingPage(
      title: 'Get Smart\nInsights',
      subtitle:
          'AI-powered analysis helps you see patterns and perspectives you might have missed.',
      illustration: _IllustrationType.insights,
      backgroundColor: const Color(0xFFF0FFF5),
      accentColor: const Color(0xFF4CAF7C),
    ),
    OnboardingPage(
      title: 'Decide With\nConfidence',
      subtitle:
          'Track your decisions, learn from outcomes, and grow as a decision-maker.',
      illustration: _IllustrationType.confidence,
      backgroundColor: const Color(0xFFFFF0F8),
      accentColor: const Color(0xFFB54A8C),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _getStarted() async {
    final storage = sl.get<LocalStorageService>();
    await storage.setOnboardingCompleted(true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;
    final currentPageData = _pages[_currentPage];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              currentPageData.backgroundColor,
              currentPageData.backgroundColor.withOpacity(0.6),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with skip
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Page indicator text
                    Text(
                      '${_currentPage + 1} of ${_pages.length}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: currentPageData.accentColor,
                      ),
                    ),
                    if (!isLastPage)
                      TextButton(
                        onPressed: _skipToEnd,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),

              // Bottom section
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  children: [
                    // Progress dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => _buildProgressDot(index),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Action button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLastPage ? _getStarted : _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentPageData.accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLastPage ? 'Get Started' : 'Continue',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isLastPage
                                  ? Icons.rocket_launch_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDot(int index) {
    final isActive = index == _currentPage;
    final currentPageData = _pages[_currentPage];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? currentPageData.accentColor
            : currentPageData.accentColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        children: [
          // Illustration
          Expanded(
            flex: 3,
            child: _buildIllustration(page),
          ),

          // Text content
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  page.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration(OnboardingPage page) {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        final float = math.sin(_floatingController.value * math.pi * 2) * 8;

        return Transform.translate(
          offset: Offset(0, float),
          child: Center(
            child: _getIllustrationWidget(page),
          ),
        );
      },
    );
  }

  Widget _getIllustrationWidget(OnboardingPage page) {
    switch (page.illustration) {
      case _IllustrationType.crossroads:
        return _CrossroadsIllustration(color: page.accentColor);
      case _IllustrationType.organize:
        return _OrganizeIllustration(color: page.accentColor);
      case _IllustrationType.insights:
        return _InsightsIllustration(color: page.accentColor);
      case _IllustrationType.confidence:
        return _ConfidenceIllustration(color: page.accentColor);
    }
  }
}

// Custom illustration widgets
class _CrossroadsIllustration extends StatelessWidget {
  final Color color;
  const _CrossroadsIllustration({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
            ),
          ),
          // Road paths
          Positioned(
            top: 40,
            child: Container(
              width: 60,
              height: 100,
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          Positioned(
            left: 30,
            child: Container(
              width: 100,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          Positioned(
            right: 30,
            child: Container(
              width: 100,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          // Center person icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          // Question marks
          Positioned(
            top: 20,
            right: 60,
            child: Text(
              '?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.5),
              ),
            ),
          ),
          Positioned(
            top: 30,
            left: 50,
            child: Text(
              '?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganizeIllustration extends StatelessWidget {
  final Color color;
  const _OrganizeIllustration({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cards arrangement
          Positioned(
            top: 50,
            left: 40,
            child: Transform.rotate(
              angle: -0.1,
              child: _buildCard(color, Icons.schedule_rounded, 'Time'),
            ),
          ),
          Positioned(
            top: 40,
            right: 40,
            child: Transform.rotate(
              angle: 0.15,
              child: _buildCard(color, Icons.attach_money_rounded, 'Cost'),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 50,
            child: Transform.rotate(
              angle: 0.05,
              child: _buildCard(color, Icons.favorite_rounded, 'Values'),
            ),
          ),
          Positioned(
            bottom: 50,
            right: 35,
            child: Transform.rotate(
              angle: -0.08,
              child: _buildCard(color, Icons.trending_up_rounded, 'Growth'),
            ),
          ),
          // Center balance scale
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.balance_rounded,
              color: color,
              size: 35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Color color, IconData icon, String label) {
    return Container(
      width: 80,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightsIllustration extends StatelessWidget {
  final Color color;
  const _InsightsIllustration({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Brain with lightbulb
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(
              Icons.psychology_rounded,
              color: color,
              size: 80,
            ),
          ),
          // Floating insights
          Positioned(
            top: 30,
            right: 50,
            child: _buildInsightBubble(color, Icons.lightbulb_rounded),
          ),
          Positioned(
            top: 60,
            left: 30,
            child: _buildInsightBubble(color, Icons.auto_graph_rounded),
          ),
          Positioned(
            bottom: 40,
            right: 40,
            child: _buildInsightBubble(color, Icons.analytics_rounded),
          ),
          Positioned(
            bottom: 60,
            left: 45,
            child: _buildInsightBubble(color, Icons.star_rounded),
          ),
          // Sparkles
          Positioned(
            top: 20,
            left: 80,
            child: Icon(
              Icons.auto_awesome,
              color: color.withOpacity(0.5),
              size: 20,
            ),
          ),
          Positioned(
            bottom: 30,
            right: 90,
            child: Icon(
              Icons.auto_awesome,
              color: color.withOpacity(0.4),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightBubble(Color color, IconData icon) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _ConfidenceIllustration extends StatelessWidget {
  final Color color;
  const _ConfidenceIllustration({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Success rings
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.15),
                width: 3,
              ),
            ),
          ),
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.25),
                width: 3,
              ),
            ),
          ),
          // Center trophy/target
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 50,
            ),
          ),
          // Stars around
          Positioned(
            top: 25,
            right: 70,
            child: Icon(Icons.star_rounded, color: color, size: 28),
          ),
          Positioned(
            top: 50,
            left: 50,
            child: Icon(Icons.star_rounded,
                color: color.withOpacity(0.6), size: 20),
          ),
          Positioned(
            bottom: 35,
            right: 55,
            child: Icon(Icons.star_rounded,
                color: color.withOpacity(0.7), size: 24),
          ),
          Positioned(
            bottom: 50,
            left: 65,
            child: Icon(Icons.star_rounded,
                color: color.withOpacity(0.5), size: 18),
          ),
          // Checkmarks
          Positioned(
            top: 80,
            right: 30,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: color, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

enum _IllustrationType {
  crossroads,
  organize,
  insights,
  confidence,
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final _IllustrationType illustration;
  final Color backgroundColor;
  final Color accentColor;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.illustration,
    required this.backgroundColor,
    required this.accentColor,
  });
}
