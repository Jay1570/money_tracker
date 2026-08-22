import "package:material_ui/material_ui.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:money_tracker/main.dart";
import "package:money_tracker/modules/accounts/add_account_screen.dart";
import "package:money_tracker/modules/accounts/edit_account_screen.dart";
import "package:money_tracker/modules/accounts/view_account_screen.dart";
import "package:money_tracker/modules/home/home_screen.dart";
import "package:money_tracker/modules/reports/reports_screen.dart";
import "package:money_tracker/modules/settings/settings_screen.dart";
import "package:money_tracker/modules/transactions/add_transaction_screen.dart";
import "package:money_tracker/modules/transactions/recurring_transaction_screen.dart";

import "package:money_tracker/modules/budgets/budgets_screen.dart";
import "package:money_tracker/modules/budgets/add_budget_screen.dart";

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: "/home",
    routes: [
      GoRoute(
        path: "/home",
        builder: (context, state) => const HomeScreen(),
        pageBuilder: (context, state) => buildSlidePage(
          state: state,
          child: const HomeScreen(),
        ),
        // routes: [],
      ),
      GoRoute(
        path: "/reports",
        pageBuilder: (context, state) => buildSlidePage(
          state: state,
          child: const ReportsScreen(),
        ),
      ),
      GoRoute(
        path: "/account/add",
        pageBuilder: (context, state) => buildSlidePage(
          state: state,
          child: const AddAccountScreen(),
        ),
      ),
      GoRoute(
        path: "/account/view/:id",
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return buildSlidePage(
            state: state,
            child: ViewAccountScreen(accountId: id ?? 0),
          );
        },
      ),
      GoRoute(
        path: "/account/edit/:id",
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return buildSlidePage(
            state: state,
            child: EditAccountScreen(accountId: id ?? 0),
          );
        },
      ),
      GoRoute(
        path: "/transaction/add",
        pageBuilder: (context, state) => buildSlidePage(
          state: state,
          child: const AddTransactionScreen(),
        ),
      ),
      GoRoute(
        path: "/transaction/edit/:id",
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return buildSlidePage(
            state: state,
            child: AddTransactionScreen(transactionId: id),
          );
        },
      ),
      GoRoute(
        path: "/recurring-transactions",
        pageBuilder: (context, state) => buildSlidePage(
          state: state,
          child: const RecurringTransactionsScreen(),
        ),
      ),
      GoRoute(
        path: "/recurring-transactions/add",
        pageBuilder: (context, state) => buildSlidePage(
          state: state,
          child: const AddTransactionScreen(
            isRecurring: true,
          ),
        ),
      ),
      GoRoute(
        path: "/settings",
        pageBuilder: (context, state) => buildSlidePage(
          state: state,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: "/budgets",
        pageBuilder: (context, state) => buildSlidePage(
          state: state,
          child: const BudgetsScreen(),
        ),
      ),
      GoRoute(
        path: "/budgets/add",
        pageBuilder: (context, state) => buildSlidePage(
          state: state,
          child: const AddBudgetScreen(),
        ),
      ),
      GoRoute(
        path: "/budgets/edit/:id",
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return buildSlidePage(
            state: state,
            child: AddBudgetScreen(budgetId: id),
          );
        },
      ),

      GoRoute(
        path: "/",
        redirect: (_, _) => "/home",
        // routes: [],
      ),
    ],
  );
});

CustomTransitionPage<T> buildSlidePage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    child: child,
    transitionsBuilder:
        (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOut));

          return SlideTransition(
            position: animation.drive(offsetAnimation),
            child: child,
          );
        },
  );
}
