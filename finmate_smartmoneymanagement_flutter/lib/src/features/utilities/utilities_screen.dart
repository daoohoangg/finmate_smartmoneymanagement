import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';
import '../ai_coach/ai_coach_intro_screen.dart';
import '../analytics/trend_analysis_screen.dart';
import '../budget/budget_status_track_screen.dart';
import '../planning/manage_budget_screen.dart';
import '../calendar/weekly_calendar_screen.dart';
import '../categories/manage_categories_screen.dart';
import '../dashboard/monthly_dashboard_screen.dart';
import '../recurring/recurring_setup_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../settings/services/settings_service.dart';
import '../settings/models/user_settings.dart';
import '../../core/storage/session_storage.dart';
import '../auth/login_screen.dart';
class UtilitiesScreen extends StatefulWidget {
  const UtilitiesScreen({super.key});

  static const String routeName = '/utilities';

  @override
  State<UtilitiesScreen> createState() => _UtilitiesScreenState();
}

class _UtilitiesScreenState extends State<UtilitiesScreen> {
  bool _darkMode = false;
  String _language = 'EN';
  bool _isLoading = false;
  final _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _settingsService.getSettings();
      if (!mounted) return;
      setState(() {
        _darkMode = settings.darkMode;
        _language = settings.language;
      });
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateSettings(bool? newDarkMode, String? newLanguage) async {
    setState(() => _isLoading = true);
    try {
      final currentSettings = await _settingsService.getSettings();
      final updated = await _settingsService.updateSettings(
        UserSettings(
          darkMode: newDarkMode ?? currentSettings.darkMode,
          language: newLanguage ?? currentSettings.language,
          defaultCurrency: currentSettings.defaultCurrency,
          notificationEnabled: currentSettings.notificationEnabled,
          budgetAlertThreshold: currentSettings.budgetAlertThreshold,
          roundingScale: currentSettings.roundingScale,
          roundingMode: currentSettings.roundingMode,
        ),
      );
      if (!mounted) return;
      setState(() {
        _darkMode = updated.darkMode;
        _language = updated.language;
      });
    } catch (e) {
      debugPrint('Failed to update settings: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background provided by main gradient
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Utilities',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.support_agent_outlined, color: AppColors.textPrimary, size: 22),
                    onPressed: () {},
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  Container(width: 1, height: 20, color: AppColors.border),
                  IconButton(
                    icon: const Icon(Icons.home_outlined, color: AppColors.textPrimary, size: 22),
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, MonthlyDashboardScreen.routeName, (route) => false),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      bottomNavigationBar: const FinMateBottomNav(active: FinMateNavItem.utilities),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE0F2FE), // Soft light blue
              Color(0xFFF8F9FA), // Generic app page background
              Color(0xFFF8F9FA),
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildReportCard(context),
                const SizedBox(height: 16),
                _buildSettingsWidgets(context),
                const SizedBox(height: 16),
                _buildAdvancedUtilities(context),
                const SizedBox(height: 16),
                _buildLogoutButton(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context) {
    final now = DateTime.now();
    // Calculate Monday
    final monday = now.subtract(Duration(days: now.weekday - 1));
    // Calculate Sunday (or just 6 days after Monday)
    final sunday = monday.add(const Duration(days: 6));
    
    final formattedMonday = '${monday.day}/${monday.month}';
    final formattedSunday = '${sunday.day}/${sunday.month}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Periodic spending report',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, TrendAnalysisScreen.routeName),
            child: Container(
              height: 100,
              width: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF0F5),
                    Color(0xFFFCE4EC),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Week:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$formattedMonday - $formattedSunday',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontSize: 18,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Receive notification for spending reports',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
              Switch(
                value: true,
                onChanged: (val) {},
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF22C55E),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsWidgets(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildThemeSwitch(context),
          const Divider(height: 1, color: AppColors.border),
          _buildLanguageSwitch(context),
        ],
      ),
    );
  }

  Widget _buildThemeSwitch(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.dark_mode_outlined, color: Color(0xFF14B8A6), size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Switch(
            value: _darkMode,
            onChanged: (val) {
              _updateSettings(val, null);
            },
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF22C55E),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSwitch(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.language_outlined, color: Color(0xFF14B8A6), size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Language', style: TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('EN', style: TextStyle(fontSize: 12)),
                selected: _language == 'EN',
                onSelected: (_) {
                  _updateSettings(null, 'EN');
                  context.setLocale(const Locale('en'));
                },
                showCheckmark: false,
                selectedColor: AppColors.primaryRed,
                labelStyle: TextStyle(
                  color: _language == 'EN' ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ChoiceChip(
                label: const Text('VI', style: TextStyle(fontSize: 12)),
                selected: _language == 'VI',
                onSelected: (_) {
                  _updateSettings(null, 'VI');
                  context.setLocale(const Locale('vi'));
                },
                showCheckmark: false,
                selectedColor: AppColors.primaryRed,
                labelStyle: TextStyle(
                  color: _language == 'VI' ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedUtilities(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced utilities',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 8,
            childAspectRatio: 0.7, // Taller items for text
            children: [
              _buildIconBtn(context, Icons.note_add_outlined, 'Import transactions',
                  route: AddTransactionScreen.routeName),
              _buildIconBtn(context, Icons.trending_up, 'Cash flow tracking',
                  route: TrendAnalysisScreen.routeName),
              _buildIconBtn(context, Icons.folder_open_outlined, 'Manage categories',
                  route: ManageCategoriesScreen.routeName),
              _buildIconBtn(context, Icons.local_offer_outlined, 'Transaction classification'),
              
              _buildIconBtn(context, Icons.savings_outlined, 'Budgets',
                  badge: '+ Coins', route: ManageBudgetScreen.routeName),
              _buildIconBtn(context, Icons.flag_outlined, 'Saving goal',
                  route: BudgetStatusTrackScreen.routeName),
              _buildIconBtn(context, Icons.calendar_month_outlined, 'Calendar',
                  route: WeeklyCalendarScreen.routeName),
                  
              _buildIconBtn(context, Icons.smart_toy_outlined, 'AI Coach',
                  route: AiCoachIntroScreen.routeName),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconBtn(BuildContext context, IconData icon, String label, {String? route, String? badge}) {
    return GestureDetector(
      onTap: route != null ? () => Navigator.pushNamed(context, route) : null,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8FB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: const Color(0xFF14B8A6), size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.2,
                    ),
              ),
            ],
          ),
          if (badge != null)
            Positioned(
              top: -6,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: () {
          SessionStorage.instance.clear();
          Navigator.pushNamedAndRemoveUntil(context, LoginScreen.routeName, (route) => false);
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primaryRed),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
        ),
        child: const Text(
          'Log Out',
          style: TextStyle(
            color: AppColors.primaryRed,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
