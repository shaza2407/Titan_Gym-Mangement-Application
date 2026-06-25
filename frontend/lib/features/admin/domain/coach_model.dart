class CoachListItem {
  final int id;
  final String name, email, status;
  final String? phone, hireDate, invitationSent;

  CoachListItem({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    this.phone,
    this.hireDate,
    this.invitationSent,
  });

  factory CoachListItem.fromJson(Map<String, dynamic> json) {
    return CoachListItem(
      id:             (json['id']    as int?)    ?? 0,
      name:           (json['name']  as String?) ?? '',
      email:          (json['email'] as String?) ?? '',
      status:         (json['status'] as String?) ?? 'pending',
      phone:          json['phone']           as String?,
      hireDate:       json['hire_date']       as String?,
      invitationSent: json['invitation_sent'] as String?,
    );
  }
}

class CoachListResponse {
  final int total, active, pending;
  final List<CoachListItem> coaches;

  CoachListResponse({
    required this.total,
    required this.active,
    required this.pending,
    required this.coaches,
  });

  factory CoachListResponse.fromJson(Map<String, dynamic> json) {
    return CoachListResponse(
      total:   (json['total']   as int?) ?? 0,
      active:  (json['active']  as int?) ?? 0,
      pending: (json['pending'] as int?) ?? 0,
      coaches: (json['coaches'] as List<dynamic>? ?? [])
          .map((c) => CoachListItem.fromJson(c))
          .toList(),
    );
  }
}