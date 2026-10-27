import '../work_key.dart';

// TMDB renumbering (docs/data-model.md, "When TMDB renumbers"): a season's or
// an episode's key is built from its numbers, so when TMDB moves specials or
// merges a double episode, a rating stays on a number that now means another
// title. The rated title's own TMDB id, stored in `works.tmdb_id`, tells
// where it went. Detection compares what is stored with what a screen
// already loaded; nothing here asks the network.

/// A live rating of a season or an episode: its key, the TMDB id stored with
/// its snapshot, and the score (for the "which one to keep" question).
final class RatedPart {
  const RatedPart({
    required this.key,
    required this.tmdbId,
    required this.scoreHalf,
  });

  final WorkKey key;

  /// The season's or episode's own TMDB id; the series' id when it was never
  /// known (the stand-in in `works.tmdb_id`).
  final int tmdbId;
  final int scoreHalf;

  /// Whether [tmdbId] is the stand-in rather than the title's own id.
  bool get idUnknown => tmdbId == key.tmdbId;
}

/// A rating that should follow its title from [from] to [to].
final class RenumberMove {
  const RenumberMove(this.from, this.to);

  final WorkKey from;
  final WorkKey to;

  @override
  bool operator ==(Object other) =>
      other is RenumberMove && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => '$from → $to';
}

/// Moves that depend on each other and are answered together: a shift
/// (E1 → E2 while E2 → E3) or a swap only works if every move in it is
/// applied at once.
final class Renumbering {
  const Renumbering(this.moves, this.conflicts);

  /// In key order.
  final List<RenumberMove> moves;

  /// Targets that already have a live rating that isn't moving away: the
  /// user picks which score stays there.
  final Set<WorkKey> conflicts;

  bool touches(WorkKey key) => moves.any((m) => m.from == key || m.to == key);

  RenumberMove moveTo(WorkKey target) =>
      moves.firstWhere((m) => m.to == target);
}

/// Proposes moves for [rated] seasons or episodes, given what TMDB [current]ly
/// has under each number it just answered with (one season's episodes, or a
/// series' seasons): key → own TMDB id, `null` when TMDB sent none.
///
/// A rated title moves when its stored id now sits under another number of
/// the same series and kind. It stays when its id is unknown, still under
/// its own number, or not in [current] at all (it vanished, or it lives in a
/// season that wasn't loaded — detected when that season is opened). When
/// two rated titles claim the same target, the first in key order moves and
/// the other is proposed again once the target is rated.
List<Renumbering> proposeRenumbering({
  required Iterable<RatedPart> rated,
  required Map<WorkKey, int?> current,
}) {
  final byId = <int, WorkKey>{
    for (final MapEntry(:key, :value) in current.entries)
      if (value != null) value: key,
  };
  final parts = [...rated]..sort((a, b) => _compareKeys(a.key, b.key));
  final ratedKeys = {for (final part in parts) part.key};

  final moves = <RenumberMove>[];
  final claimed = <WorkKey>{};
  for (final part in parts) {
    if (part.idUnknown) continue;
    final target = byId[part.tmdbId];
    if (target == null || target == part.key) continue;
    // Ids of seasons and episodes are separate TMDB tables and may collide;
    // a rating never crosses into another series either.
    if (target.kind != part.key.kind || target.tmdbId != part.key.tmdbId) {
      continue;
    }
    if (!claimed.add(target)) continue;
    moves.add(RenumberMove(part.key, target));
  }

  // Group moves that share a key: union-find over the keys.
  final parent = <WorkKey, WorkKey>{};
  WorkKey find(WorkKey key) {
    var root = key;
    while (parent[root]! != root) {
      root = parent[root]!;
    }
    parent[key] = root;
    return root;
  }

  for (final move in moves) {
    parent.putIfAbsent(move.from, () => move.from);
    parent.putIfAbsent(move.to, () => move.to);
    final a = find(move.from);
    final b = find(move.to);
    if (a != b) parent[b] = a;
  }

  final sources = {for (final move in moves) move.from};
  final groups = <WorkKey, List<RenumberMove>>{};
  for (final move in moves) {
    groups.putIfAbsent(find(move.from), () => []).add(move);
  }
  final result = [
    for (final group in groups.values)
      Renumbering(group, {
        for (final move in group)
          if (ratedKeys.contains(move.to) && !sources.contains(move.to))
            move.to,
      }),
  ];
  result.sort((a, b) => _compareKeys(a.moves.first.from, b.moves.first.from));
  return result;
}

/// Seasons and episodes in number order.
int _compareKeys(WorkKey a, WorkKey b) {
  final bySeries = a.tmdbId.compareTo(b.tmdbId);
  if (bySeries != 0) return bySeries;
  final bySeason = (a.season ?? -1).compareTo(b.season ?? -1);
  if (bySeason != 0) return bySeason;
  return (a.episode ?? -1).compareTo(b.episode ?? -1);
}
