import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/api_constants.dart';
import 'retention_offer_model.dart';

class RetentionOfferRepository {
  final String token;
  final int gymId;

  RetentionOfferRepository({required this.token, required this.gymId});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// 1- Fetch The Dashboard
  Future<RetentionDashboard> fetchDashboard() async {
    final url = '${ApiConstants.baseUrl}/retention/dashboard/$gymId';
    final res = await http.get(Uri.parse(url), headers: _headers);
    print("DEBUG dashboard: ${res.body}"); 
    _checkStatus(res);
    return RetentionDashboard.fromJson(jsonDecode(res.body));
  }

  /// 2- Members Preview
  Future<List<MemberPreview>> previewMembers({required String targetType, int? numberOfMembers}) async{
    final url = '${ApiConstants.baseUrl}/retention/preview/$gymId';
    final res = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({
          'target_type': targetType, 'number_of_members': numberOfMembers
        }),
    );
    _checkStatus(res);
    return (jsonDecode(res.body) as List).map((e) => MemberPreview.fromJson(e)).toList();
  }

  /// 3- Create & Send Offer
  Future<void> sendOffer({
    required String title,
    required String offerType,
    required String description,
    required String benefit,
    required String? validUntil,
    required String targetType,
    required List<int> selectedMemberIds,
  }) async {

    final url = '${ApiConstants.baseUrl}/retention/send/$gymId';


    // final b = jsonEncode({
    //     'title' : title,
    //     'offer_type' : offerType,
    //     'description' : description,
    //     'benefit' : benefit,
    //     'valid_until' : validUntil,
    //     'target_type' : targetType,
    //     'selected_member_ids': selectedMemberIds,
    //   });
    // print("DEBUG send body: $b");

    final res = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode({
        'title' : title,
        'offer_type' : offerType,
        'description' : description,
        'benefit' : benefit,
        'valid_until' : validUntil,
        'target_type' : targetType,
        'selected_member_ids': selectedMemberIds,
      }),
    );

    // print("DEBUG send response: ${res.statusCode} ${res.body}");
    _checkStatus(res);
  }


  void _checkStatus(http.Response res) {
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }
  }
}