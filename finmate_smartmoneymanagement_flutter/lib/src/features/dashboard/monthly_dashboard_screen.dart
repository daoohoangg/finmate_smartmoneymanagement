import 'package:flutter/material.dart';

class MonthlyDashboardScreen extends StatelessWidget {
  const MonthlyDashboardScreen({super.key});

  static const String routeName = '/dashboard/monthly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _HomeColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BalanceHeader(),
                        SizedBox(height: 18),
                        _WalletCard(),
                        SizedBox(height: 22),
                        _QuickActionsGrid(),
                        SizedBox(height: 22),
                        _SummaryRow(),
                        SizedBox(height: 22),
                        _GoalsSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const _HomeBottomNav(),
          ],
        ),
      ),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '9,955,500đ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.visibility_outlined,
                    color: _HomeColors.textMuted,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Tổng số dư',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _HomeColors.textMuted,
                      fontSize: 13,
                    ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _HomeColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _HomeColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swap_horiz, color: _HomeColors.textPrimary, size: 18),
              const SizedBox(width: 6),
              Text(
                'Đổi ví',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _HomeColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: CustomPaint(
        foregroundPainter: _DiagonalLinesPainter(
          color: Colors.white.withOpacity(0.08),
          spacing: 18,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2D325E), Color(0xFF3B2A89)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Cá nhân',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  const Icon(Icons.visibility, color: Colors.white70, size: 18),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '9,955,500đ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _HomeColors.success,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_up, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '+100.0%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'so với tháng trước',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData(
        label: 'Nhập bằng\ngiọng nói',
        icon: Icons.mic_rounded,
        colors: const [Color(0xFFCE3CC5), Color(0xFF7D5CFF)],
      ),
      _ActionData(
        label: 'Quét\nHóa đơn',
        icon: Icons.qr_code_scanner,
        colors: const [Color(0xFF1FB5FF), Color(0xFF3E60FF)],
      ),
      _ActionData(
        label: 'Nhập\nChi tiêu',
        icon: Icons.shopping_cart_outlined,
        colors: const [Color(0xFFFF8A34), Color(0xFFFF5F27)],
      ),
      _ActionData(
        label: 'Nhập\nThu nhập',
        icon: Icons.account_balance_wallet_outlined,
        colors: const [Color(0xFF12D08E), Color(0xFF11B86A)],
      ),
      _ActionData(
        label: 'Quản lý\nDanh mục',
        icon: Icons.settings,
        colors: const [Color(0xFF7A5CFF), Color(0xFF4F8DFF)],
      ),
      _ActionData(
        label: 'Chuyển\ntiền',
        icon: Icons.swap_horiz,
        colors: const [Color(0xFF6E63FF), Color(0xFF4B4FF5)],
      ),
      _ActionData(
        label: 'Sổ Nợ',
        icon: Icons.receipt_long,
        colors: const [Color(0xFFFFA630), Color(0xFFFF7C1F)],
        badge: 'BETA',
      ),
      _ActionData(
        label: 'Giao dịch\nđịnh kỳ',
        icon: Icons.autorenew,
        colors: const [Color(0xFF9D6BFF), Color(0xFF6F5CFF)],
        badge: 'BETA',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return _ActionItem(data: action);
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _MiniSummaryCard(
            title: 'Chi phí',
            subtitle: 'Hôm nay',
            amount: '45,000đ',
            amountColor: _HomeColors.danger,
            icon: Icons.trending_down,
            iconBg: Color(0xFF3B1F2A),
            iconColor: _HomeColors.danger,
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: _MiniSummaryCard(
            title: 'Thu nhập',
            subtitle: 'Hôm nay',
            amount: '10,000,500đ',
            amountColor: _HomeColors.success,
            icon: Icons.trending_up,
            iconBg: Color(0xFF20392E),
            iconColor: _HomeColors.success,
          ),
        ),
      ],
    );
  }
}

class _MiniSummaryCard extends StatelessWidget {
  const _MiniSummaryCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: _HomeColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _HomeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _HomeColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _HomeColors.textMuted,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: amountColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _GoalsSection extends StatelessWidget {
  const _GoalsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Mục tiêu',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _HomeColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _HomeColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _HomeColors.border),
              ),
              child: const Icon(Icons.add, color: _HomeColors.textPrimary, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: _HomeColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _HomeColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _HomeColors.cardAccent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.flag, color: _HomeColors.textPrimary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mục tiêu tiết kiệm',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _HomeColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bắt đầu từ 2,000,000đ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _HomeColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _HomeColors.textMuted),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeBottomNav extends StatelessWidget {
  const _HomeBottomNav();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
        decoration: const BoxDecoration(
          color: _HomeColors.navBar,
          border: Border(top: BorderSide(color: _HomeColors.navBorder)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavItem(label: 'Tổng quan', icon: Icons.home_filled, active: true),
            _NavItem(label: 'Lịch sử', icon: Icons.event_note_outlined),
            _PrimaryNavButton(),
            _NavItem(label: 'Thống kê', icon: Icons.bar_chart_rounded),
            _NavItem(label: 'Cài đặt', icon: Icons.settings_outlined),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    this.active = false,
  });

  final String label;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? _HomeColors.primary : _HomeColors.textMuted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _PrimaryNavButton extends StatelessWidget {
  const _PrimaryNavButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF2F8CFF), Color(0xFF1E6CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.data});

  final _ActionData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: data.colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: data.colors.first.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(data.icon, color: Colors.white, size: 24),
            ),
            if (data.badge != null)
              Positioned(
                top: -6,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _HomeColors.badge,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    data.badge!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _HomeColors.badgeText,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          data.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _HomeColors.textPrimary,
                fontSize: 11,
                height: 1.2,
              ),
        ),
      ],
    );
  }
}

class _ActionData {
  const _ActionData({
    required this.label,
    required this.icon,
    required this.colors,
    this.badge,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final String? badge;
}

class _DiagonalLinesPainter extends CustomPainter {
  _DiagonalLinesPainter({required this.color, this.spacing = 16});

  final Color color;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    for (double x = -size.height; x < size.width; x += spacing) {
      final start = Offset(x, size.height);
      final end = Offset(x + size.height, 0);
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalLinesPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.spacing != spacing;
  }
}

class _HomeColors {
  static const Color background = Color(0xFF0B1020);
  static const Color surface = Color(0xFF151B2D);
  static const Color border = Color(0xFF222A3D);
  static const Color navBar = Color(0xFF10182B);
  static const Color navBorder = Color(0xFF1B2336);
  static const Color textPrimary = Color(0xFFF5F7FF);
  static const Color textMuted = Color(0xFF8B95B9);
  static const Color primary = Color(0xFF2F8CFF);
  static const Color success = Color(0xFF2CD07E);
  static const Color danger = Color(0xFFFF5B5B);
  static const Color badge = Color(0xFFFFB423);
  static const Color badgeText = Color(0xFF2A1A00);
  static const Color cardAccent = Color(0xFF1D2335);
}
