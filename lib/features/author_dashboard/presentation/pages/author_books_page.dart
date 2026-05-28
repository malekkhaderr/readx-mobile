import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_theme.dart';
import '../../data/models/publisher_request_model.dart';
import '../../data/models/author_book_model.dart';
import '../bloc/author_dashboard_bloc.dart';
import '../widgets/request_forms.dart';

class AuthorBooksPage extends StatefulWidget {
  const AuthorBooksPage({super.key});

  @override
  State<AuthorBooksPage> createState() => _AuthorBooksPageState();
}

class _AuthorBooksPageState extends State<AuthorBooksPage> {
  @override
  void initState() {
    super.initState();
    context.read<AuthorDashboardBloc>().add(LoadPublisherRequestsEvent());
  }

  void _showRequestOptionsSheet(BuildContext pageContext, List<AuthorBook>? availableBooks) {
    final bloc = pageContext.read<AuthorDashboardBloc>();
    showModalBottomSheet(
      context: pageContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return BlocProvider.value(
          value: bloc,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Create Request',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(Icons.add_circle, color: Colors.blue),
                  ),
                  title: const Text('Add New Book'),
                  subtitle: const Text('Submit a new book for publication'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showFormDialog(pageContext, const AddBookRequestForm());
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF3E0),
                    child: Icon(Icons.edit, color: Colors.orange),
                  ),
                  title: const Text('Modify Existing Book'),
                  subtitle: const Text('Request changes to a published book'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (availableBooks != null && availableBooks.isNotEmpty) {
                      _showFormDialog(pageContext, ModifyBookRequestForm(availableBooks: availableBooks));
                    } else {
                      ScaffoldMessenger.of(pageContext).showSnackBar(const SnackBar(content: Text('No books available to modify.')));
                    }
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEBEE),
                    child: Icon(Icons.delete, color: Colors.red),
                  ),
                  title: const Text('Remove Book'),
                  subtitle: const Text('Request to unpublish a book'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (availableBooks != null && availableBooks.isNotEmpty) {
                      _showFormDialog(pageContext, RemoveBookRequestForm(availableBooks: availableBooks));
                    } else {
                      ScaffoldMessenger.of(pageContext).showSnackBar(const SnackBar(content: Text('No books available to remove.')));
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFormDialog(BuildContext pageContext, Widget form) {
    final bloc = pageContext.read<AuthorDashboardBloc>();
    showDialog(
      context: pageContext,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: bloc,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: form,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'approved':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'rejected':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        break;
      case 'pending':
      default:
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFEF6C00);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'NewBook':
        return Icons.add_circle_outline;
      case 'ModifyBook':
        return Icons.edit_note;
      case 'RemoveBook':
        return Icons.delete_outline;
      default:
        return Icons.assignment;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text(
          'Publisher Requests',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
  
        elevation: 0,
        centerTitle: false,
      ),
      body: BlocConsumer<AuthorDashboardBloc, AuthorDashboardState>(
        listener: (context, state) {
          if (state is PublisherRequestSubmitSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
          } else if (state is AuthorDashboardError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        buildWhen: (previous, current) {
          return current is PublisherRequestsLoaded || current is PublisherRequestsLoading || current is AuthorDashboardError;
        },
        builder: (context, state) {
          final bloc = context.read<AuthorDashboardBloc>();
          List<PublisherRequestModel> requests = bloc.cachedRequests ?? [];

          if (state is PublisherRequestsLoading && requests.isEmpty) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          
          if (state is PublisherRequestsLoaded) {
            requests = state.requests;
          }

          if (requests.isEmpty && state is PublisherRequestsLoaded) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 64, color: AppColors.textLight),
                  SizedBox(height: 16),
                  Text(
                    'No requests found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Submit a new request to get started.',
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AuthorDashboardBloc>().add(LoadPublisherRequestsEvent());
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final req = requests[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(_getTypeIcon(req.type), color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                req.type,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          _buildStatusChip(req.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (req.requestMessage != null && req.requestMessage!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Message: "${req.requestMessage}"',
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontStyle: FontStyle.italic,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      if (req.adminNotes != null && req.adminNotes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.admin_panel_settings, size: 14, color: Colors.orange),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Admin: ${req.adminNotes}',
                                    style: TextStyle(color: Colors.orange, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ID: #${req.id}',
                            style: TextStyle(color: AppColors.textLight, fontSize: 12),
                          ),
                          Text(
                            _formatDate(req.createdAt),
                            style: TextStyle(color: AppColors.textLight, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final bloc = context.read<AuthorDashboardBloc>();
          
          if (bloc.cachedBooks == null) {
            // Fetch dashboard data if books aren't loaded yet
            bloc.add(LoadAuthorDashboardEvent());
          }
          
          _showRequestOptionsSheet(context, bloc.cachedBooks ?? []);
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
