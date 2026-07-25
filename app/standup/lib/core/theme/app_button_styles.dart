import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppButtonStyles {
  AppButtonStyles._();

  static final ButtonStyle success = ElevatedButton.styleFrom(
    backgroundColor: AppColors.success,
    foregroundColor: AppColors.white,
    elevation: 0,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );

  static final ButtonStyle destructive = ElevatedButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: AppColors.white,
    elevation: 0,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );

  static final ButtonStyle warningOutlined = OutlinedButton.styleFrom(
    foregroundColor: AppColors.actionOrange,
    side: const BorderSide(color: AppColors.actionOrange),
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );

  /// Compact sizing for row actions (timer, status). Merge with a semantic
  /// style via `style.merge(AppButtonStyles.compact)` when needed.
  static final ButtonStyle compact = ButtonStyle(
    minimumSize: WidgetStateProperty.all(const Size(0, 44)),
    padding: WidgetStateProperty.all(
      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    textStyle: WidgetStateProperty.all(
      const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static final ButtonStyle compactSuccess = success.merge(compact);

  static final ButtonStyle compactDestructive = destructive.merge(compact);

  static final ButtonStyle compactWarningOutlined =
      warningOutlined.merge(compact);

  static final ButtonStyle compactOutlined = OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.primary),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ).merge(compact);

  static final ButtonStyle compactPrimary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ).merge(compact);
}
