import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';
import '../../domain/gym_model.dart';

class InviteMemberController extends ChangeNotifier {
  final AdminRepository _repo = AdminRepository();

  final GymModel gym;
  final String token;

  // ── Form controllers ──────────────────────────────────────────────────────
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController monthsCtrl = TextEditingController(text: '1');
  final TextEditingController priceCtrl = TextEditingController();

  // ── State ─────────────────────────────────────────────────────────────────
  String inviteAs = 'client';
  String subscriptionType = 'monthly';
  bool isLoading = false;
  String? errorMessage;
  String? priceError;

  InviteMemberController({required this.gym, required this.token});

  bool get isCoach => inviteAs == 'coach';

  String get subscriptionSummary {
    final months = int.tryParse(monthsCtrl.text) ?? 1;
    if (subscriptionType == 'yearly') {
      return '$months year${months > 1 ? 's' : ''} subscription';
    }
    return '$months month${months > 1 ? 's' : ''} subscription';
  }

  // ── Setters ───────────────────────────────────────────────────────────────
  void setInviteAs(String value) {
    inviteAs = value;
    notifyListeners();
  }

  void setSubscriptionType(String value) {
    subscriptionType = value;
    notifyListeners();
  }

  void notifyMonthsChanged() => notifyListeners();

  // ── Validation ────────────────────────────────────────────────────────────
  bool _validate() {
    errorMessage = null;
    priceError = null;

    if (emailCtrl.text.trim().isEmpty) {
      errorMessage = 'Please enter an email address';
      notifyListeners();
      return false;
    }

    if (!isCoach) {
      final price = int.tryParse(priceCtrl.text);
      if (price == null || price <= 0) {
        priceError = 'Please enter a valid subscription price';
        notifyListeners();
        return false;
      }
    }

    return true;
  }

  // ── Send Invitation ───────────────────────────────────────────────────────
  Future<bool> send() async {
    if (!_validate()) return false;

    isLoading = true;
    notifyListeners();

    try {
      if (isCoach) {
        await _repo.inviteCoach(
          gym.gymID,
          emailCtrl.text.trim(),
          token,
        );
      } else {
        await _repo.inviteClient(
          gym.gymID,
          emailCtrl.text.trim(),
          token,
          subscriptionType: subscriptionType,
          subscriptionMonths: int.tryParse(monthsCtrl.text) ?? 1,
          subscriptionPrice: int.tryParse(priceCtrl.text) ?? 0,
        );
      }
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    monthsCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }
}