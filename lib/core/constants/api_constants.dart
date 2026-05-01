class ApiConstants {
  static const String baseUrl =
      'https://graduation-project-backend-j3bw.onrender.com/api';

  // Auth
  static const String register = '/users/create';
  static const String login = '/users/login';
  static const String logout = '/auth/logout';
  static const String resetPassword = '/auth/reset-password';

  // Users
  static const String users = '/users';

  // Books
  static const String books = '/books';

  // Quotes
  static const String quotes = '/quotes';

  // Notifications
  static const String notifications = '/notifications';

  // Publisher Requests
  static const String publisherRequests = '/publisher-requests';
}
