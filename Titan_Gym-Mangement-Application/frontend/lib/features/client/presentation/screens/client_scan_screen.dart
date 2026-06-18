import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/client_scan_controller.dart';
import '../../domain/attendance_model.dart';
import 'qr_scanner_page.dart';

class ClientScanScreen extends StatefulWidget {
  final String token;
  final VoidCallback? onBack;
  const ClientScanScreen({super.key, required this.token, this.onBack});

  @override
  State<ClientScanScreen> createState() => _ClientScanScreenState();
}

class _ClientScanScreenState extends State<ClientScanScreen> {
  late ClientScanController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = ClientScanController();
    _ctrl.loadStatus(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Consumer<ClientScanController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final statusInfo = ctrl.statusInfo;

          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  }
                },
              ),
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QR Code Check-in',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Scan to check in',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Last check-in banner ──────────────────────────
                  if (ctrl.recentCheckins.isNotEmpty && !ctrl.isBlocked)
                    _buildLastCheckinBanner(ctrl.recentCheckins.first),

                  // ── Blocked banner ────────────────────────────────
                  if (ctrl.isBlocked)
                    _buildBlockedBanner(statusInfo['message']),

                  // ── QR Scanner box ────────────────────────────────
                  _buildScannerBox(ctrl, statusInfo),
                  const SizedBox(height: 16),

                  // ── Recent check-ins ──────────────────────────────
                  _buildHistory(ctrl.recentCheckins),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildLastCheckinBanner(AttendanceModel last) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Last Check-In',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                _formatTime(last.checkedIn),
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 32),
        ],
      ),
    );
  }

  Widget _buildBlockedBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerBox(
    ClientScanController ctrl,
    Map<String, dynamic> statusInfo,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Scan QR Code',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Point your camera at the gym's QR code",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // QR frame
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: ctrl.canCheckin
                  ? const Color(0xFFE8F5E9)
                  : ctrl.isBlocked
                  ? Colors.red.shade50
                  : const Color(0xFFF0F0FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ctrl.canCheckin
                    ? const Color(0xFF4CAF50)
                    : ctrl.isBlocked
                    ? Colors.red
                    : const Color(0xFF4F46E5),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 80,
                  color: ctrl.canCheckin
                      ? const Color(0xFF4CAF50)
                      : ctrl.isBlocked
                      ? Colors.red
                      : const Color(0xFF4F46E5),
                ),
                const SizedBox(height: 12),
                Text(
                  statusInfo['message'],
                  style: TextStyle(
                    color: statusInfo['color'],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (ctrl.canCheckin)
                  const Text(
                    'Position the QR code within the frame',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: (ctrl.canCheckin && !ctrl.isCheckingIn)
                  ? () async {
                      final scannedCode = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QrScannerPage(),
                        ),
                      );
                      if (scannedCode == null || !context.mounted) return;

                      final success = await ctrl.doCheckin(
                        widget.token,
                        scannedCode,
                      );
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Checked in successfully!'),
                            backgroundColor: Color(0xFF4CAF50),
                          ),
                        );
                      } else if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ctrl.errorMessage ?? 'Check-in failed',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  : null,
              icon: ctrl.isCheckingIn
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.qr_code, color: Colors.white),
              label: Text(
                ctrl.checkedInNow
                    ? 'Checked In!'
                    : ctrl.isCheckingIn
                    ? 'Checking in...'
                    : ctrl.canCheckin
                    ? 'Start Scanning'
                    : ctrl.status?.reason == 'already_checked_in'
                    ? 'Already Checked In Today'
                    : 'Cannot Check In',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ctrl.canCheckin
                    ? Colors.black
                    : ctrl.isBlocked
                    ? Colors.red
                    : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(List<AttendanceModel> checkins) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Check-ins',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Your attendance history',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (checkins.isEmpty)
            const Center(
              child: Text(
                'No check-ins yet',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...checkins.map((c) => _buildCheckinRow(c)),
        ],
      ),
    );
  }

  Widget _buildCheckinRow(AttendanceModel checkin) {
    final dt = checkin.checkedIn;
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final period = dt.hour < 12 ? 'AM' : 'PM';
    final time =
        '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period';
    final dateStr = '${_monthName(dt.month)} ${dt.day}, ${dt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF4CAF50),
                size: 22,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('check-in', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period - Today';
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }
}
