import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
          iconPath: 'assets/images/history-page/copy.svg',
          onPressed: () => _copyToClipboard(context),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          context: context,
          iconPath: 'assets/images/history-page/shared.svg',
          onPressed: _shareContent,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String iconPath,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFF6F7FA),
        ),
        child: Center(
          child: SvgPicture.asset(
            iconPath,
            width: 12,
            height: 12,
            colorFilter: const ColorFilter.mode(
              Color(0xFF666666),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

