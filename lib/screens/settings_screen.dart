import 'package:flutter/material.dart';
import '../services/history_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyService = HistoryService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        children: [
          // App Info Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'О приложении',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                _buildSettingTile(
                  context,
                  icon: Icons.info_outline,
                  title: 'Версия',
                  subtitle: '1.0.0',
                  onTap: null,
                ),
                _buildSettingTile(
                  context,
                  icon: Icons.description_outlined,
                  title: 'Лицензия',
                  subtitle: 'MIT License',
                  onTap: null,
                ),
              ],
            ),
          ),
          const Divider(),
          // Data Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Данные',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                _buildSettingTile(
                  context,
                  icon: Icons.history,
                  title: 'История сканирований',
                  subtitle: '${historyService.history.length} записей',
                  onTap: null,
                ),
                _buildSettingTile(
                  context,
                  icon: Icons.delete_outline,
                  title: 'Очистить историю',
                  subtitle: 'Удалить все записи',
                  onTap: () => _showClearHistoryDialog(context),
                  textColor: Colors.red,
                ),
              ],
            ),
          ),
          const Divider(),
          // Support Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Поддержка',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                _buildSettingTile(
                  context,
                  icon: Icons.help_outline,
                  title: 'Помощь',
                  subtitle: 'Часто задаваемые вопросы',
                  onTap: () {
                    _showHelpDialog(context);
                  },
                ),
                _buildSettingTile(
                  context,
                  icon: Icons.feedback_outlined,
                  title: 'Обратная связь',
                  subtitle: 'Отправить отзыв',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Спасибо за ваш отзыв!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
      enabled: onTap != null,
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить историю?'),
        content: const Text(
          'Все записи истории будут удалены. Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              HistoryService().clearHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('История очищена'),
                ),
              );
            },
            child: const Text(
              'Очистить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Помощь'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Как использовать:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Нажмите "Начать сканирование"'),
              Text('2. Наведите камеру на QR-код'),
              Text('3. Дождитесь автоматического распознавания'),
              SizedBox(height: 16),
              Text(
                'Советы:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Убедитесь, что QR-код хорошо освещен'),
              Text('• Держите устройство стабильно'),
              Text('• QR-код должен быть в фокусе камеры'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}

