import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../theme.dart';
import 'paywall_config.dart';
import 'paywall_provider.dart';

class PaywallSheet extends ConsumerStatefulWidget {
  const PaywallSheet({super.key});

  @override
  ConsumerState<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends ConsumerState<PaywallSheet> {
  String _selectedId = kYearlyId;
  bool _purchasing = false;
  List<Package>? _packages;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      final pkgs = offerings.current?.availablePackages ?? [];
      if (mounted) setState(() => _packages = pkgs);
    } catch (_) {
      // No offerings available in sandbox/test — packages remain null
    }
  }

  Package? get _selectedPackage => _packages?.where(
        (p) => p.storeProduct.identifier == _selectedId,
      ).firstOrNull;

  Future<void> _purchase() async {
    final pkg = _selectedPackage;
    if (pkg == null) return;
    setState(() => _purchasing = true);
    try {
      await Purchases.purchasePackage(pkg);
      ref.read(optimisticPremiumProvider.notifier).state = true;
      if (mounted) Navigator.of(context).pop();
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code != PurchasesErrorCode.purchaseCancelledError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Purchase failed')),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    try {
      final info = await Purchases.restorePurchases();
      final isActive =
          info.entitlements.all[kEntitlementId]?.isActive ?? false;
      if (isActive) {
        ref.read(optimisticPremiumProvider.notifier).state = true;
        if (mounted) Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active subscription found')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }

  String _priceFor(String productId) {
    if (_packages == null) return '...';
    final pkg = _packages!
        .where((p) => p.storeProduct.identifier == productId)
        .firstOrNull;
    return pkg?.storeProduct.priceString ?? '—';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: LuminoTheme.bg(context),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Center(
                child: Text('⭐ Lumino Premium',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Unlock everything to build your best life',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),
              const _FeatureBullet(
                  icon: Icons.repeat_rounded,
                  text: 'Unlimited habits (free tier: 5)'),
              const SizedBox(height: 12),
              const _FeatureBullet(
                  icon: Icons.library_music_outlined,
                  text: 'Full content library — meditations, soundscapes, affirmations'),
              const SizedBox(height: 12),
              const _FeatureBullet(
                  icon: Icons.bar_chart_rounded,
                  text: 'Year & all-time statistics'),
              const SizedBox(height: 32),
              _PlanCard(
                label: 'Monthly',
                price: _priceFor(kMonthlyId),
                productId: kMonthlyId,
                selected: _selectedId == kMonthlyId,
                onTap: () => setState(() => _selectedId = kMonthlyId),
              ),
              const SizedBox(height: 12),
              _PlanCard(
                label: 'Yearly',
                price: _priceFor(kYearlyId),
                productId: kYearlyId,
                selected: _selectedId == kYearlyId,
                badge: 'Best value',
                onTap: () => setState(() => _selectedId = kYearlyId),
              ),
              const SizedBox(height: 12),
              _PlanCard(
                label: 'Lifetime',
                price: _priceFor(kLifetimeId),
                productId: kLifetimeId,
                selected: _selectedId == kLifetimeId,
                onTap: () => setState(() => _selectedId = kLifetimeId),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _purchasing ? null : _purchase,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _purchasing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Continue with ${_labelFor(_selectedId)}'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _restore,
                    child: const Text('Restore purchases'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _labelFor(String id) => switch (id) {
        kMonthlyId  => 'Monthly',
        kYearlyId   => 'Yearly',
        kLifetimeId => 'Lifetime',
        _           => 'Plan',
      };
}

class _FeatureBullet extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureBullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: LuminoTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String label;
  final String price;
  final String productId;
  final bool selected;
  final String? badge;
  final VoidCallback onTap;

  const _PlanCard({
    required this.label,
    required this.price,
    required this.productId,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? LuminoTheme.primaryColor.withValues(alpha: 0.1)
              : LuminoTheme.surface(context),
          border: Border.all(
            color: selected
                ? LuminoTheme.primaryColor
                : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: LuminoTheme.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(badge!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(price,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
