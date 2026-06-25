class RenewMembershipRequest {
  final String subscriptionType;
  final int durationCount;
  final double price;

  const RenewMembershipRequest({
    required this.subscriptionType,
    required this.durationCount,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'subscription_type': subscriptionType,
    'duration_count':    durationCount,
    'price':             price,
  };
}