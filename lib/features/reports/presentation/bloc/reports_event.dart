import 'package:equatable/equatable.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

class LoadReportReasonsEvent extends ReportsEvent {
  const LoadReportReasonsEvent();
}

class LoadMyReportsEvent extends ReportsEvent {
  const LoadMyReportsEvent();
}

class SubmitReportEvent extends ReportsEvent {
  final int? reasonId;
  final String? customReason;
  final String? description;

  const SubmitReportEvent({
    this.reasonId,
    this.customReason,
    this.description,
  });

  @override
  List<Object?> get props => [reasonId, customReason, description];
}
