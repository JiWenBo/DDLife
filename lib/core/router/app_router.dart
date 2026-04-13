
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/home/home_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/main/main_screen.dart';
import '../../features/scanner/scanner_screen.dart';
import '../../features/stats/stats_screen.dart';
import '../../features/entry/book_entry_screen.dart';

part 'app_router.g.dart';

// 用于获取 GoRouter 实例的 Provider
@riverpod
GoRouter goRouter(GoRouterRef ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      // 底部导航 ShellRoute
      ShellRoute(
        builder: (context, state, child) {
          return MainScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/library',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LibraryScreen(),
            ),
          ),
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/stats',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: StatsScreen(),
            ),
          ),
        ],
      ),
      // 全屏页面路由 (不包含底部导航)
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: '/entry',
        builder: (context, state) => const BookEntryScreen(),
      ),
    ],
  );
}
