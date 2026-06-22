import 'dart:async';

import 'app_realtime_coordinator.dart';

/// Wires [AppRealtimeCoordinator] (+ optional extra streams) and optional
/// polling to a tab screen's reload callback.
class TabAutoRefresh {
  TabAutoRefresh({
    required this.onRefresh,
    required this.isTabActive,
    this.pollInterval = const Duration(seconds: 15),
    this.refreshWhenInactive = true,
  });

  final Future<void> Function({bool showLoader}) onRefresh;
  final bool Function() isTabActive;
  final Duration pollInterval;

  /// When true, push/global refresh runs even if the tab is hidden (IndexedStack).
  final bool refreshWhenInactive;

  final List<StreamSubscription<void>> _subscriptions = [];
  Timer? _pollTimer;

  void attach({List<Stream<void>> extraStreams = const []}) {
    AppRealtimeCoordinator.instance.ensureStarted();

    final streams = <Stream<void>>[
      AppRealtimeCoordinator.instance.onRefresh,
      ...extraStreams,
    ];

    for (final stream in streams) {
      _subscriptions.add(
        stream.listen((_) => _trigger(fromPoll: false)),
      );
    }

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) {
      _trigger(fromPoll: true);
    });
  }

  void _trigger({required bool fromPoll}) {
    if (fromPoll) {
      if (!isTabActive()) return;
    } else if (!refreshWhenInactive && !isTabActive()) {
      return;
    }

    unawaited(onRefresh(showLoader: false));
  }

  void onTabBecameActive() {
    unawaited(onRefresh(showLoader: false));
  }

  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}
