// test/features/client/presentation/screens/client_dashboard_test.dart
//
// Run with:
//   flutter test test/features/client/presentation/screens/client_dashboard_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/client/presentation/screens/subscription_blocked_screen.dart';
import 'package:frontend/features/shared/notifications/notification_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/features/client/presentation/controllers/client_dashboard_controller.dart';
import 'package:frontend/features/client/presentation/controllers/client_achievement_controller.dart';
import 'package:frontend/features/client/domain/dashboard_model.dart';
import 'package:frontend/features/shared/notifications/notification_badge_controller.dart';
import 'package:frontend/features/client/data/dashboard_repository.dart';
import 'package:frontend/features/client/data/client_achievement_repository.dart';
import 'package:frontend/features/shared/notifications/notification_badge_repository.dart';
import 'package:frontend/features/client/presentation/screens/client_dashboard_screen.dart';

// ── Mocks ───────────────────────────────────────────────────────────────────

class MockDashboardRepository extends Mock implements DashboardRepository {}

class MockAchievementRepository extends Mock
    implements ClientAchievementRepository {}

class MockNotificationBadgeRepository extends Mock
    implements NotificationBadgeRepository {}

// ── Fake fallback values for mocktail ───────────────────────────────────────

class FakeDashboardStatsModel extends Fake implements DashboardStatsModel {}

class FakeNotificationBadgeModel extends Fake
    implements NotificationBadgeModel {}

// ── Fake token: payload {"sub":"1"} → base64url = eyJzdWIiOiIxIn0 ─────────

const _kFakeToken =
    'eyJhbGciOiJIUzI1NiJ9'
    '.eyJzdWIiOiIxIn0'
    '.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

// ── Model factory ────────────────────────────────────────────────────────────

DashboardStatsModel _makeStats({
  String membershipStatus = 'active',
  int daysRemaining = 10,
  String gymName = 'Titan Gym',
  String subscription = 'Monthly',
  String subscriptionEnd = '2025-12-31',
  int totalVisits = 42,
  int daysThisWeek = 3,
  int currentStreak = 5,
}) => DashboardStatsModel(
  totalVisits: totalVisits,
  daysThisWeek: daysThisWeek,
  currentStreak: currentStreak,
  subscription: subscription,
  subscriptionEnd: subscriptionEnd,
  daysRemaining: daysRemaining,
  membershipStatus: membershipStatus,
  gymName: gymName,
);

// ── Controller factories ─────────────────────────────────────────────────────

/// Dashboard controller whose repo immediately returns [stats].
ClientDashboardController _dashCtrlWith(
  MockDashboardRepository repo,
  DashboardStatsModel stats,
) {
  when(() => repo.getDashboardStats(any())).thenAnswer((_) async => stats);
  return ClientDashboardController.withRepo(repo);
}

/// Dashboard controller whose repo never resolves (stays loading).
ClientDashboardController _dashCtrlLoading(MockDashboardRepository repo) {
  when(
    () => repo.getDashboardStats(any()),
  ).thenAnswer((_) => Future.delayed(const Duration(hours: 1)));
  return ClientDashboardController.withRepo(repo);
}

/// Achievement controller that returns an empty list.
ClientAchievementController _idleAchCtrl(MockAchievementRepository repo) {
  when(() => repo.getAchievements(any())).thenAnswer((_) async => []);
  return ClientAchievementController.withRepo(repo);
}

/// Badge controller pre-seeded with [hasUnread].
NotificationBadgeController _badgeCtrlWith(
  MockNotificationBadgeRepository repo, {
  required bool hasUnread,
}) {
  when(
    () => repo.fetchBadge(any(), any()),
  ).thenAnswer((_) async => NotificationBadgeModel(hasUnread: hasUnread));
  return NotificationBadgeController.withRepo(repo);
}

// ── KEY INSIGHT: pump the screen with injected controllers ───────────────────
//
// ClientDashboardScreen.initState() always does:
//   _ctrl = ClientDashboardController()   ← creates its OWN controller
//
// So wrapping it in MultiProvider with our mock controllers does nothing —
// the screen ignores them and uses its own repo-backed instances.
//
// The solution: pass the controllers as constructor parameters so initState
// uses them instead of creating new ones. This requires a small addition to
// ClientDashboardScreen (see README below).
//
// Add these optional params to ClientDashboardScreen:
//
//   final ClientDashboardController? testDashCtrl;
//   final ClientAchievementController? testAchCtrl;
//   final NotificationBadgeController? testBadgeCtrl;
//
// And in initState:
//   _ctrl = widget.testDashCtrl ?? ClientDashboardController();
//   if (widget.testDashCtrl == null) _ctrl.loadStats(widget.token);
//   ... same for ach and badge ...
//
// See the bottom of this file for the exact snippet to add.

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required ClientDashboardController dashCtrl,
  required ClientAchievementController achCtrl,
  required NotificationBadgeController badgeCtrl,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ClientDashboardScreen(
        token: _kFakeToken,
        testDashCtrl: dashCtrl,
        testAchCtrl: achCtrl,
        testBadgeCtrl: badgeCtrl,
      ),
    ),
  );
  await tester.pump(); // settle first frame
}

// ════════════════════════════════════════════════════════════════════════════
// TESTS
// ════════════════════════════════════════════════════════════════════════════

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDashboardStatsModel());
    registerFallbackValue(FakeNotificationBadgeModel());
  });

  late MockDashboardRepository dashRepo;
  late MockAchievementRepository achRepo;
  late MockNotificationBadgeRepository badgeRepo;

  setUp(() {
    dashRepo = MockDashboardRepository();
    achRepo = MockAchievementRepository();
    badgeRepo = MockNotificationBadgeRepository();
  });

  // ── Group 1: Loading state ────────────────────────────────────────────────

  group('Loading state', () {
    testWidgets('shows spinner while isLoading is true', (tester) async {
      final dashCtrl = _dashCtrlLoading(dashRepo);

      await _pumpDashboard(
        tester,
        dashCtrl: dashCtrl,
        achCtrl: _idleAchCtrl(achRepo),
        badgeCtrl: _badgeCtrlWith(badgeRepo, hasUnread: false),
      );

      // Manually force loading state — avoids async timing issues
      dashCtrl.isLoading = true;
      dashCtrl.notifyListeners();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  // ── Group 2: Subscription card ────────────────────────────────────────────

  group('Subscription card', () {
    testWidgets('active membership — shows green Active badge', (tester) async {
      final stats = _makeStats(membershipStatus: 'active', daysRemaining: 10);
      final dashCtrl = _dashCtrlWith(dashRepo, stats);
      await dashCtrl.loadStats(_kFakeToken); // pre-seed before pump

      await _pumpDashboard(
        tester,
        dashCtrl: dashCtrl,
        achCtrl: _idleAchCtrl(achRepo),
        badgeCtrl: _badgeCtrlWith(badgeRepo, hasUnread: false),
      );

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Active Subscription'), findsOneWidget);
    });

    testWidgets('suspended membership — shows Suspended badge', (tester) async {
      final stats = _makeStats(membershipStatus: 'suspended', daysRemaining: 5);
      final dashCtrl = _dashCtrlWith(dashRepo, stats);
      await dashCtrl.loadStats(_kFakeToken);

      await _pumpDashboard(
        tester,
        dashCtrl: dashCtrl,
        achCtrl: _idleAchCtrl(achRepo),
        badgeCtrl: _badgeCtrlWith(badgeRepo, hasUnread: false),
      );

      expect(find.text('Suspended'), findsOneWidget);
      expect(find.text('Subscription Suspended'), findsOneWidget);
      expect(
        find.text('Your access is suspended — contact your gym'),
        findsOneWidget,
      );
    });

    testWidgets('expired membership — shows Expired badge', (tester) async {
      final stats = _makeStats(
        membershipStatus: 'active',
        daysRemaining: -3,
        subscriptionEnd: '2024-01-01',
      );
      final dashCtrl = _dashCtrlWith(dashRepo, stats);
      await dashCtrl.loadStats(_kFakeToken);

      await _pumpDashboard(
        tester,
        dashCtrl: dashCtrl,
        achCtrl: _idleAchCtrl(achRepo),
        badgeCtrl: _badgeCtrlWith(badgeRepo, hasUnread: false),
      );

      expect(find.text('Expired'), findsOneWidget);
      expect(find.text('Subscription Expired'), findsOneWidget);
      expect(find.textContaining('Expired on 2024-01-01'), findsOneWidget);
    });
  });

  // ── Group 3: Stats cards ──────────────────────────────────────────────────

  group('Stats cards', () {
    testWidgets('renders correct values for days, streak, visits', (
      tester,
    ) async {
      final stats = _makeStats(
        daysThisWeek: 4,
        currentStreak: 7,
        totalVisits: 99,
      );
      final dashCtrl = _dashCtrlWith(dashRepo, stats);
      await dashCtrl.loadStats(_kFakeToken);

      await _pumpDashboard(
        tester,
        dashCtrl: dashCtrl,
        achCtrl: _idleAchCtrl(achRepo),
        badgeCtrl: _badgeCtrlWith(badgeRepo, hasUnread: false),
      );

      expect(find.text('4/7'), findsOneWidget);
      expect(find.text('7 days'), findsOneWidget);
      expect(find.text('99'), findsOneWidget);
    });

    testWidgets('shows dash placeholders while stats are null', (tester) async {
      final dashCtrl = _dashCtrlLoading(dashRepo); // stats stays null

      await _pumpDashboard(
        tester,
        dashCtrl: dashCtrl,
        achCtrl: _idleAchCtrl(achRepo),
        badgeCtrl: _badgeCtrlWith(badgeRepo, hasUnread: false),
      );

      // All three stat cards show '-'
      expect(find.text('-'), findsNWidgets(3));
    });
  });

  // ── Group 4: Tab gating ───────────────────────────────────────────────────

  group('Tab gating — suspended client', () {
    Future<ClientDashboardController> pumpSuspended(WidgetTester tester) async {
      final stats = _makeStats(membershipStatus: 'suspended', daysRemaining: 5);
      final dashCtrl = _dashCtrlWith(dashRepo, stats);
      await dashCtrl.loadStats(_kFakeToken);
      await _pumpDashboard(
        tester,
        dashCtrl: dashCtrl,
        achCtrl: _idleAchCtrl(achRepo),
        badgeCtrl: _badgeCtrlWith(badgeRepo, hasUnread: false),
      );
      return dashCtrl;
    }

    testWidgets('tapping Schedule tab shows SubscriptionBlockedScreen', (
      tester,
    ) async {
      await pumpSuspended(tester);
      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(SubscriptionBlockedScreen), findsOneWidget);
    });

    testWidgets('Scan tab is NOT blocked for suspended client', (tester) async {
      await pumpSuspended(tester);
      await tester.tap(find.byIcon(Icons.qr_code_scanner));
      await tester.pumpAndSettle();
      // Scan has no gating — SubscriptionBlockedScreen should NOT appear
      expect(find.byType(SubscriptionBlockedScreen), findsNothing);
    });

    testWidgets('Profile tab is NOT blocked for suspended client', (
      tester,
    ) async {
      await pumpSuspended(tester);
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(find.byType(SubscriptionBlockedScreen), findsNothing);
    });
  });

  group('Tab gating — expired client', () {
    testWidgets('tapping Schedule tab shows SubscriptionBlockedScreen', (
      tester,
    ) async {
      final stats = _makeStats(membershipStatus: 'active', daysRemaining: -1);
      final dashCtrl = _dashCtrlWith(dashRepo, stats);
      await dashCtrl.loadStats(_kFakeToken);
      await _pumpDashboard(
        tester,
        dashCtrl: dashCtrl,
        achCtrl: _idleAchCtrl(achRepo),
        badgeCtrl: _badgeCtrlWith(badgeRepo, hasUnread: false),
      );

      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(SubscriptionBlockedScreen), findsOneWidget);
    });
  });

  // ── Group 5: Notification badge ───────────────────────────────────────────

  group('Notification badge', () {
    /// Finds the 9×9 red circle dot widget in the tree.
    Iterable<Container> _redDots(WidgetTester tester) =>
        tester.widgetList<Container>(find.byType(Container)).where((c) {
          final d = c.decoration;
          return d is BoxDecoration &&
              d.color == Colors.red &&
              d.shape == BoxShape.circle;
        });

    testWidgets('red dot visible when hasUnread is true', (tester) async {
      final stats = _makeStats();
      final dashCtrl = _dashCtrlWith(dashRepo, stats);
      await dashCtrl.loadStats(_kFakeToken);

      final badgeCtrl = _badgeCtrlWith(badgeRepo, hasUnread: true);
      await badgeCtrl.load(_kFakeToken, 1);

      await _pumpDashboard(
        tester,
        dashCtrl: dashCtrl,
        achCtrl: _idleAchCtrl(achRepo),
        badgeCtrl: badgeCtrl,
      );

      expect(_redDots(tester), isNotEmpty);
    });

    testWidgets('red dot hidden when hasUnread is false', (tester) async {
      final stats = _makeStats();
      final dashCtrl = _dashCtrlWith(dashRepo, stats);
      await dashCtrl.loadStats(_kFakeToken);

      final badgeCtrl = _badgeCtrlWith(badgeRepo, hasUnread: false);
      await badgeCtrl.load(_kFakeToken, 1);

      await _pumpDashboard(
        tester,
        dashCtrl: dashCtrl,
        achCtrl: _idleAchCtrl(achRepo),
        badgeCtrl: badgeCtrl,
      );

      expect(_redDots(tester), isEmpty);
    });

    testWidgets('red dot disappears after clear()', (tester) async {
      final stats = _makeStats();
      final dashCtrl = _dashCtrlWith(dashRepo, stats);
      await dashCtrl.loadStats(_kFakeToken);

      final badgeCtrl = _badgeCtrlWith(badgeRepo, hasUnread: true);
      await badgeCtrl.load(_kFakeToken, 1);

      await _pumpDashboard(
        tester,
        dashCtrl: dashCtrl,
        achCtrl: _idleAchCtrl(achRepo),
        badgeCtrl: badgeCtrl,
      );

      expect(_redDots(tester), isNotEmpty);

      badgeCtrl.clear();
      await tester.pump();

      expect(_redDots(tester), isEmpty);
    });
  });

  // ── Group 6: AppBar ───────────────────────────────────────────────────────

  group('AppBar', () {
    testWidgets('shows gym name in subtitle once stats load', (tester) async {
      final stats = _makeStats(gymName: 'Iron Paradise');
      final dashCtrl = _dashCtrlWith(dashRepo, stats);
      await dashCtrl.loadStats(_kFakeToken);

      await _pumpDashboard(
        tester,
        dashCtrl: dashCtrl,
        achCtrl: _idleAchCtrl(achRepo),
        badgeCtrl: _badgeCtrlWith(badgeRepo, hasUnread: false),
      );

      expect(find.text('Iron Paradise'), findsOneWidget);
    });

    testWidgets('shows "Welcome back!" before stats load', (tester) async {
      final dashCtrl = _dashCtrlLoading(dashRepo); // stats stays null

      await _pumpDashboard(
        tester,
        dashCtrl: dashCtrl,
        achCtrl: _idleAchCtrl(achRepo),
        badgeCtrl: _badgeCtrlWith(badgeRepo, hasUnread: false),
      );

      expect(find.text('Welcome back!'), findsOneWidget);
    });
  });
}

// ════════════════════════════════════════════════════════════════════════════
// REQUIRED CHANGE TO ClientDashboardScreen
// ════════════════════════════════════════════════════════════════════════════
//
// Add 3 optional test parameters to the widget and update initState.
// Production behaviour is 100% unchanged — the params default to null.
//
// In client_dashboard_screen.dart:
//
// class ClientDashboardScreen extends StatefulWidget {
//   final String token;
//   final ClientDashboardController? testDashCtrl;   // ← add
//   final ClientAchievementController? testAchCtrl;  // ← add
//   final NotificationBadgeController? testBadgeCtrl;// ← add
//
//   const ClientDashboardScreen({
//     super.key,
//     required this.token,
//     this.testDashCtrl,   // ← add
//     this.testAchCtrl,    // ← add
//     this.testBadgeCtrl,  // ← add
//   });
//   ...
// }
//
// In initState, replace the 6 lines that create + load controllers with:
//
//   _ctrl = widget.testDashCtrl ?? ClientDashboardController();
//   if (widget.testDashCtrl == null) _ctrl.loadStats(widget.token);
//
//   _achievementCtrl = widget.testAchCtrl ?? ClientAchievementController();
//   if (widget.testAchCtrl == null) _achievementCtrl.loadAchievements(widget.token);
//
//   _badgeCtrl = widget.testBadgeCtrl ?? NotificationBadgeController();
//   if (widget.testBadgeCtrl == null)
//     _badgeCtrl.load(widget.token, getUserIdFromToken(widget.token));
