import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/brand_registry.dart';
import '../../../core/extensions/build_context_extensions.dart';

/// Three-tier brand logo widget:
/// 1. Local SVG asset (instant, offline)
/// 2. Brandfetch CDN (cached after first fetch)
/// 3. Colored initial circle (fallback)
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    required this.brand,
    this.size = AppSizes.iconLg,
  });

  final BrandInfo brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Tier 1: Local SVG
    if (brand.assetPath != null) {
      return ClipOval(
        child: SvgPicture.asset(
          brand.assetPath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholderBuilder: (_) => _InitialCircle(brand: brand, size: size),
        ),
      );
    }

    // Tier 2: Brandfetch CDN
    if (brand.domain != null) {
      final url = 'https://cdn.brandfetch.io/${brand.domain}/w/128/h/128/icon';
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _InitialCircle(brand: brand, size: size),
          errorWidget: (_, __, ___) => _InitialCircle(brand: brand, size: size),
        ),
      );
    }

    // Tier 3: Colored initial circle
    return _InitialCircle(brand: brand, size: size);
  }
}

/// Colored circle with brand initial — the ultimate fallback.
class _InitialCircle extends StatelessWidget {
  const _InitialCircle({required this.brand, required this.size});

  final BrandInfo brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: brand.color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        brand.displayInitial,
        style: context.textStyles.labelSmall?.copyWith(
          color: ThemeData.estimateBrightnessForColor(brand.color) ==
                  Brightness.dark
              ? AppColors.white
              : AppColors.black,
          fontWeight: FontWeight.w800,
          fontSize: brand.displayInitial.length > 2
              ? AppSizes.brandIconFontSmall
              : AppSizes.brandIconFontLarge,
        ),
      ),
    );
  }
}
