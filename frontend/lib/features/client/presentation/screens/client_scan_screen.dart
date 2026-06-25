// lib/features/client/presentation/screens/client_scan_screen.dart

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
              backgroundColor: Color(0xFFF3F4F6),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
              ),
            );
          }

          final statusInfo = ctrl.statusInfo;
          final reason = ctrl.status?.reason;
          final isSuspended = reason == 'suspended';
          final isExpired = reason == 'expired';

          Color accentColor = const Color(0xFF4F46E5); // Indigo default
          if (isSuspended) {
            accentColor = Colors.red;
          } else if (isExpired) {
            accentColor = const Color(0xFFF59E0B); // Amber
          } else if (ctrl.canCheckin) {
            accentColor = const Color(0xFF10B981); // Emerald green
          } else if (reason == 'already_checked_in') {
            accentColor = const Color(0xFF6366F1); // Light Indigo
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF3F4F6),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              leading: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: widget.onBack,
                    )
                  : null,
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QR Code Check-in',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Scan the gym QR to verify attendance',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
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

                  // ── Suspended banner (red) ────────────────────────
                  if (isSuspended)
                    _buildStatusBanner(
                      message:
                          statusInfo['message'] ??
                          'Your membership is suspended',
                      bgColor: const Color(0xFFFEF2F2),
                      borderColor: const Color(0xFFEF4444),
                      iconColor: Colors.red,
                      textColor: Colors.red,
                    ),

                  // ── Expired banner (yellow) ───────────────────────
                  if (isExpired)
                    _buildStatusBanner(
                      message:
                          statusInfo['message'] ??
                          'Your subscription has expired',
                      bgColor: const Color(0xFFFFFBEB),
                      borderColor: const Color(0xFFF59E0B),
                      iconColor: const Color(0xFFF59E0B),
                      textColor: const Color(0xFF92400E),
                    ),

                  // ── QR Scanner box ────────────────────────────────
                  _buildScannerBox(ctrl, statusInfo, accentColor),
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
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Last Check-In Time',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(last.checkedIn),
                style: const TextStyle(color: Color(0xFF4B5563), fontSize: 12),
              ),
            ],
          ),
          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
        ],
      ),
    );
  }

  Widget _buildStatusBanner({
    required String message,
    required Color bgColor,
    required Color borderColor,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: iconColor, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
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
    Color accentColor,
  ) {
    final reason = ctrl.status?.reason;
    final isSuspended = reason == 'suspended';
    final isExpired = reason == 'expired';

    final Color messageColor = isSuspended
        ? Colors.red
        : isExpired
        ? const Color(0xFF92400E)
        : Colors.black87;

    final String buttonLabel = ctrl.checkedInNow
        ? 'Check-In Complete!'
        : ctrl.isCheckingIn
        ? 'Verifying...'
        : ctrl.canCheckin
        ? 'Press to open Camera'
        : reason == 'already_checked_in'
        ? 'Checked In Today'
        : isSuspended
        ? 'Membership Suspended'
        : isExpired
        ? 'Subscription Expired'
        : 'Access Blocked';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Check-In Terminal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Press scan to check into the gym center",
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
          const SizedBox(height: 20),

          // QR frame
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.05),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner_outlined,
                  size: 72,
                  color: accentColor,
                ),
                const SizedBox(height: 16),
                Text(
                  statusInfo['message'] ?? 'Ready to scan',
                  style: TextStyle(
                    color: messageColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                if (ctrl.canCheckin)
                  const Text(
                    'Ensure camera detects the gym QR code',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Button
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
                      if (scannedCode == null || !mounted) return;

                      final success = await ctrl.doCheckin(
                        widget.token,
                        scannedCode,
                      );
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Checked in successfully!'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      } else if (!success && mounted) {
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
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.qr_code, color: Colors.white),
              label: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ctrl.canCheckin
                    ? const Color(0xFF4F46E5)
                    : isSuspended
                    ? Colors.red.shade300
                    : isExpired
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFD1D5DB),
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
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Log',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Your monthly check-in history',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (checkins.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'No check-ins logged yet',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                ),
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
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF9FAFB),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF10B981),
                size: 22,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Verified',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.bold,
              ),
            ),
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
