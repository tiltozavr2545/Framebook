import '../../source_failure.dart';
import 'tmdb_models.dart';

/// An actor on a card: who, as whom.
final class CastMember {
  const CastMember({
    required this.personId,
    required this.name,
    required this.character,
    required this.profilePath,
  });

  final int personId;
  final String name;

  /// The role; TMDB sometimes has none.
  final String? character;
  final String? profilePath;
}

/// The jobs a card names — the rest of a crew list (grips, accountants) is
/// noise on a phone.
enum CrewRole { creator, director, writer, composer, cinematographer }

final class CrewMember {
  const CrewMember({
    required this.personId,
    required this.name,
    required this.role,
  });

  final int personId;
  final String name;
  final CrewRole role;
}

/// A card's cast and its key crew: `credits` of a film, a series or a
/// season (not `aggregate_credits` — 350 KB for Game of Thrones), an
/// episode's own credits with its guest stars.
final class Credits {
  const Credits({this.cast = const [], this.crew = const []});

  /// [json] is the `credits` object; [createdBy] is a series' `created_by`.
  /// An episode's [guestStars] go after its regular cast.
  factory Credits.fromJson(
    Json? json, {
    List<Json> createdBy = const [],
    bool guestStars = false,
  }) {
    if (json == null && createdBy.isEmpty) return const Credits();
    final cast = <CastMember>[];
    final seen = <int>{};
    for (final person in [
      ...?json?.objects('cast'),
      if (guestStars) ...?json?.objects('guest_stars'),
    ]) {
      final id = person.integer('id');
      final name = person.string('name');
      if (id == null || name == null || !seen.add(id)) continue;
      cast.add(
        CastMember(
          personId: id,
          name: name,
          character: person.string('character'),
          profilePath: person.string('profile_path'),
        ),
      );
    }
    final crew = <CrewMember>[];
    final named = <(int, CrewRole)>{};
    void add(Json person, CrewRole role) {
      final id = person.integer('id');
      final name = person.string('name');
      if (id == null || name == null || !named.add((id, role))) return;
      crew.add(CrewMember(personId: id, name: name, role: role));
    }

    for (final person in createdBy) {
      add(person, CrewRole.creator);
    }
    for (final person in json?.objects('crew') ?? const <Json>[]) {
      if (_roleOf(person.string('job')) case final role?) add(person, role);
    }
    crew.sort((a, b) => a.role.index.compareTo(b.role.index));
    return Credits(cast: cast, crew: crew);
  }

  final List<CastMember> cast;
  final List<CrewMember> crew;

  bool get isEmpty => cast.isEmpty && crew.isEmpty;

  /// Crew grouped by role, in [CrewRole] order.
  Map<CrewRole, List<CrewMember>> get crewByRole => {
    for (final role in CrewRole.values)
      if (crew.where((c) => c.role == role).toList() case final people
          when people.isNotEmpty)
        role: people,
  };

  static CrewRole? _roleOf(String? job) => switch (job) {
    'Director' => CrewRole.director,
    'Screenplay' || 'Writer' || 'Teleplay' => CrewRole.writer,
    'Original Music Composer' || 'Music' => CrewRole.composer,
    'Director of Photography' => CrewRole.cinematographer,
    _ => null,
  };
}

/// One title in a person's filmography, with what they did on it.
final class PersonCredit {
  const PersonCredit({required this.title, required this.roles});

  final TitleSummary title;

  /// Characters for an actor, jobs for the crew; several when a person did
  /// more than one thing on the same title.
  final List<String> roles;
}

/// A person's page: who they are and what they made.
final class Person {
  const Person({
    required this.id,
    required this.name,
    required this.biography,
    required this.birthday,
    required this.deathday,
    required this.placeOfBirth,
    required this.profilePath,
    required this.acting,
    required this.crew,
  });

  factory Person.fromJson(Json json) {
    final id = json.integer('id');
    if (id == null || id <= 0) {
      throw const SourceException(SourceFailure.failed, 'person without id');
    }
    final credits = json.object('combined_credits');
    return Person(
      id: id,
      name: json.string('name') ?? '',
      biography: json.string('biography'),
      birthday: json.string('birthday'),
      deathday: json.string('deathday'),
      placeOfBirth: json.string('place_of_birth'),
      profilePath: json.string('profile_path'),
      acting: _filmography(credits?.objects('cast'), 'character'),
      crew: _filmography(credits?.objects('crew'), 'job'),
    );
  }

  final int id;
  final String name;
  final String? biography;

  /// `YYYY-MM-DD`.
  final String? birthday;
  final String? deathday;
  final String? placeOfBirth;
  final String? profilePath;

  /// Newest first; undated (announced) titles on top.
  final List<PersonCredit> acting;
  final List<PersonCredit> crew;

  /// Talk shows, news and award ceremonies where someone appears as
  /// themselves would bury the actual films.
  static const _selfGenres = {10763, 10767};

  static List<PersonCredit> _filmography(List<Json>? items, String roleField) {
    final byKey = <String, ({TitleSummary title, List<String> roles})>{};
    for (final item in items ?? const <Json>[]) {
      final title = TitleSummary.fromSearchJson(item);
      if (title == null) continue;
      if (title.genreIds.any(_selfGenres.contains)) continue;
      final role = item.string(roleField);
      final entry = byKey.putIfAbsent(
        title.key.toString(),
        () => (title: title, roles: <String>[]),
      );
      if (role != null && !entry.roles.contains(role)) entry.roles.add(role);
    }
    final list = [
      for (final entry in byKey.values)
        PersonCredit(title: entry.title, roles: entry.roles),
    ];
    list.sort((a, b) {
      final da = a.title.releaseDate;
      final db = b.title.releaseDate;
      if (da == db) return a.title.title.compareTo(b.title.title);
      if (da == null) return -1;
      if (db == null) return 1;
      return db.compareTo(da);
    });
    return list;
  }
}
