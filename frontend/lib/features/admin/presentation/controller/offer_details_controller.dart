import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';
import '../../domain/offer_details_model.dart';

class OfferDetailsController extends ChangeNotifier {
  final AdminRepository _repo = AdminRepository();

  final int gymId;
  final int offerId;
  final String token;

  // ── State ─────────────────────────────────────────────────────────────────
  OfferDetailsModel? offer;
  bool isLoading = true;
  String? errorMessage;

  OfferDetailsController({
    required this.gymId,
    required this.offerId,
    required this.token,
  }) {
    load();
  }

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> load() async {
    isLoading    = true;
    errorMessage = null;
    notifyListeners();

    try {
      final raw = await _repo.getOfferDetails(gymId, offerId, token);
      offer = OfferDetailsModel.fromMap(raw);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Formatters ────────────────────────────────────────────────────────────
  String formatDate(String? iso) {
    if (iso == null) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '-';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String formatOfferType(String type) {
    switch (type) {
      case 'discount':           return 'Discount';
      case 'supplements':        return 'Supplements';
      case 'free_sessions':      return 'Free Sessions';
      case 'membership_upgrade': return 'Membership Upgrade';
      default:                   return type.isEmpty ? '-' : type;
    }
  }

  String formatTargetType(String type) {
    switch (type) {
      case 'highest_risk':     return 'Highest Risk';
      case 'lowest_risk':      return 'Lowest Risk';
      case 'all_members':      return 'All Members';
      case 'manual_selection': return 'Manual Selection';
      default:                 return type.isEmpty ? '-' : type;
    }
  }

  Color riskColor(String riskLevel) {
    final lower = riskLevel.toLowerCase();
    if (lower.contains('high')) return const Color(0xFFF44336); // red
    if (lower.contains('mid'))  return const Color(0xFFFF9800); // orange
    return const Color(0xFF4CAF50);                              // green
  }
}