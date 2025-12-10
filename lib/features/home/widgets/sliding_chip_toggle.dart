import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class SlidingChipToggle extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const SlidingChipToggle({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[800] : Colors.grey[200];
    final selectedColor = isDark ? theme.cardColor : Colors.white;
    final unselectedIconColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Material(
      color: Colors.transparent,
      child: Container(
        height: 45,
        width: screenWidth * 0.6,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: selectedIndex == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                _buildOption(
                  context,
                  title: AppLocalizations.of(context).translate('explore'),
                  icon: Icons.explore,
                  index: 0,
                  isSelected: selectedIndex == 0,
                  primaryColor: primaryColor,
                  unselectedColor: unselectedIconColor ?? Colors.grey,
                ),
                _buildOption(
                  context,
                  title: AppLocalizations.of(context).translate('near_me'),
                  icon: Icons.near_me,
                  index: 1,
                  isSelected: selectedIndex == 1,
                  primaryColor: primaryColor,
                  unselectedColor: unselectedIconColor ?? Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required int index,
    required bool isSelected,
    required Color primaryColor,
    required Color unselectedColor,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () => onTap(index),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? primaryColor : unselectedColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? primaryColor : unselectedColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
