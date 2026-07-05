import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controller/analytics_controller.dart';
import '../../domain/analytics_models.dart';
import '../../../shared/logout_button.dart';

class AnalyticsScreen extends StatelessWidget {
  final String token;
  final int gymId;
  final AnalyticsController controller;
  final void Function(int)? onTabChange;

  const AnalyticsScreen({
    super.key,
    required this.token,
    required this.gymId,
    required this.controller,
    this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: const _AnalyticsView(),
    );
  }
}

// Private stateless view

class _AnalyticsView extends StatelessWidget {
  static const _primary = Color(0xFF4F46E5);

  const _AnalyticsView();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AnalyticsController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analytics Dashboard',
                style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text('Performance insights & metrics',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () => showLogoutDialog(context),
          ),
        ],
      ),
      body: ctrl.loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : ctrl.error != null
              ? _ErrorView(error: ctrl.error!, onRetry: () {})
              : RefreshIndicator(
                  onRefresh: () async {},
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _SummaryCards(summary: ctrl.summary!),
                      const SizedBox(height: 16),
                      _RevenueTrendChart(data: ctrl.revenueTrend!),
                      const SizedBox(height: 16),
                      _MemberTrendChart(data: ctrl.memberTrend!),
                      const SizedBox(height: 16),
                      _MembershipDistribution(data: ctrl.membershipDist!),
                      const SizedBox(height: 16),
                      _WeeklyPatternChart(data: ctrl.weeklyPattern!),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }
}

// Summary cards

class _SummaryCards extends StatelessWidget {
  static const _green   = Color(0xFF22C55E);
  static const _primary = Color(0xFF4F46E5);

  final AnalyticsSummary summary;
  const _SummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        _SummaryCard(
          icon: Icons.attach_money,
          iconBg: const Color(0xFFECFDF5),
          iconColor: _green,
          label: 'Total Revenue (${s.revenueMonth})',
          value: '\$${s.totalRevenue.toStringAsFixed(0)}',
          change: s.revenueChange,
          badgeSuffix: '%',
        ),
        _SummaryCard(
          icon: Icons.people_outline,
          iconBg: const Color(0xFFEEF2FF),
          iconColor: _primary,
          label: 'Active Members',
          value: '${s.activeMembers}',
          change: s.newMembersThisMonth.toDouble(),
          badgeSuffix: ' this month',
          alwaysPositive: true,
        ),
        _SummaryCard(
          icon: Icons.monitor_heart_outlined,
          iconBg: const Color(0xFFFAF5FF),
          iconColor: const Color(0xFFA855F7),
          label: 'Avg. Daily Attendance',
          value: '${s.avgDailyAttendance}',
          change: s.avgAttendanceChange,
          badgeSuffix: '%',
        ),
        _SummaryCard(
          icon: Icons.calendar_today_outlined,
          iconBg: const Color(0xFFFFF7ED),
          iconColor: const Color(0xFFF97316),
          label: 'Active Classes',
          value: '${s.activeClasses}',
          change: s.newClassesThisMonth.toDouble(),
          badgeSuffix: ' this month',
          alwaysPositive: true,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  static const _green = Color(0xFF22C55E);
  static const _red   = Colors.redAccent;

  final IconData icon;
  final Color    iconBg, iconColor;
  final String   label, value, badgeSuffix;
  final double   change;
  final bool     alwaysPositive;

  const _SummaryCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.change,
    required this.badgeSuffix,
    this.alwaysPositive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change >= 0;
    final trendColor = alwaysPositive ? _green : (isPositive ? _green : _red);
    final trendIcon  = isPositive ? Icons.trending_up : Icons.trending_down;
    final prefix     = isPositive ? '+' : '';
    final badge      = '$prefix${change % 1 == 0 ? change.toInt() : change}$badgeSuffix';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration:
                BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Row(children: [
            Icon(trendIcon, size: 12, color: trendColor),
            const SizedBox(width: 2),
            Flexible(
              child: Text(badge,
                  style: TextStyle(color: trendColor, fontSize: 10),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ],
      ),
    );
  }
}

// Revenue trend

class _RevenueTrendChart extends StatelessWidget {
  static const _primary = Color(0xFF4F46E5);
  final List<MonthRevenue> data;
  const _RevenueTrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY  = data.map((e) => e.revenue).fold(0.0, (a, b) => a > b ? a : b);
    final spots = List.generate(
        data.length, (i) => FlSpot(i.toDouble(), data[i].revenue));

    return _ChartCard(
      title: 'Revenue Trend',
      subtitle: 'Monthly revenue (Last 6 months)',
      child: SizedBox(
        height: 200,
        child: LineChart(LineChartData(
          maxY: maxY * 1.2,
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: _primary,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeColor: _primary,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: _primary.withValues(alpha: 0.08),
              ),
            ),
          ],
          titlesData: _titlesData(
            bottom: (v) {
              final i = v.toInt();
              if (i < 0 || i >= data.length) return const SizedBox();
              return Text(data[i].month,
                  style: const TextStyle(fontSize: 10, color: Colors.grey));
            },
            left: (v) {
              if (v >= 1000) {
                return Text('${(v / 1000).toStringAsFixed(0)}k',
                    style: const TextStyle(fontSize: 9, color: Colors.grey));
              }
              return Text('${v.toInt()}',
                  style: const TextStyle(fontSize: 9, color: Colors.grey));
            },
            leftReservedSize: 44,
          ),
          gridData: _gridData(),
          borderData: FlBorderData(show: false),
        )),
      ),
    );
  }
}

// Member trend

class _MemberTrendChart extends StatelessWidget {
  static const _primary = Color(0xFF4F46E5);
  final List<MonthMembers> data;
  const _MemberTrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final spots = List.generate(
        data.length,
        (i) => FlSpot(i.toDouble(), data[i].totalMembers.toDouble()));
    final maxY = data
        .map((e) => e.totalMembers.toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);

    return _ChartCard(
      title: 'Member Growth',
      subtitle: 'New members per month',
      child: SizedBox(
        height: 200,
        child: LineChart(LineChartData(
          maxY: maxY * 1.2,
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: _primary,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: _primary,
                ),
              ),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          titlesData: _titlesData(
            bottom: (v) {
              final i = v.toInt();
              if (i < 0 || i >= data.length) return const SizedBox();
              return Text(data[i].month,
                  style: const TextStyle(fontSize: 10, color: Colors.grey));
            },
            left: (v) => Text('${v.toInt()}',
                style: const TextStyle(fontSize: 9, color: Colors.grey)),
            leftReservedSize: 36,
          ),
          gridData: _gridData(),
          borderData: FlBorderData(show: false),
        )),
      ),
    );
  }
}

// Membership distribution

class _MembershipDistribution extends StatelessWidget {
  static const _colors = [
    Color(0xFF4F46E5),
    Color(0xFFA855F7),
    Color(0xFF22C55E),
  ];
  final List<MembershipTypeCount> data;
  const _MembershipDistribution({required this.data});

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: 'Membership Distribution',
      subtitle: 'Members by subscription type',
      child: SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              child: PieChart(PieChartData(
                sections: List.generate(
                  data.length,
                  (i) => PieChartSectionData(
                    value: data[i].count.toDouble(),
                    color: _colors[i % _colors.length],
                    radius: 80,
                    title: '',
                  ),
                ),
                centerSpaceRadius: 0,
                sectionsSpace: 2,
              )),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                data.length,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                          color: _colors[i % _colors.length],
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text('${data[i].type}: ${data[i].count}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87)),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Weekly pattern

class _WeeklyPatternChart extends StatelessWidget {
  static const _morning = Color(0xFFFBBF24);
  static const _evening = Color(0xFF3B82F6);

  final List<DayPattern> data;
  const _WeeklyPatternChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = data
        .expand((d) => [d.morning.toDouble(), d.evening.toDouble()])
        .fold(0.0, (a, b) => a > b ? a : b);

    return _ChartCard(
      title: 'Weekly Attendance Pattern',
      subtitle: 'Morning vs Evening (last 7 days)',
      legend: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          _LegendDot(color: _morning, label: 'Morning'),
          SizedBox(width: 12),
          _LegendDot(color: _evening, label: 'Evening'),
        ],
      ),
      child: SizedBox(
        height: 220,
        child: BarChart(BarChartData(
          maxY: maxY * 1.2,
          barGroups: List.generate(
            data.length,
            (i) => BarChartGroupData(
              x: i,
              barsSpace: 3,
              barRods: [
                BarChartRodData(
                  toY: data[i].morning.toDouble(),
                  color: _morning,
                  width: 10,
                  borderRadius: BorderRadius.circular(3),
                ),
                BarChartRodData(
                  toY: data[i].evening.toDouble(),
                  color: _evening,
                  width: 10,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
          titlesData: _titlesData(
            bottom: (v) => Text(data[v.toInt()].day,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
            left: (v) => Text('${v.toInt()}',
                style: const TextStyle(fontSize: 9, color: Colors.grey)),
            leftReservedSize: 32,
          ),
          gridData: _gridData(),
          borderData: FlBorderData(show: false),
        )),
      ),
    );
  }
}

// Shared chart helpers

FlGridData _gridData() => FlGridData(
      drawHorizontalLine: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) =>
          const FlLine(color: Colors.black12, strokeWidth: 0.5),
    );

FlTitlesData _titlesData({
  required Widget Function(double) bottom,
  required Widget Function(double) left,
  double leftReservedSize = 36,
}) =>
    FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (v, _) {
            if (v != v.roundToDouble()) return const SizedBox();
            return bottom(v);
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: leftReservedSize,
          getTitlesWidget: (v, _) => left(v),
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );

// Reusable card wrapper

class _ChartCard extends StatelessWidget {
  final String  title, subtitle;
  final Widget  child;
  final Widget? legend;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.legend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          child,
          if (legend != null) ...[const SizedBox(height: 10), legend!],
        ],
      ),
    );
  }
}

// Legend dot

class _LegendDot extends StatelessWidget {
  final Color  color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// Error view

class _ErrorView extends StatelessWidget {
  final String       error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}