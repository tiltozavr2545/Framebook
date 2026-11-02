import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show StringCharacters;
import '../data/library/rating_note.dart';

/// Enforces the storage limit without splitting a visible character.
class NoteLengthFormatter extends TextInputFormatter {
  const NoteLengthFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) {
      return newValue;
    }
    if (validRatingNote(newValue.text)) return newValue;
    final kept = StringBuffer();
    var count = 0;
    for (final character in newValue.text.characters) {
      final length = character.runes.length;
      if (count + length > maxNoteCodePoints) break;
      count += length;
      kept.write(character);
    }
    final text = kept.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: min(max(0, newValue.selection.extentOffset), text.length),
      ),
    );
  }
}
