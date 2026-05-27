import 'package:get_it/get_it.dart';
import '../../features/library/data/datasources/library_remote_datasource.dart';
import '../../features/library/presentation/bloc/library_bloc.dart';
import '../../features/quotes/data/datasources/quotes_remote_datasource.dart';
import '../../features/quotes/presentation/bloc/quotes_bloc.dart';
import '../../features/search/data/datasources/search_remote_datasource.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/forgot_password_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/reset_password_usecase.dart';
import '../../features/auth/domain/usecases/send_otp_usecase.dart';
import '../../features/auth/domain/usecases/verify_otp_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_me_usecase.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/home/data/datasources/home_remote_datasource.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_home_usecase.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/home/data/datasources/books_service.dart';
import '../../features/notifications/data/datasources/notifications_remote_datasource.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/domain/usecases/get_notifications_usecase.dart';
import '../../features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../features/notifications/domain/usecases/mark_one_notification_read_usecase.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../../features/author_dashboard/data/datasources/author_dashboard_remote_datasource.dart';
import '../../features/author_dashboard/data/repositories/author_dashboard_repository_impl.dart';
import '../../features/author_dashboard/domain/repositories/author_dashboard_repository.dart';
import '../../features/author_dashboard/domain/usecases/get_author_dashboard_usecase.dart';
import '../../features/author_dashboard/domain/usecases/get_author_books_usecase.dart';
import '../../features/author_dashboard/domain/usecases/get_author_statistics_usecase.dart';
import '../../features/author_dashboard/domain/usecases/publisher_requests_usecases.dart';
import '../../features/author_dashboard/domain/usecases/get_author_quotes_stats_usecase.dart';
import '../../features/author_dashboard/domain/usecases/get_author_book_quotes_usecase.dart';
import '../../features/author_dashboard/presentation/bloc/author_dashboard_bloc.dart';
import '../../features/reports/data/datasources/reports_remote_datasource.dart';
import '../../features/reports/data/repositories/reports_repository_impl.dart';
import '../../features/reports/domain/repositories/reports_repository.dart';
import '../../features/reports/domain/usecases/get_my_reports_usecase.dart';
import '../../features/reports/domain/usecases/get_report_reasons_usecase.dart';
import '../../features/reports/domain/usecases/submit_report_usecase.dart';
import '../../features/reports/presentation/bloc/reports_bloc.dart';
import '../network/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> init() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // ─── Core ───────────────────────────────────────────
  sl.registerLazySingleton<DioClient>(() => DioClient(prefs: sl()));

  // Restore auth token from cache so profile loads without re-login
  final cachedToken = sharedPreferences.getString('CACHED_AUTH_TOKEN');
  if (cachedToken != null && cachedToken.isNotEmpty) {
    sl<DioClient>().setAuthToken(cachedToken);
  }

  // ─── Auth ────────────────────────────────────────────

  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
      forgotPasswordUseCase: sl(),
      resetPasswordUseCase: sl(),
      sendOtpUseCase: sl(),
      verifyOtpUseCase: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => SendOtpUseCase(sl()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));

  // Data Source
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dioClient: sl(), sharedPreferences: sl()),
  );

  // ─── Profile ─────────────────────────────────────────

  // Bloc
  sl.registerLazySingleton(() => ProfileBloc(getMeUseCase: sl()));

  // Use Case
  sl.registerLazySingleton(() => GetMeUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(sl()));

  // Data Source
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(
      dioClient: sl(),
      sharedPreferences: sl(),
    ),
  );

  // ─── Home ────────────────────────────────────────────

  // Bloc
  sl.registerLazySingleton(() => HomeBloc(getHomeUseCase: sl()));

  // Use Case
  sl.registerLazySingleton(() => GetHomeUseCase(sl()));

  // Repository
  sl.registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(remoteDataSource: sl()));

  // Data Source
  sl.registerLazySingleton<HomeRemoteDataSource>(
      () => HomeRemoteDataSourceImpl(dioClient: sl()));
      
  sl.registerLazySingleton<BooksService>(
      () => BooksService(dioClient: sl()));

  // ─── Library ──────────────────────────────────────────

  sl.registerLazySingleton<LibraryRemoteDataSource>(
    () => LibraryRemoteDataSource(dioClient: sl()),
  );

  // Lazy singleton so home + library tab share the same instance
  // (lets the home page show "Owned" badges using library state).
  sl.registerLazySingleton(
    () => LibraryBloc(dataSource: sl()),
  );

  // ─── Quotes ──────────────────────────────────────────

  sl.registerLazySingleton<QuotesRemoteDataSource>(
    () => QuotesRemoteDataSource(dioClient: sl()),
  );

  sl.registerLazySingleton(
    () => QuotesBloc(dataSource: sl()),
  );

  // ─── Search ──────────────────────────────────────────

  sl.registerLazySingleton<SearchRemoteDataSource>(
    () => SearchRemoteDataSource(dioClient: sl()),
  );

  // Factory so each entry to the Search tab starts with a clean state.
  sl.registerFactory(() => SearchBloc(dataSource: sl()));

  // ─── Notifications ─────────────────────────────────────

  // Bloc
  sl.registerFactory(
    () => NotificationsBloc(
      getNotificationsUseCase: sl(),
      markAllNotificationsReadUseCase: sl(),
      markOneNotificationReadUseCase: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => MarkAllNotificationsReadUseCase(sl()));
  sl.registerLazySingleton(() => MarkOneNotificationReadUseCase(sl()));

  // Repository
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Source
  sl.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSourceImpl(dioClient: sl()),
  );

  // ─── Author Dashboard ──────────────────────────────────

  // Bloc
  sl.registerFactory(
    () => AuthorDashboardBloc(
      getAuthorDashboardUseCase: sl(),
      getAuthorBooksUseCase: sl(),
      getAuthorStatisticsUseCase: sl(),
      getPublisherRequestsUseCase: sl(),
      submitAddBookRequestUseCase: sl(),
      submitModifyBookRequestUseCase: sl(),
      submitRemoveBookRequestUseCase: sl(),
      getAuthorQuotesStatsUseCase: sl(),
      getAuthorBookQuotesUseCase: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetAuthorDashboardUseCase(sl()));
  sl.registerLazySingleton(() => GetAuthorBooksUseCase(sl()));
  sl.registerLazySingleton(() => GetAuthorStatisticsUseCase(sl()));
  
  sl.registerLazySingleton(() => GetPublisherRequestsUseCase(sl()));
  sl.registerLazySingleton(() => SubmitAddBookRequestUseCase(sl()));
  sl.registerLazySingleton(() => SubmitModifyBookRequestUseCase(sl()));
  sl.registerLazySingleton(() => SubmitRemoveBookRequestUseCase(sl()));
  sl.registerLazySingleton(() => GetAuthorQuotesStatsUseCase(sl()));
  sl.registerLazySingleton(() => GetAuthorBookQuotesUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthorDashboardRepository>(
    () => AuthorDashboardRepositoryImpl(sl()),
  );

  // Data Source
  sl.registerLazySingleton<AuthorDashboardRemoteDataSource>(
    () => AuthorDashboardRemoteDataSourceImpl(dioClient: sl()),
  );

  // ─── Reports ───────────────────────────────────────────

  // Bloc
  sl.registerFactory(
    () => ReportsBloc(
      getReportReasonsUseCase: sl(),
      getMyReportsUseCase: sl(),
      submitReportUseCase: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetReportReasonsUseCase(sl()));
  sl.registerLazySingleton(() => GetMyReportsUseCase(sl()));
  sl.registerLazySingleton(() => SubmitReportUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ReportsRepository>(
    () => ReportsRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Source
  sl.registerLazySingleton<ReportsRemoteDataSource>(
    () => ReportsRemoteDataSourceImpl(dioClient: sl()),
  );
}

