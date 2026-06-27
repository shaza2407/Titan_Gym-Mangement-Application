// test/features/client/presentation/controllers/dashboard_controller_test.dart
//
// Run with:
//   flutter test test/features/client/presentation/controllers/dashboard_controller_test.dart
//
// Pure unit tests — no widget pumping needed, just controller state transitions.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/features/client/data/dashboard_repository.dart';
import 'package:frontend/features/client/domain/dashboard_model.dart';
import 'package:frontend/features/client/presentation/controllers/client_dashboard_controller.dart';

// ── Mock & fakes ─────────────────────────────────────────────────────────────

class MockDashboardRepository extends Mock implements DashboardRepository {}
class FakeDashboardStatsModel extends Fake implements DashboardStatsModel {}

// ── Factory helpers ───────────────────────────────────────────────────────────

const _kToken = 'test-token';

DashboardStatsModel _makeStats({
  String membershipStatus = 'active',
  int daysRemaining = 10,
  String gymName = 'Titan Gym',
}) =>
    DashboardStatsModel(
      totalVisits: 42,
      daysThisWeek: 3,
      currentStreak: 5,
      membershipStatus: membershipStatus,
      daysRemaining: daysRemaining,
      gymName: gymName,
    );

// ════════════════════════════════════════════════════════════════════════════
// TESTS
// ════════════════════════════════════════════════════════════════════════════

void main() {
  setUpAll(() => registerFallbackValue(FakeDashboardStatsModel()));

  late MockDashboardRepository repo;
  late ClientDashboardController ctrl;

  setUp(() {
    repo = MockDashboardRepository();
    ctrl = ClientDashboardController.withRepo(repo);
  });

  tearDown(() => ctrl.dispose());

  // ── Initial state ─────────────────────────────────────────────────────────

  group('Initial state', () {
    test('stats is null before any load', () {
      expect(ctrl.stats, isNull);
    });

    test('isLoading is false before any load', () {
      expect(ctrl.isLoading, false);
    });

    test('errorMessage is null before any load', () {
      expect(ctrl.errorMessage, isNull);
    });
  });

  // ── loadStats — success ───────────────────────────────────────────────────

  group('loadStats — success', () {
    test('isLoading is true during fetch, false after', () async {
      final completer = Future<DashboardStatsModel>.delayed(
        const Duration(milliseconds: 10),
        () => _makeStats(),
      );
      when(() => repo.getDashboardStats(any())).thenAnswer((_) => completer);

      final states = <bool>[];
      ctrl.addListener(() => states.add(ctrl.isLoading));

      await ctrl.loadStats(_kToken);

      // First notification: isLoading=true, last: isLoading=false
      expect(states.first, true);
      expect(states.last, false);
    });

    test('stats is populated after successful load', () async {
      final expected = _makeStats(gymName: 'Iron Paradise');
      when(() => repo.getDashboardStats(any())).thenAnswer((_) async => expected);

      await ctrl.loadStats(_kToken);

      expect(ctrl.stats, isNotNull);
      expect(ctrl.stats!.gymName, 'Iron Paradise');
      expect(ctrl.stats!.totalVisits, 42);
    });

    test('errorMessage is null after successful load', () async {
      when(() => repo.getDashboardStats(any()))
          .thenAnswer((_) async => _makeStats());

      await ctrl.loadStats(_kToken);

      expect(ctrl.errorMessage, isNull);
    });

    test('passes token to repository', () async {
      when(() => repo.getDashboardStats(any()))
          .thenAnswer((_) async => _makeStats());

      await ctrl.loadStats('my-special-token');

      verify(() => repo.getDashboardStats('my-special-token')).called(1);
    });

    test('notifyListeners called twice — once on start, once on complete',
        () async {
      when(() => repo.getDashboardStats(any()))
          .thenAnswer((_) async => _makeStats());

      int notifyCount = 0;
      ctrl.addListener(() => notifyCount++);

      await ctrl.loadStats(_kToken);

      expect(notifyCount, 2);
    });
  });

  // ── loadStats — failure ───────────────────────────────────────────────────

  group('loadStats — failure', () {
    test('sets errorMessage when repo throws', () async {
      when(() => repo.getDashboardStats(any()))
          .thenThrow(Exception('Network error'));

      await ctrl.loadStats(_kToken);

      expect(ctrl.errorMessage, isNotNull);
      expect(ctrl.errorMessage, contains('Network error'));
    });

    test('stats remains null after failure', () async {
      when(() => repo.getDashboardStats(any()))
          .thenThrow(Exception('Network error'));

      await ctrl.loadStats(_kToken);

      expect(ctrl.stats, isNull);
    });

    test('isLoading is false after failure', () async {
      when(() => repo.getDashboardStats(any()))
          .thenThrow(Exception('timeout'));

      await ctrl.loadStats(_kToken);

      expect(ctrl.isLoading, false);
    });

    test('second load clears previous errorMessage', () async {
      // First call fails
      when(() => repo.getDashboardStats(any()))
          .thenThrow(Exception('first failure'));
      await ctrl.loadStats(_kToken);
      expect(ctrl.errorMessage, isNotNull);

      // Second call succeeds
      when(() => repo.getDashboardStats(any()))
          .thenAnswer((_) async => _makeStats());
      await ctrl.loadStats(_kToken);

      expect(ctrl.errorMessage, isNull);
      expect(ctrl.stats, isNotNull);
    });

    test('second load overwrites previous stats on success after success',
        () async {
      when(() => repo.getDashboardStats(any()))
          .thenAnswer((_) async => _makeStats(gymName: 'Gym A'));
      await ctrl.loadStats(_kToken);
      expect(ctrl.stats!.gymName, 'Gym A');

      when(() => repo.getDashboardStats(any()))
          .thenAnswer((_) async => _makeStats(gymName: 'Gym B'));
      await ctrl.loadStats(_kToken);
      expect(ctrl.stats!.gymName, 'Gym B');
    });
  });

  // ── Subscription status helpers via stats ─────────────────────────────────

  group('stats subscription status after load', () {
    test('stats.isSuspended is true after loading suspended stats', () async {
      when(() => repo.getDashboardStats(any()))
          .thenAnswer((_) async => _makeStats(membershipStatus: 'suspended'));

      await ctrl.loadStats(_kToken);

      expect(ctrl.stats!.isSuspended, true);
      expect(ctrl.stats!.isActive, false);
    });

    test('stats.isExpired is true after loading expired stats', () async {
      when(() => repo.getDashboardStats(any()))
          .thenAnswer((_) async => _makeStats(daysRemaining: -1));

      await ctrl.loadStats(_kToken);

      expect(ctrl.stats!.isExpired, true);
      expect(ctrl.stats!.isActive, false);
    });

    test('stats.isActive is true after loading active stats', () async {
      when(() => repo.getDashboardStats(any()))
          .thenAnswer((_) async => _makeStats(
                membershipStatus: 'active',
                daysRemaining: 10,
              ));

      await ctrl.loadStats(_kToken);

      expect(ctrl.stats!.isActive, true);
    });
  });
}