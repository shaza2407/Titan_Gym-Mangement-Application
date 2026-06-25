class InviteMemberModel {
  final String email;
  final String inviteAs; // 'client' | 'coach'
  final String subscriptionType; // 'monthly' | 'yearly'
  final int subscriptionMonths;
  final int subscriptionPrice;

  const InviteMemberModel({
    required this.email,
    required this.inviteAs,
    required this.subscriptionType,
    required this.subscriptionMonths,
    required this.subscriptionPrice,
  });

  bool get isCoach => inviteAs == 'coach';

  String get subscriptionSummary {
    if (isCoach) return '';
    if (subscriptionType == 'yearly') {
      return '$subscriptionMonths year${subscriptionMonths > 1 ? 's' : ''} subscription';
    }
    return '$subscriptionMonths month${subscriptionMonths > 1 ? 's' : ''} subscription';
  }
}