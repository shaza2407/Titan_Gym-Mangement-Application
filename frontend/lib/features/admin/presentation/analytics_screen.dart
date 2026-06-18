import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/analytics_models.dart';
import '../data/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget{
  final String token;
  final int gymId;
  final void Function(int)? onTabChange;

  const AnalyticsScreen({
    super.key,
    required this.token,
    required this.gymId,
    this.onTabChange,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  static const _primary = Color(0xFF4F46E5);
  static const _green = Color(0xFF22C55E);
   static const _red = Colors.redAccent;
  late final AnalyticsService _service;

  AnalyticsSummary? _summary;
  List<MonthRevenue>? _revenueTrend;
  List<MonthMembers>? _memberTrend;
  List<MembershipTypeCount>? _membershipDist;
  List<DayPattern>? _weeklyPattern;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = AnalyticsService(token: widget.token, gymId: widget.gymId);
    _load();
  }

  Future<void> _load() async {
    setState(() {_loading = true; _error = null;});
    try {
      final results = await Future.wait([
        _service.fetchSummary(),
        _service.fetchRevenueTrend(),
        _service.fetchMembersTrend(),
        _service.fetchMembershipTypeDistribution(),
        _service.fetchWeeklyPattern(),
      ]);
      setState(() {
        _summary = results[0] as AnalyticsSummary;
        _revenueTrend = results[1] as List<MonthRevenue>;
        _memberTrend = results[2] as List<MonthMembers>;
        _membershipDist = results[3] as List<MembershipTypeCount>;
        _weeklyPattern = results[4] as List<DayPattern>;
        _loading = false;
      });
    }catch (e) {
      setState(() {_error = e.toString(); _loading = false;});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analytics Dashboard',
                style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Performance insights & metrics',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null ? _buildError()
          : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCards(),
                const SizedBox(height: 16),
                _buildRevenueTrendChart(),
                const SizedBox(height: 16),
                _buildMemberTrendChart(),
                const SizedBox(height: 16),
                _buildMembershipDistribution(),
                const SizedBox(height: 16),
                _buildWeeklyPatternChart(),
                const SizedBox(height: 16),
              ],
            ),
          ),

    );
  }


  /// 1- Summary Part
  Widget _buildSummaryCards() {
    final s = _summary!;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _summaryCard(
          icon: Icons.attach_money,
          iconBg: const Color(0xFFECFDF5),
          iconColor: _green,
          label: 'Total Revenue (${s.revenueMonth})',
          value: '\$${s.totalRevenue.toStringAsFixed(0)}',
          change: s.revenueChange,
          badgeSuffix: '%',
        ),
        _summaryCard(
          icon: Icons.people_outline,
          iconBg: const Color(0xFFEEF2FF),
          iconColor: _primary,
          label: 'Active Members',
          value: '${s.activeMembers}',
          change: s.newMembersThisMonth.toDouble(),
          badgeSuffix: ' this month',
          alwaysPositive: true,
        ),
        _summaryCard(
          icon: Icons.monitor_heart_outlined,
          iconBg: const Color(0xFFFAF5FF),
          iconColor: const Color(0xFFA855F7),
          label: 'Avg. Daily Attendance',
          value: '${s.avgDailyAttendance}',
          change: s.avgAttendanceChange,
          badgeSuffix: '%',
        ),
        _summaryCard(
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

  /// [change] drives both the icon and color.
  /// [alwaysPositive] - for counts like new members where negative isn't exist.
  Widget _summaryCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required double change,
    required String badgeSuffix,
    bool alwaysPositive = false,
  }) {
    final isPositive = change >= 0;
    final trendColor = alwaysPositive ? _green : (isPositive ? _green : _red);
    final trendIcon = isPositive ? Icons.trending_up : Icons.trending_down;
    final prefix = isPositive ? '+' : '';           // negative already has '-'
    final badge = '$prefix${change % 1 == 0 ? change.toInt() : change}$badgeSuffix';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const Spacer(),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(trendIcon, size: 12, color: trendColor),
              const SizedBox(width: 2),
              Flexible(
                child: Text(badge,
                    style: TextStyle(color: trendColor, fontSize: 10),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }


  /// 2- Revenue Trend
  Widget _buildRevenueTrendChart() {
    final data = _revenueTrend!;
    final maxY = data.map((e) => e.revenue).fold(0.0, (a, b) => a > b ? a : b);
    final spots = List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].revenue));
    return _card (
      title: 'Revenue Trend',
      subtitle: 'Monthly revenue (Last 7 months)',
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
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  if (v != v.roundToDouble()) return const SizedBox();
                  final i = v.toInt();
                  if(i < 0 || i >= data.length) return const SizedBox();
                  return Text(data[i].month, style: const TextStyle(fontSize: 10, color: Colors.grey));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (v, _) {
                  if (v >= 1000) return Text('${(v / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 9, color: Colors.grey));
                  return Text('${v.toInt()}', style: const TextStyle(fontSize: 9, color: Colors.grey));
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),

          gridData: FlGridData(
            drawHorizontalLine: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: Colors.black12, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
        )),
      )
    );
  }



  /// 3- Member Trend
  Widget _buildMemberTrendChart() {
    final data = _memberTrend!;
    final spots = List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].totalMembers.toDouble()));
    final maxY = data.map((e) => e.totalMembers.toDouble()).fold(0.0, (a, b) => a > b ? a : b);

    return _card(
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
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  if (v != v.roundToDouble()) return const SizedBox();
                  final i = v.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox();
                  return Text(data[i].month, style: const TextStyle(fontSize: 10, color: Colors.grey));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            drawHorizontalLine: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: Colors.black12, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
        )),
      ),
    );
  }

  /// 4- Membership distribution
  Widget _buildMembershipDistribution() {
    final data   = _membershipDist!;
    const colors = [Color(0xFF4F46E5), Color(0xFFA855F7), Color(0xFF22C55E)];
    return _card(
      title: 'Membership Distribution',
      subtitle: 'Members by subscription type',
      child: SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              child: PieChart(PieChartData(
                sections: List.generate(data.length, (i) => PieChartSectionData(
                  value: data[i].count.toDouble(),
                  color: colors[i % colors.length],
                  radius: 80,
                  title: '',
                )),
                centerSpaceRadius: 0,
                sectionsSpace: 2,
              )),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(data.length, (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text('${data[i].type}: ${data[i].count}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                ]),
              )),
            ),
          ],
        ),
      ),
    );
  }


  /// 4- Weekly Pattern
  Widget _buildWeeklyPatternChart() {
    final data = _weeklyPattern!;
    const morningColor = Color(0xFFFBBF24);
    const eveningColor = Color(0xFF3B82F6);
    final maxY = data.expand((d) => [d.morning.toDouble(), d.evening.toDouble()]).fold(0.0, (a, b) => a > b ? a : b);
    return _card(
      title: 'Weekly Attendance Pattern',
      subtitle: 'Morning vs Evening (last 7 days)',
      child: SizedBox(
        height: 220,
        child: BarChart(BarChartData(
          maxY: maxY * 1.2,
          barGroups: List.generate(data.length, (i) => BarChartGroupData(
            x: i,
            barsSpace: 3,
            barRods: [
              BarChartRodData(
                toY: data[i].morning.toDouble(),
                color: morningColor,
                width: 10,
                borderRadius: BorderRadius.circular(3),
              ),
              BarChartRodData(
                toY: data[i].evening.toDouble(),
                color: eveningColor,
                width: 10,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          )),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Text(
                  data[v.toInt()].day,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            drawHorizontalLine: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: Colors.black12, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
        )),
      ),
      legend: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendDot(morningColor, 'Morning'),
          const SizedBox(width: 12),
          _legendDot(eveningColor, 'Evening'),
        ],
      ),
    );
  }

  /// Helper functions
  Widget _card({
    required String title, subtitle,
    required Widget child,
    Widget? legend,
  }) {
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
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          child,
          if (legend != null) ...[const SizedBox(height: 10), legend],
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ],
  );

  Widget _buildError() => Center(
    child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
}