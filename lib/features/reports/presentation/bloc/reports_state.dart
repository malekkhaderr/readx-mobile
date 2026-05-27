import 'package:equatable/equatable.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/entities/report_reason_entity.dart';

abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportSubmitting extends ReportsState {}

class ReportReasonsLoaded extends ReportsState {
  final List<ReportReasonEntity> reasons;

  const ReportReasonsLoaded({required this.reasons});

  @override
  List<Object?> get props => [reasons];
}

class MyReportsLoaded extends ReportsState {
  final List<ReportEntity> reports;

  const MyReportsLoaded({required this.reports});

  @override
  List<Object?> get props => [reports];
}

class ReportSubmittedSuccessfully extends ReportsState {}

class ReportsError extends ReportsState {
  final String message;

  const ReportsError({required this.message});

  @override
  List<Object?> get props => [message];
}
