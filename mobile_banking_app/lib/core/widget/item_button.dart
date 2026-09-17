import 'package:flutter/material.dart';
import 'package:mobile_banking_app/app/app_text.dart';

class ItemButton extends StatefulWidget {
  final String text;
  final IconData icon;
  const ItemButton({super.key, required this.text, required this.icon});

  @override
  State<ItemButton> createState() => _ItemButtonState();
}

class _ItemButtonState extends State<ItemButton> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            shape: BoxShape.circle,
          ),
          child: Icon(widget.icon, color: Colors.white),
        ),
        Text(
          widget.text,
          style: AppText.bodySmall.copyWith(color: Colors.green.shade600),
        ),
      ],
    );
  }
}
