import 'package:flutter/material.dart';
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
      
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/residents', builder: (_, __) => const ResidentsScreen()),
            GoRoute(path: '/residents/:id', builder: (_, state) => ResidentDetailScreen(residentId: state.pathParameters['id']!)),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/access', builder: (_, __) => const AccessScreen()),
            GoRoute(path: '/access/:id', builder: (_, state) => AccessDetailScreen(accessId: state.pathParameters['id']!)),
            GoRoute(path: '/visitors', builder: (_, __) => const VisitorManagementScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/payments', builder: (_, __) => const PaymentsScreen()),
            GoRoute(path: '/payments/:id', builder: (_, state) => PaymentDetailScreen(paymentId: state.pathParameters['id']!)),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/notices', builder: (_, __) => const NoticesScreen()),
            GoRoute(path: '/notices/:id', builder: (_, state) => NoticeDetailScreen(noticeId: state.pathParameters['id']!)),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/bookings', builder: (_, __) => const BookingsScreen()),
            GoRoute(path: '/bookings/:id', builder: (_, state) => BookingDetailScreen(bookingId: state.pathParameters['id']!)),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/services', builder: (_, __) => const ServicesScreen()),
            GoRoute(path: '/services/:id', builder: (_, state) => ServiceDetailScreen(serviceId: state.pathParameters['id']!)),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/accounting', builder: (_, __) => const AccountingScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())]),
        ],
      ),
    ],
  );
});

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  
  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Residentes'),
          NavigationDestination(icon: Icon(Icons.security_outlined), selectedIcon: Icon(Icons.security), label: 'Accesos'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: 'Pagos'),
          NavigationDestination(icon: Icon(Icons.announcement_outlined), selectedIcon: Icon(Icons.announcement), label: 'Avisos'),
          NavigationDestination(icon: Icon(Icons.event_seat_outlined), selectedIcon: Icon(Icons.event_seat), label: 'Reservas'),
          NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build), label: 'Servicios'),
          NavigationDestination(icon: Icon(Icons.account_balance_outlined), selectedIcon: Icon(Icons.account_balance), label: 'Contabilidad'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Config'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}