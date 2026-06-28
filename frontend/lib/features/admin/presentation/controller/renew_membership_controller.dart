import 'package:flutter/material.dart';
import '../../data/renew_membership_repository.dart';
import '../../domain/renew_membership_model.dart';
import '../../../shared/connectivity_helper.dart';

class RenewMembershipController extends ChangeNotifier {
  final RenewMembershipRepository _repo = RenewMembershipRepository();

  bool isLoading = false;
  String? errorMessage;

  final monthsController = TextEditingController(text: '1');
  final priceController  = TextEditingController();
  String subscriptionType = 'monthly';

  String get subscriptionSummary {
    final count = int.tryParse(monthsController.text) ?? 1;
    if (subscriptionType == 'yearly') {
      return '$count year${count > 1 ? 's' : ''} subscription';
    }
    return '$count month${count > 1 ? 's' : ''} subscription';
  }

  void setSubscriptionType(String type) {
    subscriptionType = type;
    notifyListeners();
  }

  Future<bool> renew({
    required String token,
    required int gymId,
    required int memberId,
  }) async {
    final online = await ConnectivityHelper.isOnline();
    if(!online){
      errorMessage = 'You are offline. Please try again when you\'re connected.';
      notifyListeners();
      return false;
    }
    final count = int.tryParse(monthsController.text) ?? 1;
    final price = double.tryParse(priceController.text) ?? 0;

    if (price <= 0) {
      errorMessage = 'Please enter a valid price';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repo.renewMembership(
        token:    token,
        gymId:    gymId,
        memberId: memberId,
        request:  RenewMembershipRequest(
          subscriptionType: subscriptionType,
          durationCount:    count,
          price:            price,
        ),
      );
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
    monthsController.dispose();
    priceController.dispose();
    super.dispose();
  }
}