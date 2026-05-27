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
  static const String me = '/users/me';

  // Books
  static const String books = '/books';
  static const String booksHome = '/books/home';

  // Quotes
  static const String quotes = '/quotes';
  static const String authorQuotesStats = '/Quotes/author/stats';
  static const String authorQuotes = '/Quotes/author';

  // Notifications
  static const String notifications = '/Notifications';

  // Publisher Requests
  static const String publisherRequests = '/PublisherRequests';
  static const String publisherRequestsMy = '/PublisherRequests/my';
  static const String publisherRequestsModify = '/PublisherRequests/modify';
  static const String publisherRequestsRemove = '/PublisherRequests/remove';

  // Reading Sessions
  static const String readingSessions = '/reading-sessions';

  // Author Dashboard
  // Author Dashboard
  static const String authorDashboard = '/AuthorDashboard/dashboard';
  static const String authorBooks = '/AuthorDashboard/books';
  static const String authorStatistics = '/AuthorDashboard/statistics';
}
