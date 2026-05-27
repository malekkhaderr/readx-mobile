import '../../domain/entities/report_entity.dart';

class ReportModel extends ReportEntity {
  ReportModel({
    required super.id,
    required super.reason,
    super.customReason,
    super.description,
    required super.status,
    super.adminFeedback,
    required super.submittedAt,
    super.updatedAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as int,
      reason: json['reason'] as String,
      customReason: json['customReason'] as String?,
      description: json['description'] as String?,
      status: json['status'] as String,
      adminFeedback: json['adminFeedback'] as String?,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reason': reason,
      'customReason': customReason,
      'description': description,
      'status': status,
      'adminFeedback': adminFeedback,
      'submittedAt': submittedAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
