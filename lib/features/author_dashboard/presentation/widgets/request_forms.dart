import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_theme.dart';
import '../../data/models/author_book_model.dart';
import '../../data/models/publisher_request_model.dart';
import '../bloc/author_dashboard_bloc.dart';

class AddBookRequestForm extends StatefulWidget {
  const AddBookRequestForm({super.key});

  @override
  State<AddBookRequestForm> createState() => _AddBookRequestFormState();
}

class _AddBookRequestFormState extends State<AddBookRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _epubController = TextEditingController();
  final _coverController = TextEditingController();
  final _isbnController = TextEditingController();
  final _summaryController = TextEditingController();
  final _priceController = TextEditingController();
  final _pagesController = TextEditingController();
  final _messageController = TextEditingController();
  
  int? _categoryId;
  int? _languageId;

  // Static options since there's no endpoint for this in the app currently.
  final Map<int, String> _categories = {
    1: 'Fiction',
    2: 'Non-Fiction',
    3: 'Science',
    4: 'History',
    5: 'Biography',
    6: 'Fantasy',
  };

  final Map<int, String> _languages = {
    1: 'English',
    2: 'Arabic',
    3: 'Spanish',
    4: 'French',
    5: 'German',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _epubController.dispose();
    _coverController.dispose();
    _isbnController.dispose();
    _summaryController.dispose();
    _priceController.dispose();
    _pagesController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final request = AddBookRequestModel(
        title: _titleController.text,
        epubFileUrl: _epubController.text,
        coverImageUrl: _coverController.text,
        isbn: _isbnController.text,
        summary: _summaryController.text,
        categoryId: _categoryId ?? 1,
        languageId: _languageId ?? 1,
        price: double.tryParse(_priceController.text) ?? 0.0,
        totalPages: int.tryParse(_pagesController.text) ?? 0,
        requestMessage: _messageController.text,
      );
      context.read<AuthorDashboardBloc>().add(SubmitAddBookRequestEvent(request));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: true,
        children: [
          Text('Submit Add Book Request', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 16),
          _buildTextField('Book Title', _titleController, isRequired: true),
          _buildTextField('ePub File URL', _epubController, isRequired: true),
          _buildTextField('Cover Image URL', _coverController, isRequired: true),
          _buildTextField('ISBN', _isbnController),
          _buildTextField('Summary', _summaryController, maxLines: 3),
          _buildDropdownField(
            'Category',
            _categoryId,
            _categories,
            (value) => setState(() => _categoryId = value),
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            'Language',
            _languageId,
            _languages,
            (value) => setState(() => _languageId = value),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField('Price', _priceController, isNumber: true)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField('Total Pages', _pagesController, isNumber: true)),
            ],
          ),
          _buildTextField('Request Message (Optional)', _messageController, maxLines: 2),
          const SizedBox(height: 24),
          BlocConsumer<AuthorDashboardBloc, AuthorDashboardState>(
            listener: (context, state) {
              if (state is PublisherRequestSubmitSuccess) {
                Navigator.of(context).pop(); // Close dialog on success
              }
            },
            builder: (context, state) {
              final isLoading = state is PublisherRequestSubmitting;
              return ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Submit Request', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isRequired = false, bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        validator: isRequired ? (value) => value == null || value.isEmpty ? 'This field is required' : null : null,
      ),
    );
  }

  Widget _buildDropdownField(String label, int? value, Map<int, String> options, ValueChanged<int?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<int>(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        value: value,
        items: options.entries.map((entry) {
          return DropdownMenuItem<int>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (val) => val == null ? 'Please select a $label' : null,
      ),
    );
  }
}

class ModifyBookRequestForm extends StatefulWidget {
  final List<AuthorBook> availableBooks;
  const ModifyBookRequestForm({super.key, required this.availableBooks});

  @override
  State<ModifyBookRequestForm> createState() => _ModifyBookRequestFormState();
}

class _ModifyBookRequestFormState extends State<ModifyBookRequestForm> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedBookId;
  final _detailsController = TextEditingController();

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedBookId != null) {
      final request = ModifyBookRequestModel(
        bookId: _selectedBookId!,
        modificationDetails: _detailsController.text,
      );
      context.read<AuthorDashboardBloc>().add(SubmitModifyBookRequestEvent(request));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Submit Modify Book Request', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Select Book',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            value: _selectedBookId,
            items: widget.availableBooks.map((book) {
              return DropdownMenuItem<int>(
                value: book.id,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(book.title, overflow: TextOverflow.ellipsis),
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedBookId = value),
            validator: (value) => value == null ? 'Please select a book' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _detailsController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Modification Details',
              hintText: 'What needs to be changed?',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Details are required' : null,
          ),
          const SizedBox(height: 24),
          BlocConsumer<AuthorDashboardBloc, AuthorDashboardState>(
            listener: (context, state) {
              if (state is PublisherRequestSubmitSuccess) {
                Navigator.of(context).pop(); // Close dialog on success
              }
            },
            builder: (context, state) {
              final isLoading = state is PublisherRequestSubmitting;
              return ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Submit Request', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              );
            },
          ),
        ],
      ),
    );
  }
}

class RemoveBookRequestForm extends StatefulWidget {
  final List<AuthorBook> availableBooks;
  const RemoveBookRequestForm({super.key, required this.availableBooks});

  @override
  State<RemoveBookRequestForm> createState() => _RemoveBookRequestFormState();
}

class _RemoveBookRequestFormState extends State<RemoveBookRequestForm> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedBookId;
  final _reasonController = TextEditingController();

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedBookId != null) {
      final request = RemoveBookRequestModel(
        bookId: _selectedBookId!,
        reason: _reasonController.text,
      );
      context.read<AuthorDashboardBloc>().add(SubmitRemoveBookRequestEvent(request));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Submit Remove Book Request', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Select Book',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            value: _selectedBookId,
            items: widget.availableBooks.map((book) {
              return DropdownMenuItem<int>(
                value: book.id,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(book.title, overflow: TextOverflow.ellipsis),
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedBookId = value),
            validator: (value) => value == null ? 'Please select a book' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Reason for Removal',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Reason is required' : null,
          ),
          const SizedBox(height: 24),
          BlocConsumer<AuthorDashboardBloc, AuthorDashboardState>(
            listener: (context, state) {
              if (state is PublisherRequestSubmitSuccess) {
                Navigator.of(context).pop(); // Close dialog on success
              }
            },
            builder: (context, state) {
              final isLoading = state is PublisherRequestSubmitting;
              return ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Submit Request', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              );
            },
          ),
        ],
      ),
    );
  }
}
