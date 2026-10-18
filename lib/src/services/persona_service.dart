import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/storage_service.dart';
import '../models/persona.dart';

/// Production PersonaService managing the Open-Source Persona Hub.
/// Supports built-in curated personas and user-authored custom personas with offline caching
/// and optional Firestore sync for authenticated users.
class PersonaService {
  static final PersonaService instance = PersonaService._internal();

  PersonaService._internal() {
    _loadPersonas();
  }

  FirebaseFirestore? _customFirestore;
  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  bool get _canSyncFirestore => _firestore != null && _currentUser != null;

  @visibleForTesting
  set firestoreForTesting(FirebaseFirestore? fs) {
    _customFirestore = fs;
  }

  final ValueNotifier<List<Persona>> personasNotifier =
      ValueNotifier<List<Persona>>([]);

  final ValueNotifier<Persona> activePersonaNotifier =
      ValueNotifier<Persona>(Persona.curatedPersonas.first);

  void _loadPersonas() {
    final list = <Persona>[...Persona.curatedPersonas];
    try {
      final custom = StorageService.getSavedPersonas();
      for (final p in custom) {
        if (!list.any((existing) => existing.id == p.id)) {
          list.add(p);
        }
      }
    } catch (_) {}

    personasNotifier.value = list;

    // Load active persona
    final savedActiveId = StorageService.getActivePersonaId();
    if (savedActiveId != null) {
      final match = list.firstWhere(
        (p) => p.id == savedActiveId,
        orElse: () => list.first,
      );
      activePersonaNotifier.value = match;
    } else {
      activePersonaNotifier.value = list.first;
    }
  }

  Persona getPersonaById(String id) {
    final list = personasNotifier.value;
    return list.firstWhere(
      (p) => p.id == id,
      orElse: () => Persona.curatedPersonas.first,
    );
  }

  Persona? findPersonaByName(String name) {
    final clean = name.toLowerCase().replaceAll('@', '').trim();
    final list = personasNotifier.value;
    for (final p in list) {
      if (p.name.toLowerCase() == clean || p.id.toLowerCase() == clean) {
        return p;
      }
    }
    return null;
  }

  Future<void> setActivePersona(String id) async {
    final persona = getPersonaById(id);
    activePersonaNotifier.value = persona;
    await StorageService.setActivePersonaId(persona.id);
  }

  Future<Persona> createCustomPersona({
    required String name,
    required String tagline,
    required String description,
    required String systemPrompt,
    String category = 'Custom',
    List<String> tags = const [],
    List<String> starterPrompts = const [],
    double temperature = 0.7,
  }) async {
    final user = _currentUser;
    final id = 'persona_${DateTime.now().millisecondsSinceEpoch}';

    final persona = Persona(
      id: id,
      name: name.trim(),
      tagline: tagline.trim(),
      description: description.trim(),
      systemPrompt: systemPrompt.trim(),
      category: category,
      tags: tags,
      starterPrompts: starterPrompts,
      isCurated: false,
      creatorId: user?.uid ?? 'guest',
      createdAt: DateTime.now(),
      temperature: temperature,
    );

    final updated = List<Persona>.from(personasNotifier.value)..add(persona);
    personasNotifier.value = updated;

    // Persist custom personas locally
    final customOnly = updated.where((p) => !p.isCurated).toList();
    await StorageService.savePersonas(customOnly);

    // Sync to Firestore if authenticated
    if (_canSyncFirestore) {
      try {
        await _firestore?.collection('personas').doc(id).set(persona.toMap());
      } catch (_) {}
    }

    return persona;
  }

  Future<void> deleteCustomPersona(String id) async {
    final current = personasNotifier.value;
    final target = current.firstWhere((p) => p.id == id, orElse: () => current.first);
    if (target.isCurated) return; // Prevent deleting curated system personas

    final updated = current.where((p) => p.id != id).toList();
    personasNotifier.value = updated;

    final customOnly = updated.where((p) => !p.isCurated).toList();
    await StorageService.savePersonas(customOnly);

    if (activePersonaNotifier.value.id == id) {
      await setActivePersona(Persona.curatedPersonas.first.id);
    }

    if (_canSyncFirestore) {
      try {
        await _firestore?.collection('personas').doc(id).delete();
      } catch (_) {}
    }
  }
}
