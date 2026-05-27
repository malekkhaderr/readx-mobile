class ReportEntity {
  final int id;
  final String reason;
  final String? customReason;
  final String? description;
  final String status;
  final String? adminFeedback;
  final DateTime submittedAt;
  final DateTime? updatedAt;

  ReportEntity({
    required this.id,
    required this.reason,
    this.customReason,
    this.description,
    required this.status,
    this.adminFeedback,
    required this.submittedAt,
    this.updatedAt,
  });
}
