import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/api_constants.dart';
import '../../shared/cache_service.dart';
import '../../shared/connectivity_helper.dart';
import '../domain/retention_offer_model.dart';

class RetentionOfferRepository {
  final String token;
  final int gymId;

  RetentionOfferRepository({required this.token, required this.gymId});

  String get _dashboardKey => 'cache_retention_dashboard_$gymId';
  // previewMembers and sendOffer are not cached — write/dynamic operations

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// 1- Fetch The Dashboard
  Future<RetentionDashboard> fetchDashboard() async {
    final isOnline = await ConnectivityHelper.isOnline();

    if (!isOnline) {
      final cached = await CacheService.load(_dashboardKey);
      if (cached != null) return RetentionDashboard.fromJson(jsonDecode(cached));
      throw Exception('You are offline and no cached retention data available.');
    }

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/retention/dashboard/$gymId'),
      headers: _headers,
    );
    _checkStatus(res);
    await CacheService.save(_dashboardKey, res.body);
    return RetentionDashboard.fromJson(jsonDecode(res.body));
  }

  /// 2- Members Preview — no caching, result depends on request body
  Future<List<MemberPreview>> previewMembers({
    required String targetType,
    int? numberOfMembers,
  }) async {
    final isOnline = await ConnectivityHelper.isOnline();
    if (!isOnline) {
      throw Exception('You are offline. Please try again when you\'re connected.');
    }

    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/retention/preview/$gymId'),
      headers: _headers,
      body: jsonEncode({
        'target_type': targetType,
        'number_of_members': numberOfMembers,
      }),
    );
    _checkStatus(res);
    return (jsonDecode(res.body) as List)
        .map((e) => MemberPreview.fromJson(e))
        .toList();
  }

  /// 3- Create & Send Offer — no caching, invalidates dashboard
  Future<void> sendOffer({
    required String title,
    required String offerType,
    required String description,
    required String benefit,
    required String? validUntil,
    required String targetType,
    required List<int> selectedMemberIds,
  }) async {
    final isOnline = await ConnectivityHelper.isOnline();
    if (!isOnline) {
      throw Exception('You are offline. Please try again when you\'re connected.');
    }

    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/retention/send/$gymId'),
      headers: _headers,
      body: jsonEncode({
        'title':               title,
        'offer_type':          offerType,
        'description':         description,
        'benefit':             benefit,
        'valid_until':         validUntil,
        'target_type':         targetType,
        'selected_member_ids': selectedMemberIds,
      }),
    );
    _checkStatus(res);
    await CacheService.clear(_dashboardKey); // invalidate so dashboard reflects new offer
  }

  void _checkStatus(http.Response res) {
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }
  }
}