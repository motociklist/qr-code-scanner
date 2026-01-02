import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ActionButtons extends StatelessWidget {
  final String content;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  const ActionButtons({
    super.key,
    required this.content,
    this.onCopy,
    this.onShare,
  });

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    onCopy?.call();
  }

  Future<void> _shareContent() async {
    await Share.share(content);
    onShare?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          context: context,
          icon: Icons.copy,
          onPressed: () => _copyToClipboard(context),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          context: context,
          icon: Icons.share,
          onPressed: _shareContent,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
        ),
        child: Icon(
          icon,
          size: 16,
          color: Colors.grey[700],
        ),
      ),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}

