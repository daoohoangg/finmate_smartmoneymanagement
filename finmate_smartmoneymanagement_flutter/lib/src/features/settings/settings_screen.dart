import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/storage/session_storage.dart';
import '../auth/login_screen.dart';
import '../ai_coach/ai_coach_intro_screen.dart';
import '../budget/allocate_funds_done_screen.dart';
import '../budget/allocate_funds_error_screen.dart';
import '../budget/allocate_funds_screen.dart';
import '../budget/budget_create_screen.dart';
import '../budget/budget_create_success_screen.dart';
import '../budget/budget_create_warning_screen.dart';
import '../budget/budget_status_empty_screen.dart';
import '../budget/budget_status_exceeded_screen.dart';
import '../budget/budget_status_track_screen.dart';
import '../budget/budget_status_warning_screen.dart';
import '../categories/manage_categories_screen.dart';
import '../analytics/category_detail_screen.dart';
import '../analytics/expense_breakdown_screen.dart';
import '../analytics/spending_insights_screen.dart';
import '../analytics/trend_analysis_screen.dart';
import '../calendar/weekly_calendar_screen.dart';
import '../dashboard/monthly_dashboard_screen.dart';
import '../onboarding/onboarding_flow_screen.dart';
import '../profile/change_password_screen.dart';
import '../profile/services/profile_service.dart';
import '../recurring/recurring_setup_screen.dart';
import '../settings/models/user_settings.dart';
import '../settings/services/settings_service.dart';
import '../sync/services/sync_service.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/edit_transaction_screen.dart';
import '../transactions/transactions_list_screen.dart';
import '../../shared/widgets/section_label.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const String routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  String _currency = 'VND';
  String _language = 'EN';
  int _roundingScale = 2;
  String _roundingMode = 'HALF_UP';
  String _fullName = 'User';
  String _email = '';
  Uint8List? _avatarBytes;
  bool _isLoading = false;

  final _settingsService = SettingsService();
  final _profileService = ProfileService();
  final _syncService = SyncService();

  @override
  void initState() {
    super.initState();
    final storage = SessionStorage.instance;
    _fullName = storage.fullName ?? _fullName;
    _email = storage.email ?? _email;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _settingsService.getSettings();
      final profile = await _profileService.getProfile();
      final avatar = await _profileService.downloadAvatar();
      if (!mounted) return;
      setState(() {
        _darkMode = settings.darkMode;
        _currency = settings.defaultCurrency;
        _language = settings.language;
        _roundingScale = settings.roundingScale;
        _roundingMode = settings.roundingMode;
        _fullName = profile.fullName;
        _email = profile.email;
        _avatarBytes = avatar;
      });
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateSettings() async {
    setState(() => _isLoading = true);
    try {
      final updated = await _settingsService.updateSettings(
        UserSettings(
          darkMode: _darkMode,
          language: _language,
          defaultCurrency: _currency,
          notificationEnabled: true,
          budgetAlertThreshold: 80,
          roundingScale: _roundingScale,
          roundingMode: _roundingMode,
        ),
      );
      setState(() {
        _darkMode = updated.darkMode;
        _currency = updated.defaultCurrency;
        _language = updated.language;
        _roundingScale = updated.roundingScale;
        _roundingMode = updated.roundingMode;
      });
      _showSnack('Settings updated successfully');
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _changeName() async {
    final controller = TextEditingController(text: _fullName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Full name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final value = controller.text.trim();
    if (value.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final profile = await _profileService.updateProfile(value);
      await SessionStorage.instance.updateProfile(fullName: profile.fullName);
      setState(() => _fullName = profile.fullName);
      _showSnack('Name updated successfully');
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openChangePassword() {
    Navigator.pushNamed(context, ChangePasswordScreen.routeName);
  }

  Future<void> _uploadAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;
    setState(() => _isLoading = true);
    try {
      final bytes = await image.readAsBytes();
      final profile = await _profileService.uploadAvatar(bytes, image.name);
      setState(() {
        _avatarBytes = bytes;
        _fullName = profile.fullName;
      });
      _showSnack('Avatar updated successfully');
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncNow() async {
    setState(() => _isLoading = true);
    try {
      await _syncService.syncAll();
      _showSnack('Sync completed successfully');
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await SessionStorage.instance.clear();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginScreen.routeName,
      (_) => false,
    );
  }

  void _openSurvey() {
    Navigator.pushNamed(context, OnboardingFlowScreen.routeName);
  }

  void _openAiCoach() {
    Navigator.pushNamed(context, AiCoachIntroScreen.routeName);
  }

  void _openAddTransaction() {
    Navigator.pushNamed(context, AddTransactionScreen.routeName);
  }

  void _openEditTransaction() {
    Navigator.pushNamed(context, EditTransactionScreen.routeName);
  }

  void _openTransactionsList() {
    Navigator.pushNamed(context, TransactionsListScreen.routeName);
  }

  void _openRecurringSetup() {
    Navigator.pushNamed(context, RecurringSetupScreen.routeName);
  }

  void _openManageCategories() {
    Navigator.pushNamed(context, ManageCategoriesScreen.routeName);
  }

  void _openBudgetCreate() {
    Navigator.pushNamed(context, BudgetCreateScreen.routeName);
  }

  void _openBudgetCreateWarning() {
    Navigator.pushNamed(context, BudgetCreateWarningScreen.routeName);
  }

  void _openBudgetCreateSuccess() {
    Navigator.pushNamed(context, BudgetCreateSuccessScreen.routeName);
  }

  void _openBudgetTrack() {
    Navigator.pushNamed(context, BudgetStatusTrackScreen.routeName);
  }

  void _openBudgetWarning() {
    Navigator.pushNamed(context, BudgetStatusWarningScreen.routeName);
  }

  void _openBudgetExceeded() {
    Navigator.pushNamed(context, BudgetStatusExceededScreen.routeName);
  }

  void _openBudgetEmpty() {
    Navigator.pushNamed(context, BudgetStatusEmptyScreen.routeName);
  }

  void _openAllocateFunds() {
    Navigator.pushNamed(context, AllocateFundsScreen.routeName);
  }

  void _openAllocateFundsError() {
    Navigator.pushNamed(context, AllocateFundsErrorScreen.routeName);
  }

  void _openAllocateFundsDone() {
    Navigator.pushNamed(context, AllocateFundsDoneScreen.routeName);
  }

  void _openDashboard() {
    Navigator.pushNamed(context, MonthlyDashboardScreen.routeName);
  }

  void _openExpenseBreakdown() {
    Navigator.pushNamed(context, ExpenseBreakdownScreen.routeName);
  }

  void _openCategoryDetail() {
    Navigator.pushNamed(context, CategoryDetailScreen.routeName);
  }

  void _openTrendAnalysis() {
    Navigator.pushNamed(context, TrendAnalysisScreen.routeName);
  }

  void _openWeeklyCalendar() {
    Navigator.pushNamed(context, WeeklyCalendarScreen.routeName);
  }

  void _openSpendingInsights() {
    Navigator.pushNamed(context, SpendingInsightsScreen.routeName);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: const FinMateBottomNav(
        active: FinMateNavItem.utilities,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _isLoading ? null : _uploadAvatar,
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primaryBlue.withOpacity(
                              0.12,
                            ),
                            backgroundImage: _avatarBytes != null
                                ? MemoryImage(_avatarBytes!)
                                : null,
                            child: _avatarBytes == null
                                ? const Icon(
                                    Icons.person,
                                    color: AppColors.primaryBlue,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _fullName,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _email,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: AppColors.textMuted,
                          ),
                          onPressed: _isLoading ? null : _changeName,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SectionLabel(text: 'appearance'.tr()),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE4E4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.nightlight_round,
                            color: AppColors.primaryRed,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'dark_mode'.tr(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Switch(
                          value: _darkMode,
                          activeColor: AppColors.primaryRed,
                          onChanged: (value) {
                            setState(() {
                              _darkMode = value;
                            });
                            _updateSettings();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SectionLabel(text: 'currency'.tr()),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE4E4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.currency_exchange,
                                color: AppColors.primaryRed,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'default_currency'.tr(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'currency_switch_desc'.tr(),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('VND'),
                                  selected: _currency == 'VND',
                                  onSelected: (_) {
                                    setState(() {
                                      _currency = 'VND';
                                    });
                                    _updateSettings();
                                  },
                                  showCheckmark: false,
                                  selectedColor: AppColors.primaryRed,
                                  backgroundColor: AppColors.chipBackground,
                                  labelStyle: TextStyle(
                                    color: _currency == 'VND'
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                ChoiceChip(
                                  label: const Text('USD'),
                                  selected: _currency == 'USD',
                                  onSelected: (_) {
                                    setState(() {
                                      _currency = 'USD';
                                    });
                                    _updateSettings();
                                  },
                                  showCheckmark: false,
                                  selectedColor: AppColors.primaryRed,
                                  backgroundColor: AppColors.chipBackground,
                                  labelStyle: TextStyle(
                                    color: _currency == 'USD'
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Current rate: 1 USD = 25,450 VND',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.primaryRed,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SectionLabel(text: 'language'.tr()),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE4E4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.language,
                            color: AppColors.primaryRed,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('language'.tr()),
                        const Spacer(),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: Text('vietnamese'.tr()),
                              selected: _language == 'VI',
                              onSelected: (_) async {
                                setState(() {
                                  _language = 'VI';
                                });
                                await context.setLocale(const Locale('vi'));
                                _updateSettings();
                              },
                              showCheckmark: false,
                              selectedColor: AppColors.primaryRed,
                              backgroundColor: AppColors.chipBackground,
                              labelStyle: TextStyle(
                                color: _language == 'VI'
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            ChoiceChip(
                              label: Text('english'.tr()),
                              selected: _language == 'EN',
                              onSelected: (_) async {
                                setState(() {
                                  _language = 'EN';
                                });
                                await context.setLocale(const Locale('en'));
                                _updateSettings();
                              },
                              showCheckmark: false,
                              selectedColor: AppColors.primaryRed,
                              backgroundColor: AppColors.chipBackground,
                              labelStyle: TextStyle(
                                color: _language == 'EN'
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SectionLabel(text: 'rounding'.tr()),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE4E4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.format_list_numbered,
                                color: AppColors.primaryRed,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('decimal_places'.tr()),
                            const Spacer(),
                            DropdownButton<int>(
                              value: _roundingScale,
                              underline: const SizedBox.shrink(),
                              items: const [
                                DropdownMenuItem(value: 0, child: Text('0')),
                                DropdownMenuItem(value: 2, child: Text('2')),
                                DropdownMenuItem(value: 3, child: Text('3')),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _roundingScale = value);
                                _updateSettings();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('rounding_mode'.tr()),
                            const Spacer(),
                            DropdownButton<String>(
                              value: _roundingMode,
                              underline: const SizedBox.shrink(),
                              items: const [
                                DropdownMenuItem(
                                  value: 'HALF_UP',
                                  child: Text('HALF_UP'),
                                ),
                                DropdownMenuItem(
                                  value: 'UP',
                                  child: Text('UP'),
                                ),
                                DropdownMenuItem(
                                  value: 'DOWN',
                                  child: Text('DOWN'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _roundingMode = value);
                                _updateSettings();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SectionLabel(text: 'smart_assist'.tr()),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _SettingsItem(
                          icon: Icons.auto_awesome,
                          label: 'ai_financial_coach'.tr(),
                          iconColor: AppColors.primaryBlue,
                          onTap: _openAiCoach,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SectionLabel(text: 'transactions_section'.tr()),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _SettingsItem(
                          icon: Icons.add_circle_outline,
                          label: 'add_transaction'.tr(),
                          iconColor: AppColors.primaryBlue,
                          onTap: _openAddTransaction,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsItem(
                          icon: Icons.edit_outlined,
                          label: 'edit_transaction'.tr(),
                          iconColor: AppColors.primaryBlue,
                          onTap: _openEditTransaction,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsItem(
                          icon: Icons.list_alt_outlined,
                          label: 'transactions_list'.tr(),
                          iconColor: AppColors.primaryBlue,
                          onTap: _openTransactionsList,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsItem(
                          icon: Icons.repeat,
                          label: 'recurring_setup'.tr(),
                          iconColor: AppColors.primaryBlue,
                          onTap: _openRecurringSetup,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SectionLabel(text: 'funds_screens'.tr()),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _SettingsItem(
                          icon: Icons.add_chart,
                          label: 'create_funds'.tr(),
                          iconColor: AppColors.primaryBlue,
                          onTap: _openBudgetCreate,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsItem(
                          icon: Icons.warning_amber_rounded,
                          label: 'create_funds_warning'.tr(),
                          iconColor: AppColors.primaryBlue,
                          onTap: _openBudgetCreateWarning,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsItem(
                          icon: Icons.check_circle_outline,
                          label: 'create_funds_success'.tr(),
                          iconColor: AppColors.primaryBlue,
                          onTap: _openBudgetCreateSuccess,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsItem(
                          icon: Icons.timeline,
                          label: 'Funds Status (On Track)',
                          iconColor: AppColors.primaryBlue,
                          onTap: _openBudgetTrack,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsItem(
                          icon: Icons.warning_amber,
                          label: 'Funds Status (Warning)',
                          iconColor: AppColors.primaryBlue,
                          onTap: _openBudgetWarning,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsItem(
                          icon: Icons.report,
                          label: 'Funds Status (Exceeded)',
                          iconColor: AppColors.primaryBlue,
                          onTap: _openBudgetExceeded,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsItem(
                          icon: Icons.inbox_outlined,
                          label: 'Funds Status (Empty)',
                          iconColor: AppColors.primaryBlue,
                          onTap: _openBudgetEmpty,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsItem(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Allocate Budget',
                          iconColor: AppColors.primaryBlue,
                          onTap: _openAllocateFunds,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsItem(
                          icon: Icons.error_outline,
                          label: 'Allocate Budget (Error)',
                          iconColor: AppColors.primaryBlue,
                          onTap: _openAllocateFundsError,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsItem(
                          icon: Icons.check_circle,
                          label: 'Allocate Budget (Done)',
                          iconColor: AppColors.primaryBlue,
                          onTap: _openAllocateFundsDone,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SectionLabel(text: 'ANALYTICS SCREENS'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _SettingsItem(
                          icon: Icons.dashboard_outlined,
                          label: 'Monthly Dashboard',
                          iconColor: AppColors.primaryBlue,
                          onTap: _openDashboard,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsItem(
                          icon: Icons.pie_chart_outline,
                          label: 'Expense Breakdown',
                          iconColor: AppColors.primaryBlue,
                          onTap: _openExpenseBreakdown,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsItem(
                          icon: Icons.restaurant_outlined,
                          label: 'Category Detail',
                          iconColor: AppColors.primaryBlue,
                          onTap: _openCategoryDetail,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsItem(
                          icon: Icons.bar_chart_outlined,
                          label: 'Trend Analysis',
                          iconColor: AppColors.primaryBlue,
                          onTap: _openTrendAnalysis,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsItem(
                          icon: Icons.calendar_today_outlined,
                          label: 'Weekly Calendar',
                          iconColor: AppColors.primaryBlue,
                          onTap: _openWeeklyCalendar,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsItem(
                          icon: Icons.insights_outlined,
                          label: 'Spending Insights',
                          iconColor: AppColors.primaryBlue,
                          onTap: _openSpendingInsights,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SectionLabel(text: 'CATEGORIES'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _SettingsItem(
                          icon: Icons.category_outlined,
                          label: 'Manage Categories',
                          iconColor: AppColors.primaryBlue,
                          onTap: _openManageCategories,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SectionLabel(text: 'FINANCIAL SURVEY'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _SettingsItem(
                          icon: Icons.fact_check_outlined,
                          label: 'Take onboarding survey',
                          iconColor: AppColors.primaryRed,
                          onTap: _openSurvey,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SectionLabel(text: 'ACCOUNT & SECURITY'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _SettingsItem(
                          icon: Icons.person,
                          label: 'Profile Settings',
                          iconColor: AppColors.primaryRed,
                          onTap: _changeName,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsItem(
                          icon: Icons.lock,
                          label: 'Change Password',
                          iconColor: AppColors.primaryRed,
                          onTap: _openChangePassword,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsItem(
                          icon: Icons.notifications,
                          label: 'Sync Now',
                          iconColor: AppColors.primaryRed,
                          onTap: _syncNow,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryRed),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'logout'.tr(),
                        style: const TextStyle(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Finance Tracker v2.4.0 (Build 82)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE4E4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
