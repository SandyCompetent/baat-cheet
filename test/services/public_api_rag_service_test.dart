import 'dart:convert';
import 'package:chatbud/main.dart';
import 'package:chatbud/route_generator.dart';
import 'package:chatbud/src/core/storage_service.dart';
import 'package:chatbud/src/models/chat_message.dart';
import 'package:chatbud/src/models/rag_citation.dart';
import 'package:chatbud/src/services/memory_service.dart';
import 'package:chatbud/src/services/public_api_rag_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    PublicApiRagService.instance.clearCache();
  });

  tearDown(() {
    PublicApiRagService.instance.httpClientForTesting = null;
    PublicApiRagService.instance.clearCache();
  });

  group('RagCitation & RagGroundingResult Models', () {
    test('serializes and formats system prompt block accurately', () {
      const citation = RagCitation(
        sourceName: 'OpenAlex',
        title: 'Attention Is All You Need (2017)',
        url: 'https://doi.org/10.48550/arXiv.1706.03762',
        snippet:
            'Authors: Vaswani et al. | Published: 2017 | Citations: 120000.',
        category: 'Academic',
      );

      final map = citation.toStringMap();
      final roundTrip = RagCitation.fromMap(map);
      expect(roundTrip.sourceName, 'OpenAlex');
      expect(roundTrip.title, 'Attention Is All You Need (2017)');
      expect(roundTrip.category, 'Academic');

      final result = RagGroundingResult(
        personaId: 'exeter',
        query: 'transformer architecture',
        citations: const [citation],
        retrievedAt: DateTime(2026, 10, 23),
      );

      expect(result.hasContext, isTrue);
      expect(result.toSourceMaps().length, 1);
      final promptBlock = result.toSystemPromptBlock();
      expect(
        promptBlock,
        contains('=== LIVE GROUNDED RAG DATA (VERIFIED PUBLIC APIs) ==='),
      );
      expect(promptBlock, contains('[OpenAlex] Attention Is All You Need'));
    });

    test('ChatMessage preserves ragSources across toMap and fromMap', () {
      final msg = ChatMessage(
        id: 'm1',
        text: 'Grounded answer',
        isUser: false,
        senderName: 'Exeter Academic',
        timestamp: DateTime(2026, 10, 23, 14, 30),
        ragSources: const [
          {
            'sourceName': 'OpenAlex',
            'title': 'Neural Networks (2025)',
            'url': 'https://openalex.org/W123',
            'snippet': 'Citations: 42',
            'category': 'Academic',
          },
        ],
      );

      final serialized = msg.toMap();
      final restored = ChatMessage.fromMap(serialized);
      expect(restored.ragSources, isNotNull);
      expect(restored.ragSources!.first['sourceName'], 'OpenAlex');
      expect(restored.ragSources!.first['title'], 'Neural Networks (2025)');
    });
  });

  group('PublicApiRagService Persona Retrievers', () {
    test('Exeter Academic retrieves OpenAlex, Open-Meteo, and UK Holidays',
        () async {
      PublicApiRagService.instance.httpClientForTesting =
          MockClient((req) async {
        if (req.url.host == 'api.openalex.org') {
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'title': 'Deep Learning in Higher Education',
                  'publication_year': 2025,
                  'cited_by_count': 88,
                  'doi': 'https://doi.org/10.1000/exeter.2025',
                  'authorships': [
                    {
                      'author': {'display_name': 'Dr. Jane Smith'},
                    },
                  ],
                },
              ],
            }),
            200,
          );
        }
        if (req.url.host == 'api.open-meteo.com') {
          return http.Response(
            jsonEncode({
              'current_weather': {'temperature': 14.5, 'windspeed': 11.2},
            }),
            200,
          );
        }
        if (req.url.host == 'www.gov.uk') {
          return http.Response(
            jsonEncode({
              'england-and-wales': {
                'events': [
                  {'title': 'Christmas Day', 'date': '2099-12-25'},
                ],
              },
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final res = await PublicApiRagService.instance.retrieveGroundingContext(
        personaId: 'exeter',
        query: 'deep learning weather on Exeter campus and bank holiday term',
      );

      expect(res.hasContext, isTrue);
      expect(res.citations.length, 3);
      expect(
        res.citations.map((c) => c.sourceName),
        containsAll(['OpenAlex', 'Open-Meteo', 'GOV.UK Calendar']),
      );
    });

    test('Athena retrieves EndOfLife.date lifecycle and Wikipedia summary',
        () async {
      PublicApiRagService.instance.httpClientForTesting =
          MockClient((req) async {
        if (req.url.host == 'endoflife.date') {
          return http.Response(
            jsonEncode([
              {
                'cycle': '3.29',
                'latest': '3.29.2',
                'eol': false,
                'lts': true,
              },
            ]),
            200,
          );
        }
        if (req.url.host == 'en.wikipedia.org') {
          return http.Response(
            jsonEncode({
              'title': 'Microservices',
              'extract':
                  'Microservices are an architectural style that structures an application as a collection of services.',
              'content_urls': {
                'desktop': {
                  'page': 'https://en.wikipedia.org/wiki/Microservices'
                },
              },
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final res = await PublicApiRagService.instance.retrieveGroundingContext(
        personaId: 'athena',
        query: 'flutter microservices architecture',
      );

      expect(res.hasContext, isTrue);
      expect(
        res.citations.map((c) => c.sourceName),
        containsAll(['EndOfLife.date', 'Wikipedia']),
      );
    });

    test('Cipher retrieves Google OSV vulnerabilities and EndOfLife data',
        () async {
      PublicApiRagService.instance.httpClientForTesting =
          MockClient((req) async {
        if (req.url.host == 'api.osv.dev') {
          return http.Response(
            jsonEncode({
              'vulns': [
                {
                  'id': 'GHSA-xxxx-yyyy-zzzz',
                  'summary': 'Prototype pollution in lodash',
                },
              ],
            }),
            200,
          );
        }
        if (req.url.host == 'endoflife.date') {
          return http.Response(
            jsonEncode([
              {
                'cycle': '22',
                'latest': '22.4.0',
                'eol': '2027-04-30',
                'lts': true
              },
            ]),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final res = await PublicApiRagService.instance.retrieveGroundingContext(
        personaId: 'cipher',
        query: 'nodejs npm security audit',
      );

      expect(res.hasContext, isTrue);
      expect(
        res.citations.map((c) => c.sourceName),
        containsAll(['Google OSV', 'EndOfLife.date']),
      );
    });

    test('Harper and Leo retrieve Arbeitnow and RemoteOK job/salary data',
        () async {
      PublicApiRagService.instance.httpClientForTesting =
          MockClient((req) async {
        if (req.url.host == 'www.arbeitnow.com') {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'title': 'Senior Flutter Engineer',
                  'company_name': 'TechCorp',
                  'location': 'London',
                  'remote': true,
                  'url': 'https://www.arbeitnow.com/jobs/1',
                  'tags': ['Flutter', 'Dart', 'Firebase'],
                },
              ],
            }),
            200,
          );
        }
        if (req.url.host == 'remoteok.com') {
          return http.Response(
            jsonEncode([
              {'legal': 'RemoteOK API'},
              {
                'position': 'Staff Mobile Engineer',
                'company': 'GlobalAI',
                'location': 'Worldwide',
                'salary_min': 140,
                'salary_max': 185,
                'url': 'https://remoteok.com/remote-jobs/1',
              },
            ]),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final leoRes =
          await PublicApiRagService.instance.retrieveGroundingContext(
        personaId: 'leo',
        query: 'flutter engineer salary negotiation',
      );
      expect(leoRes.hasContext, isTrue);
      expect(
        leoRes.citations.map((c) => c.sourceName),
        containsAll(['RemoteOK', 'Arbeitnow']),
      );
    });

    test('Aria, Marcus, and Nova retrieve live grounding from their APIs',
        () async {
      PublicApiRagService.instance.httpClientForTesting =
          MockClient((req) async {
        if (req.url.host == 'date.nager.at') {
          return http.Response(
            jsonEncode([
              {
                'name': 'Good Friday',
                'countryCode': 'GB',
                'date': '2027-03-26'
              },
            ]),
            200,
          );
        }
        if (req.url.host == 'stoic-quotes.com') {
          return http.Response(
            jsonEncode({
              'text': 'The impediment to action advances action.',
              'author': 'Marcus Aurelius',
            }),
            200,
          );
        }
        if (req.url.host == 'api.datamuse.com') {
          return http.Response(
            jsonEncode([
              {'word': 'luminary'},
              {'word': 'radiant'},
            ]),
            200,
          );
        }
        if (req.url.host == 'api.dictionaryapi.dev') {
          return http.Response(
            jsonEncode([
              {
                'meanings': [
                  {
                    'partOfSpeech': 'noun',
                    'definitions': [
                      {
                        'definition':
                            'A person who inspires or influences others.'
                      },
                    ],
                  },
                ],
              },
            ]),
            200,
          );
        }
        if (req.url.host == 'en.wikipedia.org') {
          return http.Response(
            jsonEncode({
              'title': 'Stoicism',
              'extract': 'Stoicism is a school of Hellenistic philosophy.',
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final ariaRes =
          await PublicApiRagService.instance.retrieveGroundingContext(
        personaId: 'aria',
        query: 'plan Q2 executive schedule',
      );
      expect(
          ariaRes.citations.map((c) => c.sourceName), contains('Nager.Date'));

      final marcusRes =
          await PublicApiRagService.instance.retrieveGroundingContext(
        personaId: 'marcus',
        query: 'how to handle adversity with stoicism',
      );
      expect(
        marcusRes.citations.map((c) => c.sourceName),
        contains('Stoic Quotes'),
      );

      final novaRes =
          await PublicApiRagService.instance.retrieveGroundingContext(
        personaId: 'nova',
        query: 'brand naming for beacon',
      );
      expect(
        novaRes.citations.map((c) => c.sourceName),
        containsAll(['Datamuse Lexical Engine', 'Free Dictionary']),
      );
    });

    test(
        'Dedicated Grounded RAG Engine personas (weather_rag, holiday_rag, openalex_rag, wiki_rag) retrieve live data',
        () async {
      PublicApiRagService.instance.httpClientForTesting =
          MockClient((req) async {
        if (req.url.host == 'api.open-meteo.com') {
          return http.Response(
            jsonEncode({
              'current_weather': {'temperature': 19.2, 'windspeed': 8.4},
            }),
            200,
          );
        }
        if (req.url.host == 'date.nager.at') {
          return http.Response(
            jsonEncode([
              {'name': 'Boxing Day', 'countryCode': 'GB', 'date': '2099-12-26'},
            ]),
            200,
          );
        }
        if (req.url.host == 'www.gov.uk') {
          return http.Response(
            jsonEncode({
              'england-and-wales': {
                'events': [
                  {'title': 'New Year\'s Day', 'date': '2099-01-01'},
                ],
              },
            }),
            200,
          );
        }
        if (req.url.host == 'api.openalex.org') {
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'title': 'Grounded Agents Survey',
                  'publication_year': 2026,
                  'cited_by_count': 42,
                  'doi': 'https://doi.org/10.1000/rag.2026',
                },
              ],
            }),
            200,
          );
        }
        if (req.url.host == 'en.wikipedia.org') {
          return http.Response(
            jsonEncode({
              'title': 'Turing machine',
              'extract': 'A mathematical model of computation.',
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final weatherRes =
          await PublicApiRagService.instance.retrieveGroundingContext(
        personaId: 'weather_rag',
        query: 'live weather in Tokyo',
      );
      expect(weatherRes.hasContext, isTrue);
      expect(weatherRes.citations.first.title, contains('Tokyo, Japan'));

      final holidayRes =
          await PublicApiRagService.instance.retrieveGroundingContext(
        personaId: 'holiday_rag',
        query: 'upcoming UK and global holidays',
      );
      expect(
        holidayRes.citations.map((c) => c.sourceName),
        containsAll(['Nager.Date', 'GOV.UK Calendar']),
      );

      final openAlexRes =
          await PublicApiRagService.instance.retrieveGroundingContext(
        personaId: 'openalex_rag',
        query: 'grounded agents',
      );
      expect(openAlexRes.citations.first.sourceName, 'OpenAlex');

      final wikiRes =
          await PublicApiRagService.instance.retrieveGroundingContext(
        personaId: 'wiki_rag',
        query: 'Turing machine',
      );
      expect(
        wikiRes.citations.map((c) => c.sourceName),
        containsAll(['Wikipedia', 'OpenAlex']),
      );
    });

    test('MemoryService.buildSystemPrompt injects ragContextBlock', () {
      final prompt = MemoryService.instance.buildSystemPrompt(
        basePrompt: 'You are Exeter Academic.',
        personaId: 'exeter',
        currentQuery: 'quantum computing',
        ragContextBlock:
            '=== LIVE GROUNDED RAG DATA (VERIFIED PUBLIC APIs) ===\n1. [OpenAlex] Quantum Paper',
      );

      expect(prompt, contains('You are Exeter Academic.'));
      expect(prompt, contains('=== CONTEXT & LONG-TERM MEMORY ==='));
      expect(
        prompt,
        contains('=== LIVE GROUNDED RAG DATA (VERIFIED PUBLIC APIs) ==='),
      );
      expect(prompt, contains('[OpenAlex] Quantum Paper'));
    });

    test('PublicApiRagService persists and restores APILayer / Public API Key',
        () async {
      await PublicApiRagService.instance.setApiKey('apilayer_test_key_123');
      expect(PublicApiRagService.instance.hasCustomApiKey, isTrue);
      expect(PublicApiRagService.instance.apiKey, 'apilayer_test_key_123');
      expect(StorageService.getPublicApiKey(), 'apilayer_test_key_123');

      await PublicApiRagService.instance.setApiKey('');
      expect(PublicApiRagService.instance.hasCustomApiKey, isFalse);
      expect(StorageService.getPublicApiKey(), isNull);
    });
  });

  group('Flutter Web RouteGenerator White-Screen Prevention', () {
    testWidgets(
        'RouteGenerator maps /, /index.html, and query-param routes to MyHomePage instead of SizedBox.shrink',
        (tester) async {
      for (final routeName in [
        '/',
        '',
        '/index.html',
        '/?code=123',
        '/unknown'
      ]) {
        final route = RouteGenerator.generateRoute(
          RouteSettings(name: routeName),
        ) as MaterialPageRoute;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (ctx) => route.builder(ctx),
            ),
          ),
        );
        expect(find.byType(MyHomePage), findsOneWidget);
      }
    });
  });
}
