import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_theme.dart';
import '../../domain/entities/report_reason_entity.dart';
import '../bloc/reports_bloc.dart';
import '../bloc/reports_event.dart';
import '../bloc/reports_state.dart';

class SubmitReportSheet extends StatefulWidget {
  final VoidCallback onSuccess;

  const SubmitReportSheet({super.key, required this.onSuccess});

  @override
  State<SubmitReportSheet> createState() => _SubmitReportSheetState();
}

class _SubmitReportSheetState extends State<SubmitReportSheet> {
  ReportReasonEntity? _selectedReason;
  bool _isOtherSelected = false;
  final TextEditingController _customReasonController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _customReasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_isOtherSelected && _selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason')),
      );
      return;
    }

    context.read<ReportsBloc>().add(
          SubmitReportEvent(
            reasonId: _isOtherSelected ? null : _selectedReason!.id,
            customReason:
                _isOtherSelected ? _customReasonController.text.trim() : null,
            description: _descriptionController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportsBloc, ReportsState>(
      listener: (context, state) {
        if (state is ReportSubmittedSuccessfully) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ticket submitted successfully!'),
              backgroundColor: AppColors.successGreen,
            ),
          );
          Navigator.of(context).pop();
          widget.onSuccess();
        } else if (state is ReportsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Submit Support Ticket',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<ReportsBloc, ReportsState>(
                buildWhen: (previous, current) =>
                    current is ReportsLoading ||
                    current is ReportReasonsLoaded ||
                    current is ReportsError,
                builder: (context, state) {
                  if (state is ReportsLoading) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    );
                  } else if (state is ReportReasonsLoaded) {
                    return _buildForm(state.reasons);
                  } else if (state is ReportsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 48),
                          const SizedBox(height: 16),
                          Text(state.message),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context
                                  .read<ReportsBloc>()
                                  .add(const LoadReportReasonsEvent());
                            },
                            child: const Text('Retry'),
                          )
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(List<ReportReasonEntity> reasons) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How can we help you?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select a reason and describe your issue in detail.',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
            const SizedBox(height: 20),

            // Reason Dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Reason',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
              ),
              value: _isOtherSelected
                  ? '__other__'
                  : _selectedReason?.id.toString(),
              items: [
                ...reasons.map((reason) {
                  return DropdownMenuItem<String>(
                    value: reason.id.toString(),
                    child: Text(reason.label),
                  );
                }),
                const DropdownMenuItem<String>(
                  value: '__other__',
                  child: Text('Other (Specify Reason)'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  if (value == '__other__') {
                    _isOtherSelected = true;
                    _selectedReason = null;
                  } else {
                    _isOtherSelected = false;
                    _customReasonController.clear();
                    _selectedReason = reasons.firstWhere(
                      (r) => r.id.toString() == value,
                    );
                  }
                });
              },
              validator: (value) =>
                  value == null ? 'Please select a reason' : null,
            ),

            // Custom Reason field (shown only when "Other" selected)
            if (_isOtherSelected) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _customReasonController,
                decoration: InputDecoration(
                  labelText: 'Specify Custom Reason',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a custom reason';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 16),

            // Description field (required)
            TextFormField(
              controller: _descriptionController,
              maxLines: 6,
              maxLength: 2000,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Describe your issue in detail...',
                alignLabelWithHint: true,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                if (value.trim().length < 10) {
                  return 'Description must be at least 10 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Submit button with loading state
            BlocBuilder<ReportsBloc, ReportsState>(
              buildWhen: (prev, curr) =>
                  curr is ReportSubmitting ||
                  curr is ReportSubmittedSuccessfully ||
                  curr is ReportsError,
              builder: (context, state) {
                final isSubmitting = state is ReportSubmitting;
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Submit Ticket',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
