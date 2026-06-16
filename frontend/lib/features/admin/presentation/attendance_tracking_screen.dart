import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:ui' as ui;
import '../data/attendance_analytics_models.dart';
import '../data/attendance_analytics_service.dart';
import '../data/gym_repository.dart';


class AttendanceTrackingScreen extends StatefulWidget{
  final String token;
  // final int gymId;
  final GymModel gym;

  const AttendanceTrackingScreen({
    super.key,
    required this.token,
    required this.gym,
  });

  @override
  State<AttendanceTrackingScreen> createState() => _AttendanceTrackingScreenState();
}

class _AttendanceTrackingScreenState extends State<AttendanceTrackingScreen> {
  static const _primary = Color(0xFF4F46E5);
  static const _green = Color(0xFF22C55E);

  late final AttendanceAnalyticsService _service;
  AttendanceStats? _stats;
  QRCodeInfo? _qrInfo;
  WeeklyAttendance? _weeklyAttendance;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = AttendanceAnalyticsService(token: widget.token, gymId: widget.gym.gymID);
    _load();
  }

  Future<void> _load() async {
    setState(() {_loading = true; _error = null;});
    try {
      final results = await Future.wait([
        _service.fetchStats(),
        _service.fetchQRCode(),
        _service.fetchWeeklyAttendance(),
      ]);
      setState(() {
        _stats = results[0] as AttendanceStats;
        _qrInfo = results[1] as QRCodeInfo;
        _weeklyAttendance = results[2] as WeeklyAttendance;
        _loading = false;
      });
    } catch (e) {
      setState(() {_loading = false; _error = e.toString();});
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
            Text('Attendance Tracking',
                style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('View attendance records and QR codes',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStatCards(),
                      const SizedBox(height: 16),
                      _buildQRSection(),
                      const SizedBox(height: 16),
                      _buildWeeklyOverview(),
                    ],
                  ),
                ),
    );
  }

  ////////////////////////////////////////////////////////////////////
  Widget _buildStatCards() {
    return Row(
      children: [
        _statCard(
          icon: Icons.trending_up,
          iconColor: _primary,
          label: "Today's Total",
          value: '${_stats!.totalToday}',
        ),
        const SizedBox(width: 10),
        _statCard(
          icon: Icons.calendar_today_outlined,
          iconColor: _green,
          label: 'Last 7 Days',
          value: '${_stats!.thisWeek}',
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  ////////////////////////////////////////////////////////////////////
  Widget _buildQRSection() {
    final qr = _qrInfo!;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gym QR Code',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('Members scan this to check in',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => _downloadQR(qr.qrIdentifier),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Download'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.black26),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Image.memory(
                  base64Decode(qr.qrIdentifier),
                  width: 180,
                  height: 180,
                ),
                const SizedBox(height: 10),
                const Text('Display this QR code at the gym entrance',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text('Gym ID: ${qr.qrIdentifier}',
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _downloadQR(String data) async{
    try{
      // 1. render the QR code to an image in memory
      final qrPainter = QrPainter(
        data: data,
        version: QrVersions.auto,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.white),
        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.white),
      );
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = 300.0;

      /// 2. fill background with your primary color
      canvas.drawRect(
          Rect.fromLTWH(0, 0, size, size),
          Paint()..color = const Color(0xFF4F46E5),
      );
      qrPainter.paint(canvas, const Size(size, size));

      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      /// 3. save to gallery
      final result = await ImageGallerySaver.saveImage(bytes, name: 'gym_qr_$data');
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['isSuccess'] ? 'QR code saved to gallery' : 'Failed to save')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }


  ////////////////////////////////////////////////////////////////////
  Widget _buildWeeklyOverview() {
    final days = _weeklyAttendance!.days;
    final maxCount = days.map((d) => d.count).fold(0, (a, b) => a > b ? a : b);

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
          const Text("This Week's Overview", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          const Text('Daily attendance count', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12)),
          const SizedBox(height: 16),
          ...days.map((d) => _weeklyBar(d, maxCount)),
        ],
      )
    );
  }

  Widget _weeklyBar(DayAttendance d, int maxCount) {
    final fraction = maxCount > 0 ? d.count / maxCount : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(d.day, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(
            child: Stack(
              children: [
                // track
                Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                // fill
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.05, 1.0),
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 10),
                    child: Text('${d.count}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center,),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _load, child: Text('Retry')),
        ],
      ),
    );
  }
}













