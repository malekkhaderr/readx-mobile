import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/reports_bloc.dart';
import '../bloc/reports_event.dart';
import '../bloc/reports_state.dart';
import 'submit_report_sheet.dart';

class MyReportsPage extends StatelessWidget {
  const MyReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReportsBloc>()..add(const LoadMyReportsEvent()),
      child: const _MyReportsView(),
    );
  }
}

class _MyReportsView extends StatelessWidget {
  const _MyReportsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Support Tickets',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.textDark),
      ),
      body: BlocBuilder<ReportsBloc, ReportsState>(
        builder: (context, state) {
          if (state is ReportsLoading || state is ReportsInitial) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          } else if (state is ReportsError) {
            return _buildError(context, state.message);
          } else if (state is MyReportsLoaded) {
            final reports = state.reports;
            if (reports.isEmpty) {
              return _buildEmptyState(context);
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ReportsBloc>().add(const LoadMyReportsEvent());
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _resolveTitle(report.reason, report.customReason),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(report.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (report.description != null &&
                            report.description!.isNotEmpty)
                          Text(
                            report.description!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textGrey,
                            ),
                          ),
                        const SizedBox(height: 12),
                        Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Submitted: ${DateFormat('MMM dd, yyyy').format(report.submittedAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                            if (report.updatedAt != null)
                              Text(
                                'Updated: ${DateFormat('MMM dd, yyyy').format(report.updatedAt!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                ),
                              ),
                          ],
                        ),
                        if (report.adminFeedback != null &&
                            report.adminFeedback!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.support_agent_rounded,
                                    size: 18, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Support Response',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        report.adminFeedback!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textDark,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showSubmitReportSheet(context);
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('New Ticket', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  String _resolveTitle(String reason, String? customReason) {
    if (reason == 'Other' && customReason != null && customReason.isNotEmpty) {
      return customReason;
    }
    return reason;
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String displayLabel;

    switch (status.toLowerCase()) {
      case 'done':
      case 'resolved':
        bgColor = AppColors.successGreen.withOpacity(0.15);
        textColor = AppColors.successGreen;
        displayLabel = 'Done';
        break;
      case 'inreview':
      case 'in review':
        bgColor = const Color(0xFF2196F3).withOpacity(0.15);
        textColor = const Color(0xFF2196F3);
        displayLabel = 'In Review';
        break;
      case 'waiting':
      case 'pending':
        bgColor = AppColors.warningOrange.withOpacity(0.15);
        textColor = AppColors.warningOrange;
        displayLabel = 'Waiting';
        break;
      case 'canceled':
      case 'cancelled':
      case 'rejected':
        bgColor = AppColors.error.withOpacity(0.12);
        textColor = AppColors.error;
        displayLabel = 'Canceled';
        break;
      default:
        bgColor = AppColors.textGrey.withOpacity(0.15);
        textColor = AppColors.textGrey;
        displayLabel = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.support_agent_rounded,
                  size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'No Support Tickets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "You haven't submitted any support tickets yet.\nNeed help? We're here for you!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textGrey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showSubmitReportSheet(context),
              icon: Icon(Icons.add, size: 20),
              label: const Text('Submit a Ticket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textGrey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<ReportsBloc>().add(const LoadMyReportsEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child:
                const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSubmitReportSheet(BuildContext context) {
    final myReportsBloc = context.read<ReportsBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BlocProvider(
          create: (_) => sl<ReportsBloc>()..add(const LoadReportReasonsEvent()),
          child: SubmitReportSheet(
            onSuccess: () {
              myReportsBloc.add(const LoadMyReportsEvent());
            },
          ),
        );
      },
    );
  }
}
