import 'package:flutter/material.dart';
import 'package:mobile_banking_app/app/app_text.dart';

class ItemButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color? color;

  const ItemButton({
    super.key,
    required this.text,
    required this.icon,
    this.onTap,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Colors.green.shade600;

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(icon, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              text,
              style: AppText.bodySmall.copyWith(
                color: themeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
