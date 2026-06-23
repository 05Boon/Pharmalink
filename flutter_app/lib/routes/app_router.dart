import 'package:go_router/go_router.dart';
import '../pages/login_page.dart';
import '../pages/register_page.dart';
import '../pages/owner_dashboard_page.dart';
import '../pages/drug_query_page.dart';
import '../pages/search_results_page.dart';
import '../pages/receive_alert_page.dart';
import '../pages/accept_share_page.dart';
import '../pages/view_response_page.dart';
import '../pages/transaction_history_page.dart';
import '../pages/admin_dashboard_page.dart';
import '../pages/manage_pharmacies_page.dart';
import '../pages/approve_onboarding_page.dart';
import '../pages/monitor_transactions_page.dart';
import '../pages/reports_page.dart';
import '../pages/audit_logs_page.dart';

final appRouter = GoRouter(
  initialLocation: '/register',
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
      builder: (context, state) => const SearchResultsPage(),
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
      path: '/admin',
      builder: (context, state) => const AdminDashboardPage(),
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
      builder: (context, state) => const ReportsPage(),
    ),
    GoRoute(
      path: '/admin/logs',
      builder: (context, state) => const AuditLogsPage(),
    ),
  ],
);
