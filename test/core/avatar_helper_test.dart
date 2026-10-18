import 'package:chatbud/src/core/avatar_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AvatarHelper Abbreviation & Initials Tests', () {
    test('Single name returns first letter (e.g. Sandeep -> S)', () {
      expect(getInitials('Sandeep', ''), 'S');
      expect(getInitials('Sandeep', 'sandy.competent@gmail.com'), 'S');
    });

    test('Full name returns first letters of first and last name (e.g. Sandeep Malviya -> SM)', () {
      expect(getInitials('Sandeep Malviya', ''), 'SM');
      expect(getInitials('Sandeep Malviya', 'sandy.competent@gmail.com'), 'SM');
    });

    test('Dotted email without display name returns SC (e.g. sandy.competent@gmail.com -> SC)', () {
      expect(getInitials('', 'sandy.competent@gmail.com'), 'SC');
      expect(getInitials('Guest User', 'sandy.competent@gmail.com'), 'SC');
      expect(getInitials('Guest', 'sandy.competent@gmail.com'), 'SC');
    });

    test('Simple email without dot returns first letter (e.g. sandeep@gmail.com -> S)', () {
      expect(getInitials('', 'sandeep@gmail.com'), 'S');
      expect(getInitials('Guest User', 'sandeep@gmail.com'), 'S');
    });

    test('getAvatarColor returns deterministic color for seed string', () {
      final color1 = getAvatarColor('Sandeep');
      final color2 = getAvatarColor('Sandeep');
      expect(color1, color2);

      final color3 = getAvatarColor('Sandeep Malviya');
      expect(color3, isNotNull);
    });
  });
}
