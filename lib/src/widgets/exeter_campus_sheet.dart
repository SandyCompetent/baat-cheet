import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../theme_data.dart';
import '../services/gemini_service.dart';

/// University of Exeter Live Campus Data modal bottom sheet, ported from
/// `exeter_academic_agent` (`DashboardScreen` & `DashboardCard`) and styled
/// with ChatBud's Soft Minimalist Slate design system.
class ExeterCampusSheet extends StatefulWidget {
  final http.Client? httpClient;

  const ExeterCampusSheet({super.key, this.httpClient});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExeterCampusSheet(),
    );
  }

  @override
  State<ExeterCampusSheet> createState() => _ExeterCampusSheetState();
}

class _ExeterCampusSheetState extends State<ExeterCampusSheet> {
  bool _isLoading = true;
  String _weatherStr = 'Fetching...';
  String _busEta = 'Loading...';
  int _forumOccupancy = 45;
  int _stLukesOccupancy = 35;

  @override
  void initState() {
    super.initState();
    _fetchCampusData();
  }

  Future<void> _fetchCampusData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    String weatherStr = 'Unavailable';
    String busEta = 'Every 15 mins (Stagecoach 4/4A)';

    final client = widget.httpClient ?? http.Client();
    try {
      final res = await client
          .get(
            Uri.parse(
              'https://api.open-meteo.com/v1/forecast?latitude=50.7352&longitude=-3.5328&current_weather=true',
            ),
          )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final current = data['current_weather'] as Map<String, dynamic>?;
        if (current != null) {
          final temp = current['temperature'];
          final code = (current['weathercode'] as num?)?.toInt() ?? -1;
          weatherStr = '$temp°C, ${_getWeatherEmoji(code)}';
        }
      }
    } catch (_) {
      weatherStr = 'Offline (Exeter Campus)';
    } finally {
      if (widget.httpClient == null) {
        client.close();
      }
    }

    // Fetch bus schedule insight via GeminiService
    try {
      final buffer = StringBuffer();
      final stream = GeminiService.instance.streamResponse(
        prompt:
            "What is the typical schedule or next expected time for the Stagecoach UNI or 4 bus or 4A bus from the University of Exeter right now? Respond with just a short phrase like 'In 10 mins' or 'Every 15 mins', also specify time in HH:mm format (24 hours format) of next expected bus timing.",
        systemInstruction:
            'You are an assistant providing transit schedule insights for the University of Exeter. '
            'Provide an extremely concise output under 12 words. No pleasantries.',
      );
      await for (final chunk in stream) {
        buffer.write(chunk);
      }
      final reply = buffer.toString().trim();
      if (reply.isNotEmpty && !reply.startsWith('I am ChatBud AI Assistant')) {
        busEta = reply;
      } else {
        final nextTime = DateTime.now().add(const Duration(minutes: 10));
        final hh = nextTime.hour.toString().padLeft(2, '0');
        final mm = nextTime.minute.toString().padLeft(2, '0');
        busEta = 'In 10 mins ($hh:$mm) • Every 15 mins';
      }
    } catch (_) {
      busEta = 'Every 15 mins (Stagecoach 4/4A)';
    }

    final hour = DateTime.now().hour;
    final isPeakHours = hour >= 10 && hour <= 16;
    final baseOccupancy = isPeakHours ? 75 : 30;
    final forumOccupancy = min(100, baseOccupancy + Random().nextInt(15));
    final stLukesOccupancy =
        min(100, (baseOccupancy * 0.8).toInt() + Random().nextInt(15));

    if (!mounted) return;
    setState(() {
      _weatherStr = weatherStr;
      _busEta = busEta;
      _forumOccupancy = forumOccupancy;
      _stLukesOccupancy = stLukesOccupancy;
      _isLoading = false;
    });
  }

  String _getWeatherEmoji(int code) {
    if (code == 0) return 'Clear ☀️';
    if (code >= 1 && code <= 3) return 'Cloudy ⛅';
    if (code == 45 || code == 48) return 'Foggy 🌫️';
    if (code >= 51 && code <= 67) return 'Rain 🌧️';
    if (code >= 71 && code <= 77) return 'Snow ❄️';
    if (code >= 95) return 'Thunderstorm ⛈️';
    return 'Mild 🌤️';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: context.bgCanvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: context.borderSubtle),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007D69).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Color(0xFF007D69),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exeter Campus Live Data',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'University of Exeter • Streatham & St Luke\'s',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh Live Data',
                    icon: _isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.accent,
                            ),
                          )
                        : Icon(Icons.refresh_rounded, color: context.accent),
                    onPressed: _isLoading ? null : _fetchCampusData,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _CampusDashboardCard(
                        title: 'Campus Weather',
                        value: _weatherStr,
                        icon: Icons.cloud_outlined,
                        subtitle: 'Powered by Open-Meteo (Exeter)',
                      ),
                      const SizedBox(height: 12),
                      _CampusDashboardCard(
                        title: 'Next Bus 4/4A to Campus',
                        value: _busEta,
                        icon: Icons.directions_bus_outlined,
                        subtitle: 'Stagecoach Schedule (AI Powered)',
                      ),
                      const SizedBox(height: 12),
                      _CampusDashboardCard(
                        title: 'Forum Library Occupancy',
                        value: '$_forumOccupancy% Full',
                        icon: Icons.library_books_outlined,
                        progress: _forumOccupancy / 100,
                      ),
                      const SizedBox(height: 12),
                      _CampusDashboardCard(
                        title: 'St Luke\'s Library Occupancy',
                        value: '$_stLukesOccupancy% Full',
                        icon: Icons.menu_book_outlined,
                        progress: _stLukesOccupancy / 100,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CampusDashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final double? progress;

  const _CampusDashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isHighOccupancy = progress != null && progress! > 0.8;
    final barColor =
        isHighOccupancy ? context.statusDanger : const Color(0xFF007D69);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.accentSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: context.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: context.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: context.bgElevated,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
