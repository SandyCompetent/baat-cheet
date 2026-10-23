import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/app_logger.dart';
import '../core/storage_service.dart';
import '../models/rag_citation.dart';

/// Grounded Retrieval-Augmented Generation (RAG) service powered by zero-auth,
/// CORS-enabled public APIs and MCP catalogs from `public-apis/public-apis`,
/// plus optional APILayer (`api.apilayer.com`) keyed endpoints.
///
/// Automatically enriches each ChatBud persona with live, verifiable facts,
/// citations, software release lifecycles, vulnerability advisories, academic
/// literature, job market data, and lexical associations before Gemini generates
/// a response.
class PublicApiRagService extends ChangeNotifier {
  static final PublicApiRagService instance = PublicApiRagService._internal();
  PublicApiRagService._internal();

  /// Optional build-time APILayer key (--dart-define=APILAYER_API_KEY=your_key)
  static const String defaultEnvApiLayerKey =
      String.fromEnvironment('APILAYER_API_KEY', defaultValue: '');

  static const Duration _requestTimeout = Duration(milliseconds: 3500);
  static const Duration _cacheTtl = Duration(minutes: 10);
  static const int _maxCacheEntries = 50;

  String _apiKey = defaultEnvApiLayerKey;

  /// Current Public API / APILayer key configured by the user.
  String get apiKey => _apiKey;

  /// Whether a custom APILayer / Public API key is active.
  bool get hasCustomApiKey => _apiKey.trim().isNotEmpty;

  /// Restores persisted Public API / APILayer key from local storage.
  void loadFromStorage() {
    final stored = StorageService.getPublicApiKey();
    if (stored != null && stored.trim().isNotEmpty) {
      _apiKey = stored.trim();
    } else {
      _apiKey = defaultEnvApiLayerKey;
    }
    notifyListeners();
  }

  /// Sets or clears the user's APILayer / Public API key for Grounded RAG.
  Future<void> setApiKey(String key) async {
    final trimmed = key.trim();
    _apiKey = trimmed;
    _cache.clear();
    await StorageService.setPublicApiKey(trimmed);
    notifyListeners();
  }

  http.Client? _customClient;

  @visibleForTesting
  set httpClientForTesting(http.Client? client) {
    _customClient = client;
  }

  /// Clear in-memory RAG cache (useful in tests).
  @visibleForTesting
  void clearCache() {
    _cache.clear();
  }

  final Map<String, RagGroundingResult> _cache = {};

  /// Curated MCP servers from `https://github.com/public-apis/public-apis#mcp-servers`
  /// mapped to ChatBud personas.
  static const List<Map<String, String>> recommendedMcpServers = [
    {
      'name': 'Edgepedia MCP',
      'url': 'https://github.com/EdgePlat/edgepedia-mcp',
      'transport': 'HTTP',
      'auth': 'No',
      'personas': 'exeter, aria, marcus',
      'description':
          'Search over 1M+ encyclopedia articles with citations and summaries.',
    },
    {
      'name': 'Openpath MCP',
      'url': 'https://openpath.sh/docs/connect',
      'transport': 'HTTP',
      'auth': 'No',
      'personas': 'harper, leo',
      'description':
          'Search US job listings with direct apply links by role and company.',
    },
    {
      'name': 'AI Dev Jobs MCP',
      'url': 'https://aidevboard.com',
      'transport': 'HTTP',
      'auth': 'No',
      'personas': 'harper, leo',
      'description':
          'AI and software engineering job board with REST and MCP endpoints.',
    },
    {
      'name': 'corpusAI Cloud Pricing MCP',
      'url': 'https://www.corpusai.io/docs/mcp-setup',
      'transport': 'stdio, HTTP',
      'auth': 'No',
      'personas': 'athena',
      'description':
          'Cloud instance, GPU, and LLM token prices across major providers.',
    },
    {
      'name': 'Agent Nexus MCP',
      'url': 'https://agentnexus.app',
      'transport': 'HTTP',
      'auth': 'No',
      'personas': 'athena',
      'description':
          'Discovery engine for agent-callable public APIs and MCP servers.',
    },
    {
      'name': 'GitHub MCP Server',
      'url': 'https://github.com/github/github-mcp-server',
      'transport': 'stdio, HTTP',
      'auth': 'OAuth',
      'personas': 'athena, cipher',
      'description':
          'Official GitHub MCP server for repos, issues, PRs, and code search.',
    },
  ];

  /// Known software product slugs supported by `https://endoflife.date/api/<slug>.json`.
  static const Map<String, String> _eolProductSlugs = {
    'flutter': 'flutter',
    'dart': 'dart',
    'python': 'python',
    'node': 'nodejs',
    'nodejs': 'nodejs',
    'postgres': 'postgresql',
    'postgresql': 'postgresql',
    'kubernetes': 'kubernetes',
    'k8s': 'kubernetes',
    'docker': 'docker-engine',
    'react': 'react',
    'angular': 'angular',
    'vue': 'vue',
    'golang': 'go',
    'rust': 'rust',
    'java': 'java',
    'kotlin': 'kotlin',
    'swift': 'swift',
    'ruby': 'ruby',
    'php': 'php',
    'redis': 'redis',
    'mongodb': 'mongodb',
    'mysql': 'mysql',
    'ubuntu': 'ubuntu',
    'debian': 'debian',
    'nextjs': 'nextjs',
    'django': 'django',
    'rails': 'rails',
    'dotnet': 'dotnet',
    'terraform': 'terraform',
  };

  /// Retrieves live grounding citations for [personaId] and [query].
  /// Never throws; returns an empty [RagGroundingResult] if offline or timed out.
  Future<RagGroundingResult> retrieveGroundingContext({
    required String personaId,
    required String query,
    String? personaCategory,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return RagGroundingResult(
        personaId: personaId,
        query: query,
        citations: const [],
        retrievedAt: DateTime.now(),
      );
    }

    final cacheKey = '${personaId.toLowerCase()}:${trimmed.toLowerCase()}';
    final cached = _cache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.retrievedAt) < _cacheTtl) {
      return cached;
    }

    final citations = <RagCitation>[];
    final normalizedId = personaId.toLowerCase();
    final normalizedCategory = (personaCategory ?? '').toLowerCase();

    try {
      if (normalizedId == 'openalex_rag') {
        citations.addAll(await _fetchOpenAlexWorks(trimmed, maxResults: 3));
      } else if (normalizedId == 'osv_rag') {
        citations.addAll(await _retrieveSecurityContext(trimmed));
      } else if (normalizedId == 'eol_rag') {
        citations.addAll(await _retrieveEngineeringContext(trimmed));
      } else if (normalizedId == 'jobs_rag') {
        citations.addAll(await _retrieveCareerContext(trimmed));
      } else if (normalizedId == 'weather_rag') {
        citations.addAll(await _retrieveWeatherContext(trimmed));
      } else if (normalizedId == 'wiki_rag') {
        citations.addAll(await _retrieveGeneralContext(trimmed));
      } else if (normalizedId == 'lexicon_rag') {
        citations.addAll(await _retrieveCreativeContext(trimmed));
      } else if (normalizedId == 'holiday_rag') {
        final results = await Future.wait([
          _fetchUpcomingGlobalHolidays(maxResults: 3),
          _fetchUkBankHolidays(),
        ]);
        citations.addAll(results.expand((x) => x));
      } else if (normalizedId == 'exeter' || normalizedCategory == 'academic') {
        citations.addAll(await _retrieveAcademicContext(trimmed));
      } else if (normalizedId == 'athena' ||
          normalizedCategory == 'engineering') {
        citations.addAll(await _retrieveEngineeringContext(trimmed));
      } else if (normalizedId == 'cipher' || normalizedCategory == 'security') {
        citations.addAll(await _retrieveSecurityContext(trimmed));
      } else if (normalizedId == 'harper' ||
          normalizedCategory.contains('hr')) {
        citations.addAll(await _retrieveHrAndJobsContext(trimmed));
      } else if (normalizedId == 'leo' || normalizedCategory == 'career') {
        citations.addAll(await _retrieveCareerContext(trimmed));
      } else if (normalizedId == 'aria' ||
          normalizedCategory == 'productivity') {
        citations.addAll(await _retrieveProductivityContext(trimmed));
      } else if (normalizedId == 'marcus' ||
          normalizedCategory == 'philosophy') {
        citations.addAll(await _retrievePhilosophyContext(trimmed));
      } else if (normalizedId == 'nova' || normalizedCategory == 'creative') {
        citations.addAll(await _retrieveCreativeContext(trimmed));
      } else {
        // General AI assistant or custom persona fallback: OpenAlex + Wikipedia
        citations.addAll(await _retrieveGeneralContext(trimmed));
      }
    } catch (e, st) {
      AppLogger.w(
        'PublicApiRagService retrieval fallback for "$personaId"',
        tag: 'PublicApiRagService',
        error: e,
        stackTrace: st,
      );
    }

    final result = RagGroundingResult(
      personaId: personaId,
      query: trimmed,
      citations: citations,
      retrievedAt: DateTime.now(),
    );

    if (citations.isNotEmpty) {
      if (_cache.length >= _maxCacheEntries) {
        _cache.remove(_cache.keys.first);
      }
      _cache[cacheKey] = result;
    }

    return result;
  }

  // ── 1. Exeter Academic (`exeter`) — OpenAlex + Open-Meteo + UK Holidays ───
  Future<List<RagCitation>> _retrieveAcademicContext(String query) async {
    final lower = query.toLowerCase();
    final futures = <Future<List<RagCitation>>>[
      _fetchOpenAlexWorks(query, maxResults: 3),
    ];

    if (lower.contains('weather') ||
        lower.contains('campus') ||
        lower.contains('exeter') ||
        lower.contains('streatham') ||
        lower.contains('st luke')) {
      futures.add(_fetchExeterWeather());
    }

    if (lower.contains('holiday') ||
        lower.contains('term') ||
        lower.contains('bank holiday') ||
        lower.contains('calendar') ||
        lower.contains('deadline')) {
      futures.add(_fetchUkBankHolidays());
    }

    final results = await Future.wait(futures);
    return results.expand((x) => x).toList();
  }

  // ── 2. Athena (`athena`) — EndOfLife.date + Wikipedia Summary ─────────────
  Future<List<RagCitation>> _retrieveEngineeringContext(String query) async {
    final slugs = _detectProductSlugs(query);
    final targetSlug = slugs.isNotEmpty ? slugs.first : 'flutter';
    final results = await Future.wait([
      _fetchEndOfLifeProduct(targetSlug),
      _fetchWikipediaSummary(_extractPrimaryTopic(query)),
    ]);
    return results.expand((x) => x).toList();
  }

  // ── 3. Cipher (`cipher`) — Google OSV + EndOfLife Security Support ────────
  Future<List<RagCitation>> _retrieveSecurityContext(String query) async {
    final slugs = _detectProductSlugs(query);
    final packageInfo = _detectOsvPackage(query);
    final futures = <Future<List<RagCitation>>>[
      _fetchOsvVulnerabilities(
        packageName: packageInfo.$1,
        ecosystem: packageInfo.$2,
      ),
    ];
    if (slugs.isNotEmpty) {
      futures.add(_fetchEndOfLifeProduct(slugs.first));
    } else {
      futures.add(_fetchWikipediaSummary(_extractPrimaryTopic(query)));
    }
    final results = await Future.wait(futures);
    return results.expand((x) => x).toList();
  }

  // ── 4. Harper (`harper`) — Arbeitnow Job Board API ────────────────────────
  Future<List<RagCitation>> _retrieveHrAndJobsContext(String query) async {
    return _fetchArbeitnowJobs(query, maxResults: 3);
  }

  // ── 5. Leo (`leo`) — RemoteOK Compensation + Arbeitnow Market Data ────────
  Future<List<RagCitation>> _retrieveCareerContext(String query) async {
    final results = await Future.wait([
      _fetchRemoteOkJobs(query, maxResults: 2),
      _fetchArbeitnowJobs(query, maxResults: 2),
    ]);
    return results.expand((x) => x).toList();
  }

  // ── 6. Aria (`aria`) — Nager.Date Public Holidays + Wikipedia Summary ─────
  Future<List<RagCitation>> _retrieveProductivityContext(String query) async {
    final results = await Future.wait([
      _fetchUpcomingGlobalHolidays(maxResults: 3),
      _fetchWikipediaSummary(_extractPrimaryTopic(query)),
    ]);
    return results.expand((x) => x).toList();
  }

  // ── 7. Marcus (`marcus`) — Stoic Quotes API + Wikipedia Philosophy ────────
  Future<List<RagCitation>> _retrievePhilosophyContext(String query) async {
    final results = await Future.wait([
      _fetchStoicQuote(),
      _fetchWikipediaSummary(_extractPrimaryTopic(query)),
    ]);
    return results.expand((x) => x).toList();
  }

  // ── 8. Nova (`nova`) — Datamuse Semantic Words + Free Dictionary API ──────
  Future<List<RagCitation>> _retrieveCreativeContext(String query) async {
    final primaryWord = _extractPrimaryKeyword(query);
    final results = await Future.wait([
      _fetchDatamuseAssociations(query),
      if (primaryWord.isNotEmpty) _fetchFreeDictionaryEntry(primaryWord),
    ]);
    return results.expand((x) => x).toList();
  }

  // ── 9. General Fallback — Wikipedia Summary + OpenAlex ────────────────────
  Future<List<RagCitation>> _retrieveGeneralContext(String query) async {
    final results = await Future.wait([
      _fetchWikipediaSummary(_extractPrimaryTopic(query)),
      _fetchOpenAlexWorks(query, maxResults: 2),
    ]);
    return results.expand((x) => x).toList();
  }

  // ── 10. Atmos (`weather_rag`) — Open-Meteo Global Forecast ─────────────────
  Future<List<RagCitation>> _retrieveWeatherContext(String query) async {
    final lower = query.toLowerCase();
    double lat = 50.7365;
    double lon = -3.5344;
    String cityLabel = 'Exeter, UK';

    if (lower.contains('london')) {
      lat = 51.5074;
      lon = -0.1278;
      cityLabel = 'London, UK';
    } else if (lower.contains('tokyo')) {
      lat = 35.6762;
      lon = 139.6503;
      cityLabel = 'Tokyo, Japan';
    } else if (lower.contains('new york') || lower.contains('nyc')) {
      lat = 40.7128;
      lon = -74.0060;
      cityLabel = 'New York, USA';
    } else if (lower.contains('paris')) {
      lat = 48.8566;
      lon = 2.3522;
      cityLabel = 'Paris, France';
    } else if (lower.contains('san francisco')) {
      lat = 37.7749;
      lon = -122.4194;
      cityLabel = 'San Francisco, USA';
    } else if (lower.contains('berlin')) {
      lat = 52.5200;
      lon = 13.4050;
      cityLabel = 'Berlin, Germany';
    } else if (lower.contains('sydney')) {
      lat = -33.8688;
      lon = 151.2093;
      cityLabel = 'Sydney, Australia';
    }

    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true',
    );
    final resp = await _safeGet(uri);
    if (resp == null || resp.statusCode != 200) return const [];

    try {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final cw = data['current_weather'] as Map<String, dynamic>?;
      if (cw == null) return const [];
      final temp = cw['temperature'];
      final wind = cw['windspeed'];
      return [
        RagCitation(
          sourceName: 'Open-Meteo',
          title: 'Live Weather Forecast: $cityLabel',
          url: 'https://open-meteo.com/',
          snippet: '$cityLabel ($lat, $lon): $temp°C, wind speed $wind km/h.',
          category: 'Grounded RAG',
        ),
      ];
    } catch (_) {
      return const [];
    }
  }

  // ===========================================================================
  // Low-Level Public API Connectors (Auth: No, HTTPS: Yes, CORS: Yes)
  // ===========================================================================

  Future<http.Response?> _safeGet(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    try {
      final effectiveHeaders = <String, String>{
        if (headers != null) ...headers,
        if (hasCustomApiKey && uri.host.contains('apilayer.com'))
          'apikey': _apiKey.trim(),
      };
      final client = _customClient;
      if (client != null) {
        return await client
            .get(
              uri,
              headers: effectiveHeaders.isEmpty ? null : effectiveHeaders,
            )
            .timeout(_requestTimeout);
      }
      return await http
          .get(
            uri,
            headers: effectiveHeaders.isEmpty ? null : effectiveHeaders,
          )
          .timeout(_requestTimeout);
    } catch (_) {
      return null;
    }
  }

  Future<http.Response?> _safePost(
    Uri uri, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final encoded = jsonEncode(body);
      final headers = {'Content-Type': 'application/json'};
      final client = _customClient;
      if (client != null) {
        return await client
            .post(uri, headers: headers, body: encoded)
            .timeout(_requestTimeout);
      }
      return await http
          .post(uri, headers: headers, body: encoded)
          .timeout(_requestTimeout);
    } catch (_) {
      return null;
    }
  }

  /// OpenAlex API (`https://api.openalex.org/works`) — 250M+ scholarly works.
  Future<List<RagCitation>> _fetchOpenAlexWorks(
    String query, {
    int maxResults = 3,
  }) async {
    final cleanedQuery = _sanitizeSearchTerms(query);
    if (cleanedQuery.isEmpty) return const [];

    final uri = Uri.https('api.openalex.org', '/works', {
      'search': cleanedQuery,
      'per-page': maxResults.toString(),
    });

    final resp = await _safeGet(uri);
    if (resp == null || resp.statusCode != 200) return const [];

    try {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>?) ?? const [];
      final citations = <RagCitation>[];

      for (final raw in results.take(maxResults)) {
        if (raw is! Map<String, dynamic>) continue;
        final title = (raw['title'] ?? raw['display_name'] ?? '').toString();
        if (title.trim().isEmpty) continue;

        final year = raw['publication_year']?.toString() ?? 'n.d.';
        final citedBy = raw['cited_by_count']?.toString() ?? '0';
        final doi =
            (raw['doi'] ?? raw['id'] ?? 'https://openalex.org').toString();

        final authorships = (raw['authorships'] as List<dynamic>?) ?? const [];
        final authors = authorships
            .take(3)
            .map((a) {
              if (a is Map<String, dynamic>) {
                final author = a['author'];
                if (author is Map<String, dynamic>) {
                  return (author['display_name'] ?? '').toString();
                }
              }
              return '';
            })
            .where((name) => name.isNotEmpty)
            .join(', ');

        final authorLabel = authors.isNotEmpty ? authors : 'Scholarly Authors';
        citations.add(
          RagCitation(
            sourceName: 'OpenAlex',
            title: '$title ($year)',
            url: doi,
            snippet:
                'Authors: $authorLabel | Published: $year | Citations: $citedBy.',
            category: 'Academic',
          ),
        );
      }
      return citations;
    } catch (_) {
      return const [];
    }
  }

  /// Open-Meteo API (`https://api.open-meteo.com/v1/forecast`) for Exeter UK.
  Future<List<RagCitation>> _fetchExeterWeather() async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=50.7365&longitude=-3.5344&current_weather=true',
    );
    final resp = await _safeGet(uri);
    if (resp == null || resp.statusCode != 200) return const [];

    try {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final cw = data['current_weather'] as Map<String, dynamic>?;
      if (cw == null) return const [];
      final temp = cw['temperature'];
      final wind = cw['windspeed'];
      return [
        RagCitation(
          sourceName: 'Open-Meteo',
          title: 'University of Exeter Campus Weather (Live)',
          url: 'https://open-meteo.com/',
          snippet:
              'Streatham & St Luke\'s Campus, Exeter: $temp°C, wind speed $wind km/h.',
          category: 'Academic',
        ),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// UK Government Bank Holidays API (`https://www.gov.uk/bank-holidays.json`).
  Future<List<RagCitation>> _fetchUkBankHolidays() async {
    final uri = Uri.parse('https://www.gov.uk/bank-holidays.json');
    final resp = await _safeGet(uri);
    if (resp == null || resp.statusCode != 200) return const [];

    try {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final england = data['england-and-wales'] as Map<String, dynamic>?;
      final events = (england?['events'] as List<dynamic>?) ?? const [];
      final todayIso = DateTime.now().toIso8601String().substring(0, 10);

      final upcoming = events
          .whereType<Map<String, dynamic>>()
          .where((e) => (e['date']?.toString() ?? '').compareTo(todayIso) >= 0)
          .take(3)
          .map((e) => '${e['title']} (${e['date']})')
          .toList();

      if (upcoming.isEmpty) return const [];
      return [
        RagCitation(
          sourceName: 'GOV.UK Calendar',
          title: 'Upcoming England & Wales Bank Holidays',
          url: 'https://www.gov.uk/bank-holidays',
          snippet: 'Next UK public holidays: ${upcoming.join('; ')}.',
          category: 'Academic',
        ),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// EndOfLife.date API (`https://endoflife.date/api/<product>.json`).
  Future<List<RagCitation>> _fetchEndOfLifeProduct(String slug) async {
    final uri = Uri.parse('https://endoflife.date/api/$slug.json');
    final resp = await _safeGet(uri);
    if (resp == null || resp.statusCode != 200) return const [];

    try {
      final cycles = jsonDecode(resp.body) as List<dynamic>;
      if (cycles.isEmpty) return const [];
      final top = cycles.take(2).whereType<Map<String, dynamic>>().map((c) {
        final cycle = c['cycle'] ?? '';
        final latest = c['latest'] ?? '';
        final eol = c['eol'] ?? 'Active';
        final lts = c['lts'] == true ? ' (LTS)' : '';
        return 'v$cycle$lts [latest: $latest, EOL: $eol]';
      }).join('; ');

      return [
        RagCitation(
          sourceName: 'EndOfLife.date',
          title: '${slug.toUpperCase()} Release & Support Lifecycle',
          url: 'https://endoflife.date/$slug',
          snippet: 'Verified release cycles for $slug: $top.',
          category: 'Engineering',
        ),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Google OSV API (`https://api.osv.dev/v1/query`) for live CVE/advisory data.
  Future<List<RagCitation>> _fetchOsvVulnerabilities({
    required String packageName,
    required String ecosystem,
  }) async {
    final uri = Uri.parse('https://api.osv.dev/v1/query');
    final resp = await _safePost(
      uri,
      body: {
        'package': {
          'name': packageName,
          'ecosystem': ecosystem,
        },
      },
    );
    if (resp == null || resp.statusCode != 200) return const [];

    try {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final vulns = (data['vulns'] as List<dynamic>?) ?? const [];
      if (vulns.isEmpty) return const [];

      final citations = <RagCitation>[];
      for (final raw in vulns.take(2)) {
        if (raw is! Map<String, dynamic>) continue;
        final id = (raw['id'] ?? 'OSV-Advisory').toString();
        final summary = (raw['summary'] ?? raw['details'] ?? '')
            .toString()
            .replaceAll('\n', ' ')
            .trim();
        final shortSummary = summary.length > 160
            ? '${summary.substring(0, 157)}...'
            : (summary.isEmpty
                ? 'Security advisory reported in $ecosystem/$packageName.'
                : summary);
        citations.add(
          RagCitation(
            sourceName: 'Google OSV',
            title: '$id ($ecosystem: $packageName)',
            url: 'https://osv.dev/vulnerability/$id',
            snippet: shortSummary,
            category: 'Security',
          ),
        );
      }
      return citations;
    } catch (_) {
      return const [];
    }
  }

  /// Arbeitnow Job Board API (`https://www.arbeitnow.com/api/job-board-api`).
  Future<List<RagCitation>> _fetchArbeitnowJobs(
    String query, {
    int maxResults = 3,
  }) async {
    final uri = Uri.parse('https://www.arbeitnow.com/api/job-board-api');
    final resp = await _safeGet(uri);
    if (resp == null || resp.statusCode != 200) return const [];

    try {
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final jobs = (decoded['data'] as List<dynamic>?) ?? const [];
      if (jobs.isEmpty) return const [];

      final tokens = _extractTokens(query);
      final typedJobs = jobs.whereType<Map<String, dynamic>>().toList();

      // Score jobs by keyword overlap with user query; fall back to newest listings
      typedJobs.sort((a, b) {
        final scoreA = _scoreJobMatch(a, tokens);
        final scoreB = _scoreJobMatch(b, tokens);
        return scoreB.compareTo(scoreA);
      });

      final citations = <RagCitation>[];
      for (final job in typedJobs.take(maxResults)) {
        final title = (job['title'] ?? 'Open Role').toString();
        final company = (job['company_name'] ?? 'Company').toString();
        final location = (job['location'] ?? 'Remote').toString();
        final remote = job['remote'] == true ? 'Remote' : 'On-site/Hybrid';
        final url = (job['url'] ?? 'https://www.arbeitnow.com').toString();
        final tags = ((job['tags'] as List<dynamic>?) ?? const [])
            .map((e) => e.toString())
            .take(4)
            .join(', ');

        citations.add(
          RagCitation(
            sourceName: 'Arbeitnow',
            title: '$title at $company',
            url: url,
            snippet:
                'Location: $location ($remote)${tags.isNotEmpty ? ' | Skills: $tags' : ''}.',
            category: 'HR & Talent',
          ),
        );
      }
      return citations;
    } catch (_) {
      return const [];
    }
  }

  /// RemoteOK API (`https://remoteok.com/api`) for live remote roles & salary bands.
  Future<List<RagCitation>> _fetchRemoteOkJobs(
    String query, {
    int maxResults = 2,
  }) async {
    final uri = Uri.parse('https://remoteok.com/api');
    final resp = await _safeGet(uri);
    if (resp == null || resp.statusCode != 200) return const [];

    try {
      final list = jsonDecode(resp.body) as List<dynamic>;
      // First element in RemoteOK API is legal metadata object; skip entries without 'position'
      final jobs = list
          .whereType<Map<String, dynamic>>()
          .where((j) => j.containsKey('position'))
          .toList();
      if (jobs.isEmpty) return const [];

      final tokens = _extractTokens(query);
      jobs.sort((a, b) {
        final textA =
            '${a['position']} ${a['company']} ${a['tags']}'.toLowerCase();
        final textB =
            '${b['position']} ${b['company']} ${b['tags']}'.toLowerCase();
        final hitsA = tokens.where(textA.contains).length;
        final hitsB = tokens.where(textB.contains).length;
        return hitsB.compareTo(hitsA);
      });

      final citations = <RagCitation>[];
      for (final job in jobs.take(maxResults)) {
        final position = (job['position'] ?? 'Remote Engineer').toString();
        final company = (job['company'] ?? 'Remote Company').toString();
        final url = (job['url'] ?? 'https://remoteok.com').toString();
        final minSal = job['salary_min'];
        final maxSal = job['salary_max'];
        final salaryInfo =
            (minSal is num && maxSal is num && minSal > 0 && maxSal > 0)
                ? 'Compensation band: \$${minSal}k–\$${maxSal}k USD'
                : 'Global remote role';
        citations.add(
          RagCitation(
            sourceName: 'RemoteOK',
            title: '$position — $company',
            url: url.startsWith('http') ? url : 'https://remoteok.com',
            snippet:
                '$salaryInfo | Location: ${job['location'] ?? 'Worldwide'}.',
            category: 'Career',
          ),
        );
      }
      return citations;
    } catch (_) {
      return const [];
    }
  }

  /// Nager.Date Public Holidays API (`https://date.nager.at/api/v3/NextPublicHolidaysWorldwide`).
  Future<List<RagCitation>> _fetchUpcomingGlobalHolidays({
    int maxResults = 3,
  }) async {
    final uri = Uri.parse(
      'https://date.nager.at/api/v3/NextPublicHolidaysWorldwide',
    );
    final resp = await _safeGet(uri);
    if (resp == null || resp.statusCode != 200) return const [];

    try {
      final list = jsonDecode(resp.body) as List<dynamic>;
      final items = list
          .whereType<Map<String, dynamic>>()
          .take(maxResults)
          .map((h) => '${h['name']} (${h['countryCode']}, ${h['date']})')
          .toList();
      if (items.isEmpty) return const [];

      return [
        RagCitation(
          sourceName: 'Nager.Date',
          title: 'Upcoming Global Public Holidays',
          url: 'https://date.nager.at',
          snippet: 'Upcoming holidays for scheduling: ${items.join('; ')}.',
          category: 'Productivity',
        ),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Stoic Quotes API (`https://stoic-quotes.com/api/quote`).
  Future<List<RagCitation>> _fetchStoicQuote() async {
    final uri = Uri.parse('https://stoic-quotes.com/api/quote');
    final resp = await _safeGet(uri);
    if (resp == null || resp.statusCode != 200) return const [];

    try {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final text = (data['text'] ?? '').toString().trim();
      final author = (data['author'] ?? 'Stoic Philosopher').toString().trim();
      if (text.isEmpty) return const [];

      return [
        RagCitation(
          sourceName: 'Stoic Quotes',
          title: 'Passage by $author',
          url: 'https://stoic-quotes.com',
          snippet: '"$text" — $author',
          category: 'Philosophy',
        ),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Datamuse API (`https://api.datamuse.com/words?ml=...`) for creative copy/naming.
  Future<List<RagCitation>> _fetchDatamuseAssociations(String query) async {
    final cleaned = _sanitizeSearchTerms(query);
    if (cleaned.isEmpty) return const [];

    final uri = Uri.https('api.datamuse.com', '/words', {
      'ml': cleaned,
      'max': '10',
    });
    final resp = await _safeGet(uri);
    if (resp == null || resp.statusCode != 200) return const [];

    try {
      final list = jsonDecode(resp.body) as List<dynamic>;
      final words = list
          .whereType<Map<String, dynamic>>()
          .map((w) => (w['word'] ?? '').toString())
          .where((w) => w.isNotEmpty)
          .take(10)
          .toList();
      if (words.isEmpty) return const [];

      return [
        RagCitation(
          sourceName: 'Datamuse Lexical Engine',
          title: 'Semantic Associations for "$cleaned"',
          url: 'https://www.datamuse.com/api/',
          snippet: 'Related lexical concepts & triggers: ${words.join(', ')}.',
          category: 'Creative',
        ),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Free Dictionary API (`https://api.dictionaryapi.dev/api/v2/entries/en/<word>`).
  Future<List<RagCitation>> _fetchFreeDictionaryEntry(String word) async {
    final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (cleanWord.length < 3) return const [];

    final uri = Uri.parse(
      'https://api.dictionaryapi.dev/api/v2/entries/en/$cleanWord',
    );
    final resp = await _safeGet(uri);
    if (resp == null || resp.statusCode != 200) return const [];

    try {
      final list = jsonDecode(resp.body) as List<dynamic>;
      if (list.isEmpty || list.first is! Map<String, dynamic>) return const [];
      final entry = list.first as Map<String, dynamic>;
      final meanings = (entry['meanings'] as List<dynamic>?) ?? const [];
      if (meanings.isEmpty || meanings.first is! Map<String, dynamic>) {
        return const [];
      }
      final firstMeaning = meanings.first as Map<String, dynamic>;
      final partOfSpeech = (firstMeaning['partOfSpeech'] ?? 'noun').toString();
      final defs = (firstMeaning['definitions'] as List<dynamic>?) ?? const [];
      if (defs.isEmpty || defs.first is! Map<String, dynamic>) return const [];
      final definition =
          ((defs.first as Map<String, dynamic>)['definition'] ?? '').toString();
      if (definition.isEmpty) return const [];

      return [
        RagCitation(
          sourceName: 'Free Dictionary',
          title: 'Lexical Definition: "$cleanWord" ($partOfSpeech)',
          url: 'https://dictionaryapi.dev/',
          snippet: definition,
          category: 'Creative',
        ),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Wikipedia REST v1 Summary API (`https://en.wikipedia.org/api/rest_v1/page/summary/<title>`).
  Future<List<RagCitation>> _fetchWikipediaSummary(String topic) async {
    final cleaned = topic.trim();
    if (cleaned.isEmpty) return const [];

    final encodedTitle = Uri.encodeComponent(cleaned.replaceAll(' ', '_'));
    final uri = Uri.parse(
      'https://en.wikipedia.org/api/rest_v1/page/summary/$encodedTitle',
    );
    final resp = await _safeGet(uri);
    if (resp == null || resp.statusCode != 200) return const [];

    try {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final title = (data['title'] ?? cleaned).toString();
      final extract = (data['extract'] ?? '').toString().trim();
      if (extract.isEmpty) return const [];

      final contentUrls = data['content_urls'] as Map<String, dynamic>?;
      final desktop = contentUrls?['desktop'] as Map<String, dynamic>?;
      final pageUrl =
          (desktop?['page'] ?? 'https://en.wikipedia.org/wiki/$encodedTitle')
              .toString();

      final shortExtract =
          extract.length > 260 ? '${extract.substring(0, 257)}...' : extract;

      return [
        RagCitation(
          sourceName: 'Wikipedia',
          title: title,
          url: pageUrl,
          snippet: shortExtract,
          category: 'Knowledge',
        ),
      ];
    } catch (_) {
      return const [];
    }
  }

  // ===========================================================================
  // Query Parsing Helpers
  // ===========================================================================

  static const Set<String> _stopWords = {
    'what',
    'when',
    'where',
    'which',
    'who',
    'whom',
    'whose',
    'why',
    'how',
    'can',
    'could',
    'would',
    'should',
    'will',
    'shall',
    'may',
    'might',
    'must',
    'tell',
    'explain',
    'give',
    'show',
    'help',
    'please',
    'about',
    'with',
    'from',
    'into',
    'that',
    'this',
    'these',
    'those',
    'the',
    'and',
    'for',
    'are',
    'was',
    'were',
    'been',
    'have',
    'has',
    'had',
    'does',
    'did',
    'make',
    'best',
    'good',
    'need',
    'want',
  };

  List<String> _detectProductSlugs(String query) {
    final tokens = query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\.]'), ' ')
        .split(RegExp(r'\s+'));
    final matched = <String>[];
    for (final token in tokens) {
      final slug = _eolProductSlugs[token];
      if (slug != null && !matched.contains(slug)) {
        matched.add(slug);
      }
    }
    return matched;
  }

  (String, String) _detectOsvPackage(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('python') ||
        lower.contains('django') ||
        lower.contains('flask') ||
        lower.contains('requests')) {
      return ('requests', 'PyPI');
    }
    if (lower.contains('node') ||
        lower.contains('npm') ||
        lower.contains('react') ||
        lower.contains('express') ||
        lower.contains('lodash')) {
      return ('lodash', 'npm');
    }
    if (lower.contains('rust') || lower.contains('cargo')) {
      return ('tokio', 'crates.io');
    }
    if (lower.contains('go') || lower.contains('golang')) {
      return ('golang.org/x/crypto', 'Go');
    }
    return ('http', 'Pub');
  }

  int _scoreJobMatch(Map<String, dynamic> job, Set<String> tokens) {
    if (tokens.isEmpty) return 0;
    final haystack =
        '${job['title']} ${job['company_name']} ${job['tags']} ${job['location']}'
            .toLowerCase();
    int score = 0;
    for (final t in tokens) {
      if (haystack.contains(t)) score += 2;
    }
    if (job['remote'] == true) score += 1;
    return score;
  }

  Set<String> _extractTokens(String query) {
    return query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !_stopWords.contains(w))
        .toSet();
  }

  String _sanitizeSearchTerms(String query) {
    final tokens = query
        .replaceAll(RegExp(r'[^\w\s-]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !_stopWords.contains(w.toLowerCase()))
        .take(6)
        .toList();
    if (tokens.isEmpty) return query.trim();
    return tokens.join(' ');
  }

  String _extractPrimaryTopic(String query) {
    final tokens = query
        .replaceAll(RegExp(r'[^\w\s-]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !_stopWords.contains(w.toLowerCase()))
        .take(3)
        .toList();
    if (tokens.isEmpty) return query.trim();
    return tokens.join(' ');
  }

  String _extractPrimaryKeyword(String query) {
    final tokens = query
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 3 && !_stopWords.contains(w.toLowerCase()))
        .toList();
    return tokens.isNotEmpty ? tokens.first : '';
  }
}
