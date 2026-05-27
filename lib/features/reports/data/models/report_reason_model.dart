import '../../domain/entities/report_reason_entity.dart';

class ReportReasonModel extends ReportReasonEntity {
  ReportReasonModel({
    required super.id,
    required super.label,
    required super.appliesTo,
  });

  factory ReportReasonModel.fromJson(Map<String, dynamic> json) {
    return ReportReasonModel(
      id: json['id'] as int,
      label: json['label'] as String,
      appliesTo: json['appliesTo'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'appliesTo': appliesTo,
    };
  }
}
