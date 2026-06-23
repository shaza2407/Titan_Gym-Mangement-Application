import 'package:flutter/material.dart';
import '../data/retention_offer_model.dart';
import '../data/retention_offer_repository.dart';

class RetentionOfferController extends ChangeNotifier{
  final RetentionOfferRepository _repo;

  RetentionOfferController({required String token, required int gymId})
    : _repo = RetentionOfferRepository(token: token, gymId: gymId);

  /// Dashboard State
  RetentionDashboard? dashboard;
  bool isLoadingDashboard = false;
  String? dashboardError;

  /// Preview State
  List<MemberPreview> previewMembers = [];
  bool isLoadingPreview = false;
  String? previewError;

  /// Send State
  bool isSending = false, sendSuccess = false;
  String? sendError;

  /// Form State
  String offerType = 'discount', targetType = 'highest_risk';
  int numberOfMembers  = 0;
  List<int> selectedMemberIds = [];
  Set<int>  manualSelected = {};

  Future<void> loadDashboard() async {
    isLoadingDashboard = true;
    dashboardError = null;
    try {
      dashboard = await _repo.fetchDashboard();
      numberOfMembers = dashboard!.totalActiveMembers;
    } catch (e) {
      dashboardError = e.toString();
    } finally {
      isLoadingDashboard = false;
      notifyListeners();
    }
  }

  Future<void> loadPreview() async {
    isLoadingPreview = true;
    previewError = null;
    manualSelected = {};
    notifyListeners();
    try {
      previewMembers = await _repo.previewMembers(
          targetType: targetType,
          numberOfMembers: targetType == 'manual_selection' ? null : numberOfMembers,);
    }catch (e) {
      previewError = e.toString();
    } finally {
      isLoadingPreview = false;
      notifyListeners();
    }
  }

  void toggleManualMember(int membershipId) {
    if(manualSelected.contains(membershipId)) {
      manualSelected.remove(membershipId);
    } else {
      manualSelected.add(membershipId);
    }
    notifyListeners();
  }

  void setOfferType(String value) {
    offerType = value;
    notifyListeners();
  }

  void setTargetType(String value) {
    targetType = value;
    manualSelected = {};
    notifyListeners();
  }

  void setNumberOfMembers(int value) {
    final max = dashboard?.totalActiveMembers ?? 999;
    if (value >= 1 && value <= max) {
        numberOfMembers = value;
        notifyListeners();
    }
  }


  Future<void> sendOffer({
    required String  title,
    required String  description,
    required String  benefit,
    required String? validUntil,
  }) async {
    isSending = true;
    sendError = null;
    sendSuccess = false;
    notifyListeners();

    final ids = targetType == 'manual_selection' ? manualSelected.toList() : previewMembers.map((m) => m.membershipId).toList();

    try {
      await _repo.sendOffer(
        title : title,
        offerType : offerType,
        description : description,
        benefit : benefit,
        validUntil : validUntil,
        targetType : targetType,
        selectedMemberIds: ids,
      );
      sendSuccess = true;
      await loadDashboard();   // refresh dashboard after sending
    } catch (e) {
      sendError = e.toString();
    } finally {
      isSending = false;
      notifyListeners();
    }

  }
}