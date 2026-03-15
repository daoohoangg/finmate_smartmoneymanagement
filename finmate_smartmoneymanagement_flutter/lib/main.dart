import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'src/core/theme/app_theme.dart';
import 'src/core/storage/session_storage.dart';
import 'src/features/auth/forgot_password_screen.dart';
import 'src/features/auth/login_screen.dart';
import 'src/features/auth/otp_verify_screen.dart';
import 'src/features/auth/register_screen.dart';
import 'src/features/auth/reset_password_screen.dart';
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
import 'src/features/budget/subcategory_budget_detail_screen.dart';
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
import 'src/features/planning/manage_budget_screen.dart';
import 'src/features/planning/manual_allocation_screen.dart';
import 'src/features/planning/plan_recommendation_screen.dart';
import 'src/features/profile/change_password_screen.dart';
import 'src/features/recurring/recurring_custom_screen.dart';
import 'src/features/recurring/recurring_setup_screen.dart';
import 'src/features/settings/settings_screen.dart';
import 'src/features/utilities/utilities_screen.dart';
import 'src/features/transactions/add_transaction_screen.dart';
import 'src/features/transactions/delete_transaction_screen.dart';
import 'src/features/transactions/edit_transaction_screen.dart';
import 'src/features/transactions/filter_transactions_screen.dart';
import 'src/features/transactions/search_results_screen.dart';
import 'src/features/transactions/transactions_list_screen.dart';
import 'src/shared/widgets/finmate_top_nav.dart';

// Navigation globals
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<String> currentRouteNotifier = ValueNotifier<String>('/');

class AppRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null) {
      currentRouteNotifier.value = route.settings.name!;
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute?.settings.name != null) {
      currentRouteNotifier.value = previousRoute!.settings.name!;
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute?.settings.name != null) {
      currentRouteNotifier.value = newRoute!.settings.name!;
    }
  }
}

final AppRouteObserver appRouteObserver = AppRouteObserver();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await SessionStorage.instance.init();
  
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('vi')],
      path: 'assets/translations', // path to translation files
      fallbackLocale: const Locale('en'),
      useFallbackTranslations: true,
      child: const FinMateApp(),
    ),
  );
}

class FinMateApp extends StatelessWidget {
  const FinMateApp({super.key});

  Widget _buildLanding(bool hasSession) {
    if (hasSession) {
      return MonthlyDashboardScreen();
    }
    return LoginScreen();
  }

  Widget _buildGradientBackground(Widget child) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFF8F9FA), Color(0xFFF8F9FA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.2, 1.0],
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = SessionStorage.instance;
    final hasSession = storage.token != null;
    return MaterialApp(
      key: ValueKey<bool>(hasSession),
      navigatorKey: appNavigatorKey,
      navigatorObservers: [appRouteObserver],
      debugShowCheckedModeBanner: false,
      title: 'FinMate',
      theme: buildAppTheme(),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      initialRoute: '/',
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return Scaffold(
                backgroundColor: Colors.transparent,
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(64),
                  child: FinMateTopNav(
                    currentRouteNotifier: currentRouteNotifier,
                    navigatorKey: appNavigatorKey,
                  ),
                ),
                body: child ?? const SizedBox.shrink(),
              );
            }
            return child ?? const SizedBox.shrink();
          },
        );
      },
      routes: {
        '/': (_) => _buildGradientBackground(_buildLanding(hasSession)),
        LoginScreen.routeName: (_) => _buildGradientBackground(const LoginScreen()),
        RegisterScreen.routeName: (_) => _buildGradientBackground(const RegisterScreen()),
        ForgotPasswordScreen.routeName: (_) => _buildGradientBackground(const ForgotPasswordScreen()),
        OtpVerifyScreen.routeName: (_) => _buildGradientBackground(const OtpVerifyScreen()),
        ResetPasswordScreen.routeName: (_) => _buildGradientBackground(const ResetPasswordScreen()),
        AiCoachIntroScreen.routeName: (_) => _buildGradientBackground(const AiCoachIntroScreen()),
        AiCoachChatScreen.routeName: (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments as String?;
          return _buildGradientBackground(AiCoachChatScreen(initialMessage: args));
        },
        MonthlyDashboardScreen.routeName: (_) => _buildGradientBackground(const MonthlyDashboardScreen()),
        ExpenseBreakdownScreen.routeName: (_) => _buildGradientBackground(const ExpenseBreakdownScreen()),
        CategoryDetailScreen.routeName: (_) => _buildGradientBackground(const CategoryDetailScreen()),
        TrendAnalysisScreen.routeName: (_) => _buildGradientBackground(const TrendAnalysisScreen()),
        WeeklyCalendarScreen.routeName: (_) => _buildGradientBackground(const WeeklyCalendarScreen()),
        SpendingInsightsScreen.routeName: (_) => _buildGradientBackground(const SpendingInsightsScreen()),
        AddTransactionScreen.routeName: (_) => _buildGradientBackground(const AddTransactionScreen()),
        EditTransactionScreen.routeName: (_) => _buildGradientBackground(const EditTransactionScreen()),
        DeleteTransactionScreen.routeName: (_) =>
            _buildGradientBackground(const DeleteTransactionScreen()),
        TransactionsListScreen.routeName: (_) => _buildGradientBackground(const TransactionsListScreen()),
        FilterTransactionsScreen.routeName: (_) =>
            _buildGradientBackground(const FilterTransactionsScreen()),
        SearchResultsScreen.routeName: (_) => _buildGradientBackground(const SearchResultsScreen()),
        BudgetCreateScreen.routeName: (_) => _buildGradientBackground(const BudgetCreateScreen()),
        BudgetCreateWarningScreen.routeName: (_) =>
            _buildGradientBackground(const BudgetCreateWarningScreen()),
        BudgetCreateSuccessScreen.routeName: (_) =>
            _buildGradientBackground(const BudgetCreateSuccessScreen()),
        BudgetStatusTrackScreen.routeName: (_) =>
            _buildGradientBackground(const BudgetStatusTrackScreen()),
        BudgetStatusWarningScreen.routeName: (_) =>
            _buildGradientBackground(const BudgetStatusWarningScreen()),
        BudgetStatusExceededScreen.routeName: (_) =>
            _buildGradientBackground(const BudgetStatusExceededScreen()),
        BudgetStatusEmptyScreen.routeName: (_) =>
            _buildGradientBackground(const BudgetStatusEmptyScreen()),
        SubCategoryBudgetDetailScreen.routeName: (_) =>
            _buildGradientBackground(const SubCategoryBudgetDetailScreen()),
        AllocateFundsScreen.routeName: (_) => _buildGradientBackground(const AllocateFundsScreen()),
        AllocateFundsErrorScreen.routeName: (_) =>
            _buildGradientBackground(const AllocateFundsErrorScreen()),
        AllocateFundsDoneScreen.routeName: (_) =>
            _buildGradientBackground(const AllocateFundsDoneScreen()),
        OnboardingFlowScreen.routeName: (_) => _buildGradientBackground(const OnboardingFlowScreen()),
        PlanRecommendationScreen.routeName: (_) =>
            _buildGradientBackground(const PlanRecommendationScreen()),
        ManualAllocationScreen.routeName: (_) => _buildGradientBackground(const ManualAllocationScreen()),
        ManageBudgetScreen.routeName: (_) => _buildGradientBackground(const ManageBudgetScreen()),
        RecurringSetupScreen.routeName: (_) => _buildGradientBackground(const RecurringSetupScreen()),
        RecurringCustomScreen.routeName: (_) => _buildGradientBackground(const RecurringCustomScreen()),
        ManageCategoriesScreen.routeName: (_) => _buildGradientBackground(const ManageCategoriesScreen()),
        CreateCategoryScreen.routeName: (_) => _buildGradientBackground(const CreateCategoryScreen()),
        DeleteCategoryScreen.routeName: (_) => _buildGradientBackground(const DeleteCategoryScreen()),
        ChangePasswordScreen.routeName: (_) => _buildGradientBackground(const ChangePasswordScreen()),
        SettingsScreen.routeName: (_) => _buildGradientBackground(const SettingsScreen()),
        UtilitiesScreen.routeName: (_) => _buildGradientBackground(const UtilitiesScreen()),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => _buildGradientBackground(_buildLanding(hasSession)),
      ),
    );
  }
}
