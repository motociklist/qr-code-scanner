import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_styles.dart';

class StandardHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onTrailingTap;

  const StandardHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.white,
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: AppStyles.title3,
          ),
          if (trailing != null)
            GestureDetector(
              onTap: onTrailingTap,
              child: trailing!,
            ),
        ],
      ),
    );
  }

  /// Создает стандартную кнопку-кружок с иконкой
  static Widget createIconButton({
    required String iconPath,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? iconColor,
    double? iconWidth,
    double? iconHeight,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? const Color(0xFFF6F7FA),
      ),
      child: Center(
        child: SvgPicture.asset(
          iconPath,
          width: iconWidth ?? 16,
          height: iconHeight ?? 16,
          colorFilter: ColorFilter.mode(
            iconColor ?? Colors.black,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

