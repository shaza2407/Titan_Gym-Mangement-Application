// test/features/client/domain/dashboard_model_test.dart
//
// Run with:
//   flutter test test/features/client/domain/dashboard_model_test.dart
//
// Pure unit tests — no Flutter, no mocks, no HTTP. Just model logic.

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/client/domain/dashboard_model.dart';

// ── Factory helper ────────────────────────────────────────────────────────────

DashboardStatsModel _make({
  int? daysRemaining = 10,
  String? membershipStatus = 'active',
  int totalVisits = 0,
  int daysThisWeek = 0,
  int currentStreak = 0,
  String? subscription,
  String? subscriptionEnd,
  String? gymName,
}) =>
    DashboardStatsModel(
      totalVisits: totalVisits,
      daysThisWeek: daysThisWeek,
      currentStreak: currentStreak,
      subscription: subscription,
      subscriptionEnd: subscriptionEnd,
      daysRemaining: daysRemaining,
      membershipStatus: membershipStatus,
      gymName: gymName,
    );

// ════════════════════════════════════════════════════════════════════════════
// TESTS
// ════════════════════════════════════════════════════════════════════════════

void main() {
  // ── isExpired ─────────────────────────────────────────────────────────────

  group('isExpired', () {
    test('true when daysRemaining is negative', () {
      expect(_make(daysRemaining: -1).isExpired, true);
      expect(_make(daysRemaining: -100).isExpired, true);
    });

    test('false when daysRemaining is zero — boundary: zero means today, not expired', () {
      expect(_make(daysRemaining: 0).isExpired, false);
    });

    test('false when daysRemaining is positive', () {
      expect(_make(daysRemaining: 1).isExpired, false);
      expect(_make(daysRemaining: 30).isExpired, false);
    });

    test('false when daysRemaining is null — defaults to 0, not expired', () {
      expect(_make(daysRemaining: null).isExpired, false);
    });
  });

  // ── isSuspended ───────────────────────────────────────────────────────────

  group('isSuspended', () {
    test('true only when membershipStatus is exactly "suspended"', () {
      expect(_make(membershipStatus: 'suspended').isSuspended, true);
    });

    test('false for "active"', () {
      expect(_make(membershipStatus: 'active').isSuspended, false);
    });

    test('false for null membershipStatus', () {
      expect(_make(membershipStatus: null).isSuspended, false);
    });

    test('case-sensitive — "Suspended" is not suspended', () {
      expect(_make(membershipStatus: 'Suspended').isSuspended, false);
      expect(_make(membershipStatus: 'SUSPENDED').isSuspended, false);
    });

    test('false for empty string', () {
      expect(_make(membershipStatus: '').isSuspended, false);
    });
  });

  // ── isActive ──────────────────────────────────────────────────────────────

  group('isActive', () {
    test('true when not expired and not suspended', () {
      expect(_make(membershipStatus: 'active', daysRemaining: 10).isActive, true);
    });

    test('false when suspended even if days remaining', () {
      expect(_make(membershipStatus: 'suspended', daysRemaining: 10).isActive, false);
    });

    test('false when expired even if status is active', () {
      expect(_make(membershipStatus: 'active', daysRemaining: -1).isActive, false);
    });

    test('false when both suspended and expired', () {
      expect(_make(membershipStatus: 'suspended', daysRemaining: -1).isActive, false);
    });

    test('true at boundary — daysRemaining == 0 is still active', () {
      expect(_make(membershipStatus: 'active', daysRemaining: 0).isActive, true);
    });
  });

  // ── fromJson ──────────────────────────────────────────────────────────────

  group('fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'total_visits': 42,
        'days_this_week': 3,
        'current_streak': 7,
        'subscription': 'Monthly',
        'subscription_end': '2025-12-31',
        'days_remaining': 14,
        'membership_status': 'active',
        'gym_name': 'Titan Gym',
      };

      final model = DashboardStatsModel.fromJson(json);

      expect(model.totalVisits, 42);
      expect(model.daysThisWeek, 3);
      expect(model.currentStreak, 7);
      expect(model.subscription, 'Monthly');
      expect(model.subscriptionEnd, '2025-12-31');
      expect(model.daysRemaining, 14);
      expect(model.membershipStatus, 'active');
      expect(model.gymName, 'Titan Gym');
    });

    test('handles null optional fields', () {
      final json = {
        'total_visits': 0,
        'days_this_week': 0,
        'current_streak': 0,
        'subscription': null,
        'subscription_end': null,
        'days_remaining': null,
        'membership_status': null,
        'gym_name': null,
      };

      final model = DashboardStatsModel.fromJson(json);

      expect(model.subscription, isNull);
      expect(model.subscriptionEnd, isNull);
      expect(model.daysRemaining, isNull);
      expect(model.membershipStatus, isNull);
      expect(model.gymName, isNull);
    });

    test('suspended status parsed from JSON sets isSuspended true', () {
      final json = {
        'total_visits': 0,
        'days_this_week': 0,
        'current_streak': 0,
        'membership_status': 'suspended',
        'days_remaining': 5,
      };
      final model = DashboardStatsModel.fromJson(json);
      expect(model.isSuspended, true);
      expect(model.isActive, false);
    });

    test('negative daysRemaining from JSON sets isExpired true', () {
      final json = {
        'total_visits': 0,
        'days_this_week': 0,
        'current_streak': 0,
        'membership_status': 'active',
        'days_remaining': -5,
      };
      final model = DashboardStatsModel.fromJson(json);
      expect(model.isExpired, true);
      expect(model.isActive, false);
    });
  });
}