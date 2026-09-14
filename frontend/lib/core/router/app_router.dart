import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/resident/presentation/screens/residents_screen.dart';
import '../../features/resident/presentation/screens/resident_detail_screen.dart';
import '../../features/access/presentation/screens/access_screen.dart';
import '../../features/access/presentation/screens/access_detail_screen.dart';
import '../../features/access/presentation/screens/visitor_management_screen.dart';
import '../../features/payment/presentation/screens/payments_screen.dart';
import '../../features/payment/presentation/screens/payment_detail_screen.dart';
import '../../features/notice/presentation/screens/notices_screen.dart';
import '../../features/notice/presentation/screens/notice_detail_screen.dart';
import '../../features/booking/presentation/screens/bookings_screen.dart';
import '../../features/booking/presentation/screens/booking_detail_screen.dart';
import '../../features/service/presentation/screens/services_screen.dart';
import '../../features/service/presentation/screens/service_detail_screen.dart';
import '../../features/accounting/presentation/screens/accounting_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
                          state.matchedLocation.startsWith('/register') ||
                          state.matchedLocation.startsWith('/splash');

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }
      if (isLoggedIn && isAuthRoute && !state.matchedLocation.startsWith('/splash')) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),

      GoRoute(path: '/residents', builder: (_, __) => const ResidentsScreen()),
      GoRoute(path: '/residents/:id', builder: (_, state) => ResidentDetailScreen(residentId: state.pathParameters['id']!)),

      GoRoute(path: '/access', builder: (_, __) => const AccessScreen()),
      GoRoute(path: '/access/:id', builder: (_, state) => AccessDetailScreen(accessId: state.pathParameters['id']!)),
      GoRoute(path: '/visitors', builder: (_, __) => const VisitorManagementScreen()),

      GoRoute(path: '/payments', builder: (_, __) => const PaymentsScreen()),
      GoRoute(path: '/payments/:id', builder: (_, state) => PaymentDetailScreen(paymentId: state.pathParameters['id']!)),

      GoRoute(path: '/notices', builder: (_, __) => const NoticesScreen()),
      GoRoute(path: '/notices/:id', builder: (_, state) => NoticeDetailScreen(noticeId: state.pathParameters['id']!)),

      GoRoute(path: '/bookings', builder: (_, __) => const BookingsScreen()),
      GoRoute(path: '/bookings/:id', builder: (_, state) => BookingDetailScreen(bookingId: state.pathParameters['id']!)),

      GoRoute(path: '/services', builder: (_, __) => const ServicesScreen()),
      GoRoute(path: '/services/:id', builder: (_, state) => ServiceDetailScreen(serviceId: state.pathParameters['id']!)),

      GoRoute(path: '/accounting', builder: (_, __) => const AccountingScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ],
  );
});