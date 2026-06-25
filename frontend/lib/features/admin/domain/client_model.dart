class ClientListItem {
  final int id;
  final String name, email, status;
  final String? phone, subscription, subscriptionEnd, joined, invitationSent;
  final int? visits;

  ClientListItem({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    this.phone,
    this.subscription,
    this.subscriptionEnd,
    this.visits,
    this.joined,
    this.invitationSent,
  });

  factory ClientListItem.fromJson(Map<String, dynamic> json) {
    return ClientListItem(
      id:              (json['id']    as int?)    ?? 0,
      name:            (json['name']  as String?) ?? '',
      email:           (json['email'] as String?) ?? '',
      status:          (json['status'] as String?) ?? 'pending',
      phone:           json['phone']            as String?,
      subscription:    json['subscription']     as String?,
      subscriptionEnd: json['subscription_end'] as String?,
      visits:          json['visits']           as int?,
      joined:          json['joined']           as String?,
      invitationSent:  json['invitation_sent']  as String?,
    );
  }
}

class ClientListResponse {
  final int total, active, pending, expired;
  final List<ClientListItem> members;

  ClientListResponse({
    required this.total,
    required this.active,
    required this.pending,
    required this.expired,
    required this.members,
  });

  factory ClientListResponse.fromJson(Map<String, dynamic> json) {
    return ClientListResponse(
      total:   (json['total']   as int?) ?? 0,
      active:  (json['active']  as int?) ?? 0,
      pending: (json['pending'] as int?) ?? 0,
      expired: (json['expired'] as int?) ?? 0,
      members: (json['members'] as List<dynamic>? ?? [])
          .map((m) => ClientListItem.fromJson(m))
          .toList(),
    );
  }
}