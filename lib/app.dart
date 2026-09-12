import 'package:flutter/material.dart';
import 'screens/downloads_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'services/download_queue_service.dart';
import 'services/settings_service.dart';

class RLClickerApp extends StatefulWidget {
  final SettingsService settingsService;
  final DownloadQueueService queueService;

  const RLClickerApp({
    super.key,
    required this.settingsService,
    required this.queueService,
  });

  @override
  State<RLClickerApp> createState() => _RLClickerAppState();
}

class _RLClickerAppState extends State<RLClickerApp> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settingsService,
      builder: (context, _) {
        final isDark = widget.settingsService.isDarkMode;

        return MaterialApp(
          title: 'RL Clicker',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorSchemeSeed:
                const Color(0xFF833AB4), // Instagram-inspired accent
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: const Color(0xFFC13584),
            scaffoldBackgroundColor: const Color(0xFF121212),
          ),
          home: Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: [
                HomeScreen(
                  queueService: widget.queueService,
                  settingsService: widget.settingsService,
                  onNavigateToDownloads: () {
                    setState(() => _currentIndex = 1);
                  },
                ),
                DownloadsScreen(
                  queueService: widget.queueService,
                ),
                SettingsScreen(
                  settingsService: widget.settingsService,
                ),
              ],
            ),
            bottomNavigationBar: ListenableBuilder(
              listenable: widget.queueService,
              builder: (context, _) {
                final activeCount = widget.queueService.activeDownloadCount;

                return NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() => _currentIndex = index);
                  },
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'Ana Sayfa',
                    ),
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible: activeCount > 0,
                        label: Text('$activeCount'),
                        child: const Icon(Icons.download_outlined),
                      ),
                      selectedIcon: Badge(
                        isLabelVisible: activeCount > 0,
                        label: Text('$activeCount'),
                        child: const Icon(Icons.download_rounded),
                      ),
                      label: 'İndirmeler',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings_rounded),
                      label: 'Ayarlar',
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
