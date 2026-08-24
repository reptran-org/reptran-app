import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/core/network/api_client.dart';

/// -------------------------------
/// SERVICE
/// -------------------------------
class TriggerService {
  final Dio _dio = ApiClient().dio;
  static const _kAuthTokenKey = 'auth_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> getToken() => _storage.read(key: _kAuthTokenKey);

  Future<void> _attachToken() async {
    final token = await getToken();
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<Map<String, dynamic>> getMyTrigger() async {
    await _attachToken();
    final res = await _dio.get('/triggers/me');
    return (res.data['result'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> updateMyTrigger({
    required Map<String, dynamic> payload,
  }) async {
    await _attachToken();
    final res = await _dio.patch('/triggers/me', data: payload);
    return (res.data['result'] as Map).cast<String, dynamic>();
  }
}

/// -------------------------------
/// PAGE
/// -------------------------------
class TriggerSettingsPage extends StatefulWidget {
  const TriggerSettingsPage({super.key});

  @override
  State<TriggerSettingsPage> createState() => _TriggerSettingsPageState();
}

class _TriggerSettingsPageState extends State<TriggerSettingsPage> {
  final TriggerService _triggerService = TriggerService();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  /// preferredWindows: max 2
  List<Map<String, String>> _preferredWindows = [
    {"start": "06:00", "end": "09:00"},
  ];

  String _tone = "supportive";

  Map<String, bool> _channelConfig = {
    "in_app": true,
    "push": true,
    "email": false,
  };

  String? _timezone; // IANA timezone e.g. Asia/Kolkata

  // --- constants ---
  final Map<String, String> _morningWindow = const {
    "start": "06:00",
    "end": "09:00",
  };
  final Map<String, String> _eveningWindow = const {
    "start": "18:00",
    "end": "21:00",
  };

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _syncTimezoneFromDevice();
    await _fetchTrigger();
  }

  Future<void> _syncTimezoneFromDevice() async {
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      _timezone = tzInfo.identifier; // e.g. "Asia/Kolkata"
    } catch (_) {
      // ignore
    }
  }

  Future<void> _fetchTrigger() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final trigger = await _triggerService.getMyTrigger();

      final pw = trigger['preferredWindows'];
      if (pw is List) {
        final parsed = pw
            .map(
              (e) => {
                "start": (e['start'] ?? '').toString(),
                "end": (e['end'] ?? '').toString(),
              },
            )
            .where((w) => w["start"]!.isNotEmpty && w["end"]!.isNotEmpty)
            .take(2)
            .toList();

        if (parsed.isNotEmpty) {
          _preferredWindows = parsed;
        }
      }

      final tone = trigger['tone']?.toString().trim();
      if (tone != null && tone.isNotEmpty) {
        _tone = tone;
      }

      final cc = trigger['channelConfig'];
      if (cc is Map) {
        final map = cc.cast<String, dynamic>();
        _channelConfig = {
          "in_app": map["in_app"] == true,
          "push": map["push"] == true,
          "email": map["email"] == true,
        };
      }

      final backendTz = trigger['timezone']?.toString().trim();
      if (backendTz != null && backendTz.isNotEmpty) {
        _timezone = backendTz;
      }

      // If backend timezone missing but device timezone exists, sync once
      if ((backendTz == null || backendTz.isEmpty) &&
          _timezone != null &&
          _timezone!.isNotEmpty) {
        await _triggerService.updateMyTrigger(payload: {"timezone": _timezone});
      }

      setState(() {
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = "Failed to load trigger settings";
      });
    }
  }

  Future<void> _saveTrigger() async {
    if (_saving) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _syncTimezoneFromDevice();

      final payload = <String, dynamic>{
        "preferredWindows": _preferredWindows
            .take(2)
            .map((w) => {"start": w["start"], "end": w["end"]})
            .toList(),
        "tone": _tone,
        "channelConfig": _channelConfig,
        "timezone": _timezone,
      };

      final updated = await _triggerService.updateMyTrigger(payload: payload);

      final pw = updated['preferredWindows'];
      if (pw is List) {
        _preferredWindows = pw
            .map(
              (e) => {
                "start": (e['start'] ?? '').toString(),
                "end": (e['end'] ?? '').toString(),
              },
            )
            .where((w) => w["start"]!.isNotEmpty && w["end"]!.isNotEmpty)
            .take(2)
            .toList();
      }

      final tone = updated['tone']?.toString().trim();
      if (tone != null && tone.isNotEmpty) _tone = tone;

      final cc = updated['channelConfig'];
      if (cc is Map) {
        final map = cc.cast<String, dynamic>();
        _channelConfig = {
          "in_app": map["in_app"] == true,
          "push": map["push"] == true,
          "email": map["email"] == true,
        };
      }

      final tz = updated['timezone']?.toString().trim();
      if (tz != null && tz.isNotEmpty) _timezone = tz;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Settings saved")),
        );
      }
    } catch (_) {
      setState(() {
        _error = "Failed to save settings";
      });
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  // -------------------------------
  // WINDOWS LOGIC (max 2)
  // -------------------------------

  bool _sameWindow(Map<String, String> a, Map<String, String> b) {
    return a["start"] == b["start"] && a["end"] == b["end"];
  }

  bool _hasWindow(Map<String, String> w) {
    return _preferredWindows.any((x) => _sameWindow(x, w));
  }

  bool get _isMorningSelected => _hasWindow(_morningWindow);
  bool get _isEveningSelected => _hasWindow(_eveningWindow);

  bool get _hasCustomWindow {
    return _preferredWindows.any((w) {
      final isMorning = _sameWindow(w, _morningWindow);
      final isEvening = _sameWindow(w, _eveningWindow);
      return !(isMorning || isEvening);
    });
  }

  Map<String, String>? get _customWindow {
    for (final w in _preferredWindows) {
      final isMorning = _sameWindow(w, _morningWindow);
      final isEvening = _sameWindow(w, _eveningWindow);
      if (!(isMorning || isEvening)) return w;
    }
    return null;
  }

  void _removeWindow(Map<String, String> w) {
    setState(() {
      _preferredWindows =
          _preferredWindows.where((x) => !_sameWindow(x, w)).toList();
    });
  }

  void _removeCustomWindow() {
    final cw = _customWindow;
    if (cw == null) return;
    _removeWindow(cw);
  }

  String _formatTime(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(":");
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: h, minute: m);
  }

  String _prettyTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return hhmm;

    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;

    final isPm = h >= 12;
    final hour12 = (h % 12 == 0) ? 12 : (h % 12);
    final mm = m.toString().padLeft(2, '0');

    return "$hour12:$mm ${isPm ? "PM" : "AM"}";
  }

  Future<int?> _askReplaceWindowIndex() async {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final scheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        String labelFor(Map<String, String> w) {
          if (_sameWindow(w, _morningWindow)) return "Morning (6–9 AM)";
          if (_sameWindow(w, _eveningWindow)) return "Evening (6–9 PM)";
          return "Custom (${_prettyTime(w["start"]!)} – ${_prettyTime(w["end"]!)})";
        }

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadii.xl),
              topRight: Radius.circular(AppRadii.xl),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Replace a time window",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemibold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                "You already have 2 reminder windows. Choose one to replace.",
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (int i = 0; i < _preferredWindows.length; i++) ...[
                GestureDetector(
                  onTap: () => Navigator.pop(context, i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: scheme.outline.withOpacity(0.25),
                      ),
                    ),
                    child: Text(
                      labelFor(_preferredWindows[i]),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: AppTypography.wSemibold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  Future<void> _togglePresetWindow(Map<String, String> preset) async {
    final exists = _hasWindow(preset);

    if (exists) {
      setState(() {
        _preferredWindows =
            _preferredWindows.where((x) => !_sameWindow(x, preset)).toList();
      });
      return;
    }

    // if we have space, just add it
    if (_preferredWindows.length < 2) {
      setState(() {
        _preferredWindows = [..._preferredWindows, preset];
      });
      return;
    }

    // already 2 windows -> ask user what to replace
    final replaceIndex = await _askReplaceWindowIndex();
    if (replaceIndex == null) return;

    setState(() {
      _preferredWindows[replaceIndex] = preset;
    });
  }

  Future<void> _applyCustomWindow(Map<String, String> newWindow) async {
    // if already exists, just replace that custom window
    final cw = _customWindow;
    if (cw != null) {
      final idx = _preferredWindows.indexWhere((w) => _sameWindow(w, cw));
      if (idx != -1) {
        setState(() {
          _preferredWindows[idx] = newWindow;
        });
        return;
      }
    }

    // if space exists, add it
    if (_preferredWindows.length < 2) {
      setState(() {
        _preferredWindows = [..._preferredWindows, newWindow];
      });
      return;
    }

    // already 2 windows -> ask what to replace
    final replaceIndex = await _askReplaceWindowIndex();
    if (replaceIndex == null) return;

    setState(() {
      _preferredWindows[replaceIndex] = newWindow;
    });
  }

  Future<void> _openCustomWindowSheet() async {
    TimeOfDay? start;
    TimeOfDay? end;

    final existing = _customWindow;
    if (existing != null) {
      start = _parseTime(existing["start"]!);
      end = _parseTime(existing["end"]!);
    } else {
      start = const TimeOfDay(hour: 7, minute: 0);
      end = const TimeOfDay(hour: 8, minute: 0);
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final scheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickStart() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: start ?? const TimeOfDay(hour: 7, minute: 0),
              );
              if (picked == null) return;
              setSheetState(() => start = picked);
            }

            Future<void> pickEnd() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: end ??
                    TimeOfDay(
                      hour: ((start?.hour ?? 7) + 1) % 24,
                      minute: start?.minute ?? 0,
                    ),
              );
              if (picked == null) return;
              setSheetState(() => end = picked);
            }

            bool isValid() {
              if (start == null || end == null) return false;
              final s = start!.hour * 60 + start!.minute;
              final e = end!.hour * 60 + end!.minute;
              return e > s;
            }

            Future<void> save() async {
              if (!isValid()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("End time must be after start time"),
                  ),
                );
                return;
              }

              final newWindow = {
                "start": _formatTime(start!),
                "end": _formatTime(end!),
              };

              Navigator.pop(context);

              await _applyCustomWindow(newWindow);
            }

            return Container(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadii.xl),
                  topRight: Radius.circular(AppRadii.xl),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Custom time window",
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: AppTypography.wSemibold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    "Pick a start and end time for your workout reminders.",
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _TimeRow(
                    label: "Start time",
                    value: start != null ? start!.format(context) : "--",
                    onTap: pickStart,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _TimeRow(
                    label: "End time",
                    value: end != null ? end!.format(context) : "--",
                    onTap: pickEnd,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GestureDetector(
                    onTap: save,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Save window",
                        style: textTheme.titleMedium?.copyWith(
                          color: scheme.onSecondary,
                          fontWeight: AppTypography.wSemibold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------------
  // TONE / CHANNELS
  // -------------------------------

  void _selectTone(String tone) {
    setState(() {
      _tone = tone;
    });
  }

  void _toggleChannel(String key, bool value) {
    setState(() {
      _channelConfig = {..._channelConfig, key: value};
    });
  }

  // -------------------------------
  // UI
  // -------------------------------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLight = scheme.brightness == Brightness.light;

    if (_loading) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: scheme.primary),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxl),

                  Text(
                    'Workout Reminders',
                    style: textTheme.headlineSmall!.copyWith(height: 1.2),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Control when and how RepTran nudges you to train.',
                    style: textTheme.bodyMedium!.copyWith(
                      color: scheme.onSurface.withValues(
                        alpha: AppOpacities.secondary,
                      ),
                      height: 1.2,
                      fontWeight: AppTypography.wMedium,
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _error!,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.error,
                        fontWeight: AppTypography.wSemibold,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  /// Preferred workout time card
                  _Card(
                    scheme: scheme,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            PhosphorIcon(
                              PhosphorIconsRegular.clock,
                              size: 20,
                              color: scheme.secondary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Preferred workout time',
                              style: textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () async =>
                                    await _togglePresetWindow(_morningWindow),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isMorningSelected
                                        ? scheme.primary
                                        : (isLight
                                            ? AppColors.neutralLight
                                            : AppColors.neutralDark),
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.md,
                                    ),
                                    border: _isMorningSelected
                                        ? null
                                        : Border.all(
                                            color: scheme.outline.withOpacity(
                                              0.3,
                                            ),
                                          ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Morning\n6–9 AM',
                                    textAlign: TextAlign.center,
                                    style: textTheme.labelLarge?.copyWith(
                                      color: _isMorningSelected
                                          ? AppColors.whiteUtility
                                          : scheme.onSurface.withOpacity(0.9),
                                      fontWeight: AppTypography.wSemibold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async =>
                                    await _togglePresetWindow(_eveningWindow),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isEveningSelected
                                        ? scheme.primary
                                        : (isLight
                                            ? AppColors.neutralLight
                                            : AppColors.neutralDark),
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.md,
                                    ),
                                    border: _isEveningSelected
                                        ? null
                                        : Border.all(
                                            color: scheme.outline.withOpacity(
                                              0.3,
                                            ),
                                          ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Evening\n6–9 PM',
                                    textAlign: TextAlign.center,
                                    style: textTheme.labelLarge?.copyWith(
                                      color: _isEveningSelected
                                          ? AppColors.whiteUtility
                                          : scheme.onSurface.withOpacity(0.9),
                                      fontWeight: AppTypography.wSemibold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        /// Add custom time (tap)
                        GestureDetector(
                          onTap: _openCustomWindowSheet,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(AppRadii.md),
                              border: Border.all(
                                color: scheme.outline,
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PhosphorIcon(
                                  PhosphorIconsRegular.plus,
                                  size: 24,
                                  color: isLight
                                      ? scheme.primary
                                      : scheme.onSurface,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'Add custom time',
                                  style: textTheme.bodyMedium!.copyWith(
                                    color: isLight
                                        ? scheme.primary
                                        : scheme.onSurface,
                                    fontWeight: AppTypography.wSemibold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        /// Custom window preview (improved UI)
                        if (_hasCustomWindow && _customWindow != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                              horizontal: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(AppRadii.md),
                              border: Border.all(
                                color: scheme.outline.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: scheme.primary.withOpacity(0.10),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: PhosphorIcon(
                                    PhosphorIconsRegular.clock,
                                    size: 18,
                                    color: scheme.primary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Custom window",
                                        style: textTheme.bodyMedium?.copyWith(
                                          fontWeight: AppTypography.wSemibold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${_prettyTime(_customWindow!["start"]!)} – ${_prettyTime(_customWindow!["end"]!)}",
                                        style: textTheme.bodySmall?.copyWith(
                                          color: scheme.onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _openCustomWindowSheet,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    child: PhosphorIcon(
                                      PhosphorIconsRegular.pencilSimple,
                                      size: 18,
                                      color: scheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                GestureDetector(
                                  onTap: _removeCustomWindow,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    child: PhosphorIcon(
                                      PhosphorIconsRegular.trash,
                                      size: 18,
                                      color: scheme.error.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  /// Notification tone card
                  _Card(
                    scheme: scheme,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            PhosphorIcon(
                              PhosphorIconsRegular.bell,
                              size: 24,
                              color: scheme.secondary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Notification tone',
                              style: textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectTone("supportive"),
                                child: _tone == "supportive"
                                    ? _Chip.selectedWithIcon(
                                        context: context,
                                        label: 'Supportive',
                                        icon: const PhosphorIcon(
                                          PhosphorIconsRegular.smileyWink,
                                          size: 24,
                                        ),
                                        scheme: scheme,
                                        textTheme: textTheme,
                                        isVertical: true,
                                      )
                                    : _Chip.unselectedWithIcon(
                                        context: context,
                                        label: 'Supportive',
                                        icon: const PhosphorIcon(
                                          PhosphorIconsRegular.smileyWink,
                                          size: 24,
                                        ),
                                        scheme: scheme,
                                        textTheme: textTheme,
                                        isVertical: true,
                                      ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectTone("firm"),
                                child: _tone == "firm"
                                    ? _Chip.selectedWithIcon(
                                        context: context,
                                        label: 'Firm',
                                        icon: const PhosphorIcon(
                                          PhosphorIconsRegular.handshake,
                                          size: 24,
                                        ),
                                        scheme: scheme,
                                        textTheme: textTheme,
                                        isVertical: true,
                                      )
                                    : _Chip.unselectedWithIcon(
                                        context: context,
                                        label: 'Firm',
                                        icon: const PhosphorIcon(
                                          PhosphorIconsRegular.handshake,
                                          size: 24,
                                        ),
                                        scheme: scheme,
                                        textTheme: textTheme,
                                        isVertical: true,
                                      ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectTone("silent"),
                                child: _tone == "silent"
                                    ? _Chip.selectedWithIcon(
                                        context: context,
                                        label: 'Silent\nMinimal',
                                        icon: const PhosphorIcon(
                                          PhosphorIconsRegular.moon,
                                          size: 24,
                                        ),
                                        scheme: scheme,
                                        textTheme: textTheme,
                                        isVertical: true,
                                      )
                                    : _Chip.unselectedWithIcon(
                                        context: context,
                                        label: 'Silent\nMinimal',
                                        icon: const PhosphorIcon(
                                          PhosphorIconsRegular.moon,
                                          size: 24,
                                        ),
                                        scheme: scheme,
                                        textTheme: textTheme,
                                        isVertical: true,
                                      ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Tone affects message style and language.',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  /// Delivery channels card
                  _Card(
                    scheme: scheme,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            PhosphorIcon(
                              PhosphorIconsRegular.bell,
                              size: 20,
                              color: scheme.secondary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Delivery channels',
                              style: textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        _ChannelRow(
                          scheme: scheme,
                          textTheme: textTheme,
                          title: 'In-App Push',
                          subtitle: 'Get notified while using the app',
                          enabled: _channelConfig["in_app"] == true,
                          icon: PhosphorIconsRegular.bell,
                          onChanged: (v) => _toggleChannel("in_app", v),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Divider(height: 1),
                        const SizedBox(height: AppSpacing.xs),

                        _ChannelRow(
                          scheme: scheme,
                          textTheme: textTheme,
                          title: 'Local Notification',
                          subtitle: 'System notifications on your device',
                          enabled: _channelConfig["push"] == true,
                          icon: PhosphorIconsRegular.deviceMobileCamera,
                          onChanged: (v) => _toggleChannel("push", v),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Divider(height: 1),
                        const SizedBox(height: AppSpacing.xs),

                        _ChannelRow(
                          scheme: scheme,
                          textTheme: textTheme,
                          title: 'Optional Email',
                          subtitle: 'In-App Push (optional email reminders)',
                          enabled: _channelConfig["email"] == true,
                          icon: PhosphorIconsRegular.envelopeSimple,
                          onChanged: (v) => _toggleChannel("email", v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  /// Fallback window card
                  _Card(
                    scheme: scheme,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.10),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: PhosphorIcon(
                                PhosphorIconsRegular.warningCircle,
                                size: 22,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fallback window',
                                    style: textTheme.titleMedium?.copyWith(
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'If you miss your preferred time, RepTran will nudge again 2 hours later.',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurface.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  /// Save button
                  GestureDetector(
                    onTap: _saving ? null : _saveTrigger,
                    child: Opacity(
                      opacity: _saving ? 0.75 : 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          boxShadow: AppShadows.e1(scheme),
                        ),
                        constraints: const BoxConstraints(minHeight: 56),
                        child: Center(
                          child: _saving
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: scheme.onSecondary,
                                  ),
                                )
                              : Text(
                                  'Save Settings',
                                  style: textTheme.titleMedium!.copyWith(
                                    color: scheme.onSecondary,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// -------------------------------
/// UI HELPERS
/// -------------------------------
class _Card extends StatelessWidget {
  final Widget child;
  final ColorScheme scheme;
  const _Card({required this.child, required this.scheme, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e1(scheme),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: child,
    );
  }
}

class _Chip {
  static Widget selectedWithIcon({
    required BuildContext context,
    required String label,
    required Widget icon,
    required ColorScheme scheme,
    required TextTheme textTheme,
    bool isVertical = false,
  }) =>
      _baseChip(
        context: context,
        label: label,
        icon: icon,
        scheme: scheme,
        textTheme: textTheme,
        selected: true,
        isVertical: isVertical,
      );

  static Widget unselectedWithIcon({
    required BuildContext context,
    required String label,
    required Widget icon,
    required ColorScheme scheme,
    required TextTheme textTheme,
    bool isVertical = false,
  }) =>
      _baseChip(
        context: context,
        label: label,
        icon: icon,
        scheme: scheme,
        textTheme: textTheme,
        selected: false,
        isVertical: isVertical,
      );

  static Widget _baseChip({
    required BuildContext context,
    required String label,
    required Widget icon,
    required ColorScheme scheme,
    required TextTheme textTheme,
    required bool selected,
    required bool isVertical,
  }) {
    final isLight = scheme.brightness == Brightness.light;

    final backgroundColor = selected
        ? scheme.secondary
        : isLight
            ? AppColors.neutralLight
            : AppColors.neutralDark;

    final textColor = selected
        ? AppColors.whiteUtility
        : scheme.onSurface.withOpacity(0.9);

    return Material(
      color: Colors.transparent,
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: AppBorders.boxCard(scheme),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: textTheme.labelLarge?.copyWith(
                  color: textColor,
                  fontWeight: AppTypography.wSemibold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;
  final String title;
  final String subtitle;
  final bool enabled;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  const _ChannelRow({
    required this.scheme,
    required this.textTheme,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.icon,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  bool get _isLight => scheme.brightness == Brightness.light;

  @override
  Widget build(BuildContext context) {
    final Color iconBg = _isLight ? AppColors.neutralLight : AppColors.neutralDark;

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: 0,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: PhosphorIcon(icon, size: 20, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: AppTypography.wSemibold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.0,
            child: Switch.adaptive(
              value: enabled,
              onChanged: onChanged,
              activeTrackColor: scheme.primary,
              inactiveTrackColor: scheme.outline,
              activeColor: AppColors.whiteUtility,
              inactiveThumbColor: AppColors.whiteUtility,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeRow({
    required this.label,
    required this.value,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: scheme.outline.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: AppTypography.wSemibold,
                ),
              ),
            ),
            Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withOpacity(0.85),
                fontWeight: AppTypography.wSemibold,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            PhosphorIcon(
              PhosphorIconsRegular.caretRight,
              size: 18,
              color: scheme.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}
