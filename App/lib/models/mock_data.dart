/// Decision Companion - Mock Data
/// Sample data for UI development

import 'package:flutter/material.dart';
import 'models.dart';

class MockData {
  MockData._();

  static User get currentUser => User(
        id: '1',
        name: 'John Doe',
        email: 'john.doe@example.com',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );

  static List<Decision> get recentDecisions => [
        Decision(
          id: '1',
          title: 'Which laptop to buy?',
          options: [
            const DecisionOption(id: 'o1', title: 'MacBook Pro M3'),
            const DecisionOption(id: 'o2', title: 'Dell XPS 15'),
            const DecisionOption(id: 'o3', title: 'ThinkPad X1 Carbon'),
          ],
          factors: [
            const DecisionFactor(
              id: 'f1',
              name: 'Price',
              icon: Icons.attach_money_rounded,
              color: Color(0xFF10B981),
              weight: 8,
            ),
            const DecisionFactor(
              id: 'f2',
              name: 'Performance',
              icon: Icons.speed_rounded,
              color: Color(0xFF3B82F6),
              weight: 9,
            ),
          ],
          result: DecisionResult(
            recommendedOptionId: 'o1',
            confidence: 87,
            optionScores: {'o1': 87, 'o2': 75, 'o3': 72},
            explanation:
                'Based on your priorities of performance and build quality, the MacBook Pro M3 offers the best balance.',
            insights: [
              'The MacBook Pro excels in performance benchmarks',
              'Dell XPS offers better value for money',
              'ThinkPad has the best keyboard experience',
            ],
            analyzedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          completedAt: DateTime.now().subtract(const Duration(days: 2)),
          satisfaction: 4,
          status: DecisionStatus.completed,
        ),
        Decision(
          id: '2',
          title: 'Should I change jobs?',
          options: [
            const DecisionOption(id: 'o1', title: 'Stay at current job'),
            const DecisionOption(id: 'o2', title: 'Accept new offer'),
          ],
          factors: [
            const DecisionFactor(
              id: 'f1',
              name: 'Salary',
              icon: Icons.attach_money_rounded,
              color: Color(0xFF10B981),
              weight: 7,
            ),
            const DecisionFactor(
              id: 'f2',
              name: 'Growth',
              icon: Icons.trending_up_rounded,
              color: Color(0xFF6366F1),
              weight: 9,
            ),
          ],
          result: DecisionResult(
            recommendedOptionId: 'o2',
            confidence: 72,
            optionScores: {'o1': 65, 'o2': 72},
            explanation:
                'The new opportunity offers better growth potential aligned with your career goals.',
            insights: [
              'New role has 25% salary increase',
              'More leadership opportunities available',
              'Consider the learning curve at new company',
            ],
            analyzedAt: DateTime.now().subtract(const Duration(days: 7)),
          ),
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          completedAt: DateTime.now().subtract(const Duration(days: 7)),
          satisfaction: 5,
          status: DecisionStatus.completed,
        ),
        Decision(
          id: '3',
          title: 'Which apartment to rent?',
          options: [
            const DecisionOption(id: 'o1', title: 'Downtown Studio'),
            const DecisionOption(id: 'o2', title: 'Suburban 2BR'),
            const DecisionOption(id: 'o3', title: 'City 1BR'),
          ],
          factors: [],
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          status: DecisionStatus.draft,
        ),
      ];

  static List<AiSuggestion> get aiSuggestions => [
        const AiSuggestion(
          id: 's1',
          name: 'Environmental Impact',
          reason:
              'Based on your past decisions, sustainability seems important to you.',
          isIncluded: false,
        ),
        const AiSuggestion(
          id: 's2',
          name: 'Resale Value',
          reason:
              'For purchases over \$1000, resale value is often a consideration.',
          isIncluded: true,
        ),
        const AiSuggestion(
          id: 's3',
          name: 'Brand Reliability',
          reason:
              'Product reliability ratings vary significantly between brands.',
          isIncluded: false,
        ),
        const AiSuggestion(
          id: 's4',
          name: 'Warranty Coverage',
          reason:
              'Different options have varying warranty terms worth considering.',
          isIncluded: false,
        ),
      ];

  static List<UserFeedback> get feedbackHistory => [
        UserFeedback(
          id: 'fb1',
          decisionId: '1',
          rating: 5,
          comment: 'Very helpful in organizing my thoughts!',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        UserFeedback(
          id: 'fb2',
          decisionId: '2',
          rating: 4,
          comment: 'The AI suggestions were useful.',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ];

  static List<AppNotification> get notifications => [
        AppNotification(
          id: 'n1',
          title: 'Decision Reminder',
          message: 'You have a pending decision about apartment rental.',
          type: NotificationType.reminder,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        AppNotification(
          id: 'n2',
          title: 'Weekly Insight',
          message:
              'You made 3 decisions this week with 85% average confidence.',
          type: NotificationType.insight,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        AppNotification(
          id: 'n3',
          title: 'Rate Your Decision',
          message: 'How satisfied are you with your laptop choice?',
          type: NotificationType.decision,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];

  static AnalyticsData get analyticsData => AnalyticsData(
        totalDecisions: 24,
        completedDecisions: 18,
        averageConfidence: 78.5,
        averageSatisfaction: 4.2,
        factorUsage: {
          'Price': 15,
          'Quality': 12,
          'Time': 8,
          'Risk': 6,
          'Convenience': 10,
        },
        trends: List.generate(7, (index) {
          return DecisionTrend(
            date: DateTime.now().subtract(Duration(days: 6 - index)),
            count: (index + 1) % 4 + 1,
            averageConfidence: 70 + (index * 3).toDouble(),
          );
        }),
      );

  static List<AdminUser> get adminUsers => [
        AdminUser(
          id: 'u1',
          name: 'John Doe',
          email: 'john@example.com',
          lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
          totalDecisions: 24,
          isActive: true,
        ),
        AdminUser(
          id: 'u2',
          name: 'Jane Smith',
          email: 'jane@example.com',
          lastActive: DateTime.now().subtract(const Duration(hours: 2)),
          totalDecisions: 15,
          isActive: true,
        ),
        AdminUser(
          id: 'u3',
          name: 'Bob Wilson',
          email: 'bob@example.com',
          lastActive: DateTime.now().subtract(const Duration(days: 3)),
          totalDecisions: 8,
          isActive: false,
        ),
      ];
}
