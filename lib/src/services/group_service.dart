import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/group_chat.dart';

/// Production GroupService backed by Cloud Firestore.
/// Real-time sync for group channels, creation, and membership.
class GroupService {
  static final GroupService instance = GroupService._internal();
  GroupService._internal() {
    _initFirestoreListener();
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

  @visibleForTesting
  set firestoreForTesting(FirebaseFirestore? fs) {
    _customFirestore = fs;
  }

  final ValueNotifier<List<GroupChat>> groupsNotifier =
      ValueNotifier<List<GroupChat>>([]);

  void _initFirestoreListener() {
    final fs = _firestore;
    if (fs == null) return;
    try {
      fs
          .collection('groups')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          final groups = snapshot.docs.map((doc) {
            final data = doc.data();
            return GroupChat(
              id: doc.id,
              name: data['name'] as String? ?? 'Group',
              description: data['description'] as String? ?? '',
              memberCount: (data['memberCount'] as num?)?.toInt() ?? 1,
              lastActive: data['lastActive'] as String? ?? 'Active',
              isJoined: data['isJoined'] as bool? ?? false,
            );
          }).toList();

          groupsNotifier.value = groups;
        },
        onError: (_) {
          // Offline fallback
        },
      );
    } catch (_) {
      // Offline fallback
    }
  }

  Future<GroupChat> createGroup({
    required String name,
    required String description,
    String? creatorId,
  }) async {
    final newGroup = GroupChat(
      id: 'grp_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      description: description.trim(),
      memberCount: 1,
      lastActive: 'Just now',
      isJoined: true,
    );

    // Optimistically add to local state
    groupsNotifier.value = [newGroup, ...groupsNotifier.value];

    // Persist to Cloud Firestore
    final fs = _firestore;
    if (fs != null) {
      try {
        await fs.collection('groups').doc(newGroup.id).set({
          'id': newGroup.id,
          'name': newGroup.name,
          'description': newGroup.description,
          'memberCount': 1,
          'members': creatorId != null ? [creatorId] : [],
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': 'Just now',
        });
      } catch (_) {}
    }

    return newGroup;
  }

  Future<void> toggleJoinGroup(String groupId, {String? userId}) async {
    final current = List<GroupChat>.from(groupsNotifier.value);
    final idx = current.indexWhere((g) => g.id == groupId);
    if (idx != -1) {
      final grp = current[idx];
      final willJoin = !grp.isJoined;
      current[idx] = grp.copyWith(
        isJoined: willJoin,
        memberCount: willJoin ? grp.memberCount + 1 : grp.memberCount - 1,
      );
      groupsNotifier.value = current;

      final fs = _firestore;
      if (fs != null) {
        try {
          final docRef = fs.collection('groups').doc(groupId);
          if (willJoin) {
            await docRef.update({
              'memberCount': FieldValue.increment(1),
              if (userId != null) 'members': FieldValue.arrayUnion([userId]),
            });
          } else {
            await docRef.update({
              'memberCount': FieldValue.increment(-1),
              if (userId != null) 'members': FieldValue.arrayRemove([userId]),
            });
          }
        } catch (_) {}
      }
    }
  }
}
