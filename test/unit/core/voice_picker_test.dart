import 'package:flutter_test/flutter_test.dart';
import 'package:wonderly/core/services/voice_picker.dart';

Map<String, String> _voice(
  String name, {
  String locale = 'en-US',
  String quality = 'default',
  String identifier = '',
}) => {
  'name': name,
  'locale': locale,
  'quality': quality,
  'identifier': identifier,
};

void main() {
  group('VoicePicker', () {
    test('prefers a premium voice over the default one', () {
      final best = VoicePicker.best([
        _voice('Samantha'),
        _voice(
          'Ava',
          quality: 'premium',
          identifier: 'com.apple.voice.premium.en-US.Ava',
        ),
        _voice('Allison', quality: 'enhanced'),
      ]);
      expect(best?['name'], 'Ava');
    });

    test('prefers enhanced over default', () {
      final best = VoicePicker.best([
        _voice('Samantha'),
        _voice('Nicky', quality: 'enhanced'),
      ]);
      expect(best?['name'], 'Nicky');
    });

    test('never picks a novelty voice', () {
      final best = VoicePicker.best([_voice('Zarvox'), _voice('Fred')]);
      expect(best, isNull);
    });

    test('skips voices that are not English', () {
      final best = VoicePicker.best([
        _voice('Amelie', locale: 'fr-FR', quality: 'premium'),
        _voice('Samantha'),
      ]);
      expect(best?['name'], 'Samantha');
    });

    test('skips voices that need the internet', () {
      final best = VoicePicker.best([
        _voice('en-us-x-tpd-network'),
        _voice('en-us-x-tpd-local'),
      ]);
      expect(best?['name'], 'en-us-x-tpd-local');
    });

    test('prefers US English at equal quality', () {
      final best = VoicePicker.best([
        _voice('Daniel', locale: 'en-GB'),
        _voice('Samantha'),
      ]);
      expect(best?['name'], 'Samantha');
    });

    test('accepts underscore locales and ignores junk entries', () {
      final best = VoicePicker.best([
        'not a map',
        null,
        _voice('Samantha', locale: 'en_US'),
      ]);
      expect(best?['name'], 'Samantha');
    });

    test('returns null for an empty list', () {
      expect(VoicePicker.best(const []), isNull);
    });
  });
}
