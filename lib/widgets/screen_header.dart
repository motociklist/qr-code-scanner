import 'package:flutter/material.dart';

class ScreenHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onClose;

  const ScreenHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (onClose != null)
            IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                ),
                child: const Icon(Icons.close, color: Colors.black),
              ),
              onPressed: onClose,
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: onClose != null ? TextAlign.left : TextAlign.center,
            ),
          ),
          trailing ?? const SizedBox(width: 48),
        ],
      ),
    );
  }
}

