class RetentionDashboard {
  final int highRiskCount, midRiskCount, offersSent, totalActiveMembers;
  final String aiInsight;
  final List<OfferHistoryItem> offerHistory;

  RetentionDashboard({
    required this.highRiskCount,
    required this.midRiskCount,
    required this.offersSent,
    required this.totalActiveMembers,
    required this.aiInsight,
    required this.offerHistory,
  });

  factory RetentionDashboard.fromJson(Map<String, dynamic> json) {
    return RetentionDashboard(
      offersSent: json['offers_sent'] ?? 0,
      highRiskCount: json['high_risk_count'] ?? 0,
      midRiskCount: json['mid_risk_count'] ?? 0,
      totalActiveMembers: json['total_active_members'] ?? 0,
      aiInsight : json['ai_insight'],
      offerHistory : (json['offer_history'] as List)
          .map((e) => OfferHistoryItem.fromJson(e))
          .toList(),
    );
  }
}

class OfferHistoryItem {
  final int id;
  final int? membersCount;
  final String title, offerType, targetType, createdAt;

  OfferHistoryItem({
    required this.id,
    required this.title,
    required this.offerType,
    required this.targetType,
    required this.membersCount,
    required this.createdAt,
  });

  factory OfferHistoryItem.fromJson(Map<String, dynamic> json) {
    return OfferHistoryItem(
      id : json['id'],
      title : json['title'],
      offerType : json['offer_type'],
      targetType : json['target_type'],
      membersCount: json['number_of_members'] ?? 0,
      createdAt : json['created_at'],
    );
  }
}

class MemberPreview {
  final int    membershipId, clientId;
  final String name, email, churnRisk;

  MemberPreview({
    required this.membershipId,
    required this.clientId,
    required this.name,
    required this.email,
    required this.churnRisk,
  });

  factory MemberPreview.fromJson(Map<String, dynamic> json) {
    return MemberPreview(
      membershipId : json['membershipID'],
      clientId : json['clientID'],
      name : json['name'],
      email : json['email'],
      churnRisk : json['churn_risk'],
    );
  }
}

