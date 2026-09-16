import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/floating_art.dart';

/// Splash slider — a single static hero introducing the app, shown for
/// [_holdDuration] before automatically handing off into Home. No manual
/// CTA: the whole launch sequence (white frame → brand splash → this
/// slider) is fully automatic.
class SplashSliderScreen extends StatefulWidget {
  const SplashSliderScreen({super.key});

  @override
  State<SplashSliderScreen> createState() => _SplashSliderScreenState();
}

class _SplashSliderScreenState extends State<SplashSliderScreen> {
  static const _holdDuration = Duration(milliseconds: 2600);

  bool _navigating = false;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _navTimer = Timer(_holdDuration, _goHome);
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  void _goHome() {
    if (_navigating) return;
    _navigating = true;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final contentWidth = size.width > 520 ? 480.0 : size.width;

    return Scaffold(
      backgroundColor: AppColors.splashBackground.first,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.splashBackground,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            width: size.width * 0.6,
            child: Image.asset(
              'assets/images/blob_top_left.png',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            width: size.width * 0.6,
            child: Transform.rotate(
              angle: 3.14159,
              child: Image.asset(
                'assets/images/blob_top_left.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppTextStyles.fig(24),
                        AppTextStyles.fig(10),
                        AppTextStyles.fig(24),
                        0,
                      ),
                      child: Image.asset(
                        'assets/images/logo_full.png',
                        width: contentWidth * 0.48,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppTextStyles.fig(24),
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(height: AppTextStyles.fig(10)),
                                  Text(
                                    'Rent Smart.',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.display(
                                      figmaSize: 29,
                                      weight: FontWeight.w800,
                                      color: AppColors.navy,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  Text(
                                    'Live Easy.',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.display(
                                      figmaSize: 27,
                                      weight: FontWeight.w700,
                                      color: AppColors.purple,
                                    ),
                                  ),
                                  SizedBox(height: AppTextStyles.fig(12)),
                                  Text(
                                    'AC, washing machines, refrigerators and '
                                    'more — one app for every premium '
                                    'appliance.',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.of(
                                      figmaSize: 14,
                                      weight: FontWeight.w400,
                                      color: AppColors.textGray,
                                    ),
                                  ),
                                  SizedBox(height: AppTextStyles.fig(22)),
                                  const _FeatureRow(),
                                  SizedBox(height: AppTextStyles.fig(46)),
                                  FloatingProductArt(
                                    assetPath: 'assets/images/main_splash.png',
                                    width:
                                        size.width - AppTextStyles.fig(24) * 2,
                                  ),
                                  SizedBox(height: AppTextStyles.fig(26)),
                                  Text(
                                    'Smart Renting, Better Living',
                                    style: AppTextStyles.display(
                                      figmaSize: 18,
                                      weight: FontWeight.w700,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                  SizedBox(height: AppTextStyles.fig(12)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: AppTextStyles.fig(34)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Static "Free Delivery / Free Installation / Service & Maintenance" badge
/// row.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow();

  static const _items = [
    (
      icon: Icons.local_shipping_rounded,
      label: 'Free\nDelivery',
      weight: FontWeight.w700,
      figmaLabelSize: 13.0,
    ),
    (
      icon: Icons.build_rounded,
      label: 'Free\nInstallation',
      weight: FontWeight.w400,
      figmaLabelSize: 13.0,
    ),
    (
      icon: Icons.verified_user_rounded,
      label: 'Service &\nMaintenance',
      weight: FontWeight.w700,
      figmaLabelSize: 12.0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppTextStyles.fig(18),
        horizontal: AppTextStyles.fig(10),
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCardPurple,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppTextStyles.fig(35)),
      ),
      child: Row(
        children: [
          for (final item in _items)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.bgCardPurple,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, size: 20, color: AppColors.purple),
                  ),
                  SizedBox(height: 40 * 0.14),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.of(
                        figmaSize: item.figmaLabelSize,
                        weight: item.weight,
                        color: AppColors.textGray,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
