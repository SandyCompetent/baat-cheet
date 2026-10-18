import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Severity levels for [AppLogger].
enum LogLevel { debug, info, warning, error }

/// Centralized, dependency-free logging for ChatBud.
///
/// Replaces scattered silent `catch (_) {}` blocks so failures are observable
/// instead of invisible. In debug builds, messages are printed via
/// `dart:developer` (visible in the IDE/DevTools logging view). In release
/// builds, debug/info logs are suppressed while warnings and errors are routed
/// to [errorReporter] when one is registered.
///
/// ## Wiring a crash reporter (e.g. Firebase Crashlytics)
/// This class deliberately has **no** Crashlytics dependency so the build stays
/// green without platform configuration. To forward errors once Crashlytics is
/// configured for the project, register a reporter at startup:
///
/// ```dart
/// AppLogger.errorReporter = (message, error, stackTrace, {fatal = false}) {
///   FirebaseCrashlytics.instance.recordError(
///     error ?? message, stackTrace, reason: message, fatal: fatal,
///   );
/// };
/// ```
class AppLogger {
  const AppLogger._();

  /// Optional sink for warnings/errors (e.g. Crashlytics). No-op until set.
  static void Function(
    String message,
    Object? error,
    StackTrace? stackTrace, {
    bool fatal,
  })? errorReporter;

  /// Minimum level actually emitted. Defaults to [LogLevel.debug] in debug
  /// builds and [LogLevel.warning] in release builds.
  static LogLevel minLevel = kReleaseMode ? LogLevel.warning : LogLevel.debug;

  static void d(String message, {String? tag}) =>
      _log(LogLevel.debug, message, tag: tag);

  static void i(String message, {String? tag}) =>
      _log(LogLevel.info, message, tag: tag);

  static void w(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);

  static void e(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    bool fatal = false,
  }) =>
      _log(LogLevel.error, message,
          tag: tag, error: error, stackTrace: stackTrace, fatal: fatal);

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    bool fatal = false,
  }) {
    if (level.index < minLevel.index) return;

    final label = tag == null ? 'ChatBud' : 'ChatBud/$tag';
    developer.log(
      message,
      name: label,
      level: _levelValue(level),
      error: error,
      stackTrace: stackTrace,
    );

    if (level.index >= LogLevel.warning.index && errorReporter != null) {
      try {
        errorReporter!(message, error, stackTrace, fatal: fatal);
      } catch (_) {
        // Never let the reporter itself throw into the caller.
      }
    }
  }

  static int _levelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}
