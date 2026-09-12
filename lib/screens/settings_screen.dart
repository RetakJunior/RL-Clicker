import 'dart:io';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsService settingsService;

  const SettingsScreen({
    super.key,
    required this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: settingsService,
      builder: (context, _) {
        final folderDisplay = Platform.isLinux
            ? '~/Downloads/RL_Clicker'
            : 'Movies/RL Clicker (Galeri / Medya Depolama)';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Ayarlar'),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Concurrent Downloads Setting
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.speed_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Eşzamanlı İndirme (Concurrent)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Aynı anda indirilecek maksimum video sayısı.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 1, label: Text('1')),
                          ButtonSegment(value: 2, label: Text('2 (Önerilen)')),
                          ButtonSegment(value: 3, label: Text('3')),
                          ButtonSegment(value: 4, label: Text('4')),
                        ],
                        selected: {settingsService.concurrentDownloads},
                        onSelectionChanged: (set) {
                          if (set.isNotEmpty) {
                            settingsService.setConcurrentDownloads(set.first);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Toggles Card
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Otomatik Pano Algılama'),
                      subtitle: const Text(
                        'Uygulama açıldığında panodaki Instagram linklerini öner.',
                      ),
                      value: settingsService.autoClipboard,
                      onChanged: settingsService.setAutoClipboard,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Bildirimler'),
                      subtitle: const Text(
                        'İndirme tamamlandığında sistem bildirimi göster.',
                      ),
                      value: settingsService.notificationsEnabled,
                      onChanged: settingsService.setNotificationsEnabled,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Karanlık Mod'),
                      subtitle: const Text('Koyu tema görünümünü kullan.'),
                      value: settingsService.isDarkMode,
                      onChanged: settingsService.setDarkMode,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Yalnızca Wi-Fi'),
                      subtitle: const Text(
                        'Mobil veri kullanımını kısıtla.',
                      ),
                      value: settingsService.wifiOnly,
                      onChanged: settingsService.setWifiOnly,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Storage Path Information
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.folder_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Kayıt Konumu'),
                  subtitle: Text(folderDisplay),
                ),
              ),

              const SizedBox(height: 16),

              // Privacy & Info Card
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.security_rounded,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Gizlilik ve Güvenlik Güvencesi',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Instagram şifreniz istenmez ve saklanmaz.\n'
                        '• Çerez (cookie) veya oturum anahtarı toplanmaz.\n'
                        '• Yalnızca herkese açık ve erişilebilir videolar indirilir.\n'
                        '• DRM veya erişim kısıtlamaları aşılmaz.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'RL Clicker v1.0.0',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
