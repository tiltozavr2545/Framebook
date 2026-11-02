/// Matches SQLite length(TEXT) for normal notes and sync's rune validation.
const maxNoteCodePoints = 10000;

bool validRatingNote(String? note) =>
    note == null || note.runes.length <= maxNoteCodePoints;
