import 'package:flutter/material.dart';

import 'src/core/theme/app_theme.dart';
import 'src/core/storage/session_storage.dart';
import 'src/features/auth/forgot_password_screen.dart';
import 'src/features/auth/login_screen.dart';
import 'src/features/auth/register_screen.dart';
import 'src/features/ai_coach/ai_coach_chat_screen.dart';
import 'src/features/ai_coach/ai_coach_intro_screen.dart';
import 'src/features/budget/allocate_funds_done_screen.dart';
import 'src/features/budget/allocate_funds_error_screen.dart';
import 'src/features/budget/allocate_funds_screen.dart';
import 'src/features/budget/budget_create_screen.dart';
import 'src/features/budget/budget_create_success_screen.dart';
import 'src/features/budget/budget_create_warning_screen.dart';
import 'src/features/budget/budget_status_empty_screen.dart';
import 'src/features/budget/budget_status_exceeded_screen.dart';
import 'src/features/budget/budget_status_track_screen.dart';
import 'src/features/budget/budget_status_warning_screen.dart';
import 'src/features/categories/create_category_screen.dart';
import 'src/features/categories/delete_category_screen.dart';
import 'src/features/categories/manage_categories_screen.dart';
import 'src/features/analytics/category_detail_screen.dart';
import 'src/features/analytics/expense_breakdown_screen.dart';
import 'src/features/analytics/spending_insights_screen.dart';
import 'src/features/analytics/trend_analysis_screen.dart';
import 'src/features/dashboard/monthly_dashboard_screen.dart';
import 'src/features/calendar/weekly_calendar_screen.dart';
import 'src/features/onboarding/onboarding_flow_screen.dart';
import 'src/features/planning/fix_overspending_screen.dart';
import 'src/features/planning/manual_allocation_screen.dart';
import 'src/features/planning/plan_recommendation_screen.dart';
import 'src/features/profile/change_password_screen.dart';
import 'src/features/recurring/recurring_custom_screen.dart';
import 'src/features/recurring/recurring_setup_screen.dart';
import 'src/features/settings/settings_screen.dart';
import 'src/features/transactions/add_transaction_screen.dart';
import 'src/features/transactions/delete_transaction_screen.dart';
import 'src/features/transactions/edit_transaction_screen.dart';
import 'src/features/transactions/filter_transactions_screen.dart';
import 'src/features/transactions/search_results_screen.dart';
import 'src/features/transactions/transactions_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionStorage.instance.init();
  runApp(const FinMateApp());
}

class FinMateApp extends StatelessWidget {
  const FinMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = SessionStorage.instance;
    final hasSession = storage.token != null;
    final initialRoute = hasSession ? SettingsScreen.routeName : LoginScreen.routeName;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FinMate',
      theme: buildAppTheme(),
      initialRoute: initialRoute,
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
        ForgotPasswordScreen.routeName: (_) => const ForgotPasswordScreen(),
        AiCoachIntroScreen.routeName: (_) => const AiCoachIntroScreen(),
        AiCoachChatScreen.routeName: (_) => const AiCoachChatScreen(),
        MonthlyDashboardScreen.routeName: (_) => const MonthlyDashboardScreen(),
        ExpenseBreakdownScreen.routeName: (_) => const ExpenseBreakdownScreen(),
        CategoryDetailScreen.routeName: (_) => const CategoryDetailScreen(),
        TrendAnalysisScreen.routeName: (_) => const TrendAnalysisScreen(),
        WeeklyCalendarScreen.routeName: (_) => const WeeklyCalendarScreen(),
        SpendingInsightsScreen.routeName: (_) => const SpendingInsightsScreen(),
        AddTransactionScreen.routeName: (_) => const AddTransactionScreen(),
        EditTransactionScreen.routeName: (_) => const EditTransactionScreen(),
        DeleteTransactionScreen.routeName: (_) => const DeleteTransactionScreen(),
        TransactionsListScreen.routeName: (_) => const TransactionsListScreen(),
        FilterTransactionsScreen.routeName: (_) => const FilterTransactionsScreen(),
        SearchResultsScreen.routeName: (_) => const SearchResultsScreen(),
        BudgetCreateScreen.routeName: (_) => const BudgetCreateScreen(),
        BudgetCreateWarningScreen.routeName: (_) => const BudgetCreateWarningScreen(),
        BudgetCreateSuccessScreen.routeName: (_) => const BudgetCreateSuccessScreen(),
        BudgetStatusTrackScreen.routeName: (_) => const BudgetStatusTrackScreen(),
        BudgetStatusWarningScreen.routeName: (_) => const BudgetStatusWarningScreen(),
        BudgetStatusExceededScreen.routeName: (_) => const BudgetStatusExceededScreen(),
        BudgetStatusEmptyScreen.routeName: (_) => const BudgetStatusEmptyScreen(),
        AllocateFundsScreen.routeName: (_) => const AllocateFundsScreen(),
        AllocateFundsErrorScreen.routeName: (_) => const AllocateFundsErrorScreen(),
        AllocateFundsDoneScreen.routeName: (_) => const AllocateFundsDoneScreen(),
        OnboardingFlowScreen.routeName: (_) => const OnboardingFlowScreen(),
        PlanRecommendationScreen.routeName: (_) => const PlanRecommendationScreen(),
        ManualAllocationScreen.routeName: (_) => const ManualAllocationScreen(),
        FixOverspendingScreen.routeName: (_) => const FixOverspendingScreen(),
        RecurringSetupScreen.routeName: (_) => const RecurringSetupScreen(),
        RecurringCustomScreen.routeName: (_) => const RecurringCustomScreen(),
        ManageCategoriesScreen.routeName: (_) => const ManageCategoriesScreen(),
        CreateCategoryScreen.routeName: (_) => const CreateCategoryScreen(),
        DeleteCategoryScreen.routeName: (_) => const DeleteCategoryScreen(),
        ChangePasswordScreen.routeName: (_) => const ChangePasswordScreen(),
        SettingsScreen.routeName: (_) => const SettingsScreen(),
      },
    );
  }
}
