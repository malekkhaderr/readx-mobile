import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_my_reports_usecase.dart';
import '../../domain/usecases/get_report_reasons_usecase.dart';
import '../../domain/usecases/submit_report_usecase.dart';
import 'reports_event.dart';
import 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final GetReportReasonsUseCase getReportReasonsUseCase;
  final GetMyReportsUseCase getMyReportsUseCase;
  final SubmitReportUseCase submitReportUseCase;

  ReportsBloc({
    required this.getReportReasonsUseCase,
    required this.getMyReportsUseCase,
    required this.submitReportUseCase,
  }) : super(ReportsInitial()) {
    on<LoadReportReasonsEvent>(_onLoadReportReasons);
    on<LoadMyReportsEvent>(_onLoadMyReports);
    on<SubmitReportEvent>(_onSubmitReport);
  }

  Future<void> _onLoadReportReasons(
      LoadReportReasonsEvent event, Emitter<ReportsState> emit) async {
    emit(ReportsLoading());
    final result = await getReportReasonsUseCase();
    result.fold(
      (failure) => emit(ReportsError(message: failure.message)),
      (reasons) => emit(ReportReasonsLoaded(reasons: reasons)),
    );
  }

  Future<void> _onLoadMyReports(
      LoadMyReportsEvent event, Emitter<ReportsState> emit) async {
    emit(ReportsLoading());
    final result = await getMyReportsUseCase();
    result.fold(
      (failure) => emit(ReportsError(message: failure.message)),
      (reports) => emit(MyReportsLoaded(reports: reports)),
    );
  }

  Future<void> _onSubmitReport(
      SubmitReportEvent event, Emitter<ReportsState> emit) async {
    emit(ReportsLoading());
    final result = await submitReportUseCase(
      reasonId: event.reasonId,
      customReason: event.customReason,
      description: event.description,
    );
    result.fold(
      (failure) => emit(ReportsError(message: failure.message)),
      (_) => emit(ReportSubmittedSuccessfully()),
    );
  }
}
