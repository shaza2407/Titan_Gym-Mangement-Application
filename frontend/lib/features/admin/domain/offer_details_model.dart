class OfferRecipientModel {
  final String name;
  final String email;
  final String riskLevel;

  const OfferRecipientModel({
    required this.name,
    required this.email,
    required this.riskLevel,
  });

  factory OfferRecipientModel.fromMap(Map<String, dynamic> map) {
    return OfferRecipientModel(
      name:      map['name']       as String? ?? '',
      email:     map['email']      as String? ?? '',
      riskLevel: map['risk_level'] as String? ?? '',
    );
  }
}

class OfferDetailsModel {
  final String title;
  final String description;
  final String offerType;
  final String benefit;
  final String? sentAt;
  final String? validUntil;
  final String targetType;
  final int numberOfMembers;
  final List<OfferRecipientModel> recipients;

  const OfferDetailsModel({
    required this.title,
    required this.description,
    required this.offerType,
    required this.benefit,
    required this.sentAt,
    required this.validUntil,
    required this.targetType,
    required this.numberOfMembers,
    required this.recipients,
  });

  factory OfferDetailsModel.fromMap(Map<String, dynamic> map) {
    final rawRecipients =
        (map['recipients'] as List? ?? []).cast<Map<String, dynamic>>();
    return OfferDetailsModel(
      title:           map['title']             as String? ?? '',
      description:     map['description']       as String? ?? '',
      offerType:       map['offer_type']        as String? ?? '',
      benefit:         map['benefit']           as String? ?? '-',
      sentAt:          map['sent_at']           as String?,
      validUntil:      map['valid_until']       as String?,
      targetType:      map['target_type']       as String? ?? '',
      numberOfMembers: map['number_of_members'] as int?    ?? 0,
      recipients:      rawRecipients.map(OfferRecipientModel.fromMap).toList(),
    );
  }
}