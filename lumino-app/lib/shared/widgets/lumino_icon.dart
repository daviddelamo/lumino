import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _iconAssets = {
  'circle':  'assets/icons/icon_circle.svg',
  'run':     'assets/icons/icon_run.svg',
  'yoga':    'assets/icons/icon_yoga.svg',
  'book':    'assets/icons/icon_book.svg',
  'food':    'assets/icons/icon_food.svg',
  'water':   'assets/icons/icon_water.svg',
  'brain':   'assets/icons/icon_brain.svg',
  'pencil':  'assets/icons/icon_pencil.svg',
  'sun':     'assets/icons/icon_sun.svg',
  'moon':    'assets/icons/icon_moon.svg',
  'check':   'assets/icons/icon_check.svg',
  'work':    'assets/icons/icon_work.svg',
};

class LuminoIcon extends StatelessWidget {
  final String iconId;
  final double size;
  final Color? color;

  const LuminoIcon(this.iconId, {super.key, this.size = 20, this.color});

  @override
  Widget build(BuildContext context) {
    final path = _iconAssets[iconId] ?? _iconAssets['circle']!;
    return SvgPicture.asset(
      path,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
