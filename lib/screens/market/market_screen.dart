import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/market_data.dart';
import '../../state/app_status.dart';
import '../../state/locale_controller.dart';
import '../../state/market_controller.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_surfaces.dart';
import '../../widgets/market/market_trend_chart.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final _controller = MarketController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_refresh);
    _bootstrap();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
    await _controller.load();
    if (_controller.rates.isEmpty && _controller.marketEnabled) {
      await _controller.refresh();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final ok = await _controller.refresh();
    if (!mounted) return;
    if (ok) {
      AppSnackbar.show(context, 'Market rates updated.');
    } else if (_controller.refreshError != null) {
      AppSnackbar.show(context, _controller.refreshError!, isError: true);
    }
  }

  String _trendLabel(List<MarketHistoryPoint> points) {
    if (points.length < 2) return context.l10n.emDash;
    final first = points.first.value;
    final last = points.last.value;
    if (last > first) return 'Up';
    if (last < first) return 'Down';
    return 'Flat';
  }

  AppBadgeType _trendType(List<MarketHistoryPoint> points) {
    if (points.length < 2) return AppBadgeType.neutral;
    final first = points.first.value;
    final last = points.last.value;
    if (last > first) return AppBadgeType.success;
    if (last < first) return AppBadgeType.error;
    return AppBadgeType.neutral;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final desktop = AppResponsive.isDesktop(context);

    return AppScaffold(
      title: l10n.marketTitle,
      route: AppRoutes.market,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            AppSectionHeader(
              title: l10n.exchangeRates,
              action: AppButton(
                label: l10n.refresh,
                expanded: false,
                icon: Icons.refresh,
                isLoading: _controller.isRefreshing,
                onPressed: _onRefresh,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Wrap(
              spacing: AppSizes.md,
              runSpacing: AppSizes.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _controller.lastUpdated == null
                      ? '${l10n.lastUpdated}: ${l10n.emDash}'
                      : '${l10n.lastUpdated}: ${Formatters.dateTime(_controller.lastUpdated)}',
                  style: AppTextStyles.caption,
                ),
                if (_controller.source != null)
                  AppBadge(label: _controller.source!, type: AppBadgeType.info),
                AppBadge(
                  label: 'Base ${_controller.baseCurrency}',
                  type: AppBadgeType.neutral,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            if (_controller.isLoading && _controller.rates.isEmpty)
              AppLoading(message: l10n.loadingMarket)
            else if (_controller.status.hasError && _controller.rates.isEmpty)
              AppErrorState(
                message: _controller.errorMessage,
                onRetry: _bootstrap,
              )
            else if (!_controller.marketEnabled ||
                (_controller.status.isEmpty && _controller.rates.isEmpty))
              AppEmptyState(
                title: l10n.noMarketData,
                message:
                    _controller.errorMessage ??
                    (!_controller.marketEnabled
                        ? l10n.marketDisabled
                        : l10n.noMarketDataMessage),
                actionLabel: _controller.marketEnabled ? l10n.refresh : null,
                onAction: _controller.marketEnabled ? _onRefresh : null,
              )
            else ...[
              if (desktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _ratesCard(desktop: true)),
                    const SizedBox(width: AppSizes.lg),
                    Expanded(flex: 2, child: _historyCard()),
                  ],
                )
              else ...[
                _ratesCard(desktop: false),
                const SizedBox(height: AppSizes.lg),
                _historyCard(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _ratesCard({required bool desktop}) {
    final l10n = context.l10n;
    final rates = _controller.rates;
    if (desktop) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.exchangeRates, style: AppTextStyles.label),
            const SizedBox(height: AppSizes.md),
            const Divider(height: 1),
            for (final rate in rates) ...[
              InkWell(
                onTap: () => _controller.selectSymbol(rate.symbol),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          rate.symbol,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight:
                                rate.symbol == _controller.selectedSymbol
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      Expanded(child: Text(rate.value.toStringAsFixed(4))),
                      Expanded(
                        child: Text(
                          Formatters.dateTime(rate.fetchedAt),
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final rate in rates)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.md),
            child: AppCard(
              onTap: () => _controller.selectSymbol(rate.symbol),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rate.symbol, style: AppTextStyles.headingSmall),
                        Text(
                          '1 ${rate.baseCurrency} = ${rate.value.toStringAsFixed(4)} ${rate.currency}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: rate.symbol == _controller.selectedSymbol
                        ? AppColors.info
                        : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _historyCard() {
    final l10n = context.l10n;
    final symbol = _controller.selectedSymbol ?? l10n.emDash;
    final points = _controller.historyPoints;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.marketHistory} · $symbol',
                  style: AppTextStyles.label,
                ),
              ),
              AppBadge(label: _trendLabel(points), type: _trendType(points)),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          MarketTrendChart(points: points),
          const SizedBox(height: AppSizes.md),
          if (points.isEmpty)
            Text(l10n.emptyTitle, style: AppTextStyles.bodySmall)
          else
            for (final point in points.reversed.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        Formatters.dateTime(point.fetchedAt),
                        style: AppTextStyles.caption,
                      ),
                    ),
                    Text(point.value.toStringAsFixed(4)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
