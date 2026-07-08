import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../pages/login_page.dart';
import '../pages/register_page.dart';
import '../pages/bulk_register_page.dart';
import '../pages/owner_dashboard_page.dart';
import '../pages/drug_query_page.dart';
import '../pages/search_results_page.dart';
import '../pages/receive_alert_page.dart';
import '../pages/accept_share_page.dart';
import '../pages/view_response_page.dart';
import '../pages/transaction_history_page.dart';
import '../pages/manage_pharmacies_page.dart';
import '../pages/approve_onboarding_page.dart';
import '../pages/monitor_transactions_page.dart';
import '../pages/audit_logs_page.dart';
import '../pages/manage_inventory_page.dart';

final appRouter = GoRouter(
  initialLocation: '/register',
  redirect: (context, state) {
    final isLoggedIn = AuthService.isLoggedIn();
    final isGoingToAdmin = state.uri.path.startsWith('/admin');

    if (isGoingToAdmin) {
      if (!isLoggedIn) {
        return '/login';
      }
      if (!AuthService.isAdmin) {
        return '/dashboard';
      }
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/debug/bulk-register',
      builder: (context, state) => const BulkRegisterPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const OwnerDashboardPage(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const DrugQueryPage(),
    ),
    GoRoute(
      path: '/search/results',
      builder: (context, state) => SearchResultsPage(
        query: state.uri.queryParameters['q'],
      ),
    ),
    GoRoute(
      path: '/requests',
      builder: (context, state) => const ReceiveAlertPage(),
    ),
    GoRoute(
      path: '/requests/accepted',
      builder: (context, state) => const AcceptSharePage(),
    ),
    GoRoute(
      path: '/search/response',
      builder: (context, state) => const ViewResponsePage(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const TransactionHistoryPage(),
    ),
    GoRoute(
      path: '/inventory',
      builder: (context, state) => const ManageInventoryPage(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/pharmacies',
      builder: (context, state) => const ManagePharmaciesPage(),
    ),
    GoRoute(
      path: '/admin/pharmacies/approve/:id',
      builder: (context, state) => ApproveOnboardingPage(
        pharmacyId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/admin/transactions',
      builder: (context, state) => const MonitorTransactionsPage(),
    ),
    GoRoute(
      path: '/admin/reports',
      // Keep legacy reports path working by rendering reports inside admin dashboard.
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/logs',
      builder: (context, state) => const AuditLogsPage(),
    ),
  ],
);