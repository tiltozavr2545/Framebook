// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Framebook';

  @override
  String get tabSearch => 'Search';

  @override
  String get tabRatings => 'My ratings';

  @override
  String get tabWatchlist => 'Watchlist';

  @override
  String get tabStats => 'Stats';

  @override
  String get tabStatsPlaceholder =>
      'Statistics will be here once you have ratings.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSources => 'Sources and API keys';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get onboardingTitle => 'Welcome to Framebook';

  @override
  String get onboardingIntro =>
      'Framebook has no server: film data comes straight from TMDB, Kinopoisk and IMDb using your own free API keys. Only the TMDB key is required to start.';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingTmdbRequired => 'Add a working TMDB key to continue.';

  @override
  String get sourcesTitle => 'Sources and API keys';

  @override
  String get sourcesHowToGet => 'How to get the keys';

  @override
  String get sourceRequired => 'required';

  @override
  String get sourceOptional => 'optional';

  @override
  String get sourceTmdbName => 'TMDB';

  @override
  String get sourceTmdbDescription =>
      'Search, title details, seasons and episodes, posters, TMDB rating.';

  @override
  String get sourceTmdbHint =>
      'API Read Access Token (starts with eyJ…) or API key';

  @override
  String get sourcePoiskkinoName => 'PoiskKino';

  @override
  String get sourcePoiskkinoDescription =>
      'Kinopoisk rating. Free plan: 200 requests a day.';

  @override
  String get sourcePoiskkinoHint =>
      'Key from the @poiskkinodev_bot Telegram bot';

  @override
  String get sourceOmdbName => 'OMDb';

  @override
  String get sourceOmdbDescription =>
      'IMDb, Rotten Tomatoes and Metacritic ratings. Free plan: 1,000 requests a day.';

  @override
  String get sourceOmdbHint => 'Key from the OMDb email (activate it first)';

  @override
  String get keySave => 'Check and save';

  @override
  String get keyRemove => 'Remove';

  @override
  String get keyShow => 'Show key';

  @override
  String get keyHide => 'Hide key';

  @override
  String get keyStatusMissing => 'Not set';

  @override
  String get keyStatusChecking => 'Checking…';

  @override
  String get keyStatusValid => 'Key works';

  @override
  String get keyStatusUnverified => 'Saved, not checked: no connection';

  @override
  String get keyStatusInvalid => 'The service rejected this key';

  @override
  String get keyStatusLimit =>
      'Key works, but today\'s request limit is used up';

  @override
  String get keyStatusEmpty => 'Paste a key first';

  @override
  String get retry => 'Try again';

  @override
  String get searchHint => 'Film or series';

  @override
  String get searchClear => 'Clear';

  @override
  String get searchEmpty => 'Find a film or series by title.';

  @override
  String searchNothing(String query) {
    return 'Nothing found for “$query”.';
  }

  @override
  String get kindMovie => 'Film';

  @override
  String get kindTv => 'Series';

  @override
  String get failureOffline =>
      'No connection. Search and title pages need the internet; what was opened before is shown from the cache.';

  @override
  String get failureTmdbKey => 'TMDB rejected the key. Check it in settings.';

  @override
  String get failureNotFound => 'TMDB has no such title.';

  @override
  String get failureTmdb =>
      'TMDB didn\'t answer properly. Try again a bit later.';

  @override
  String get titleOverview => 'Overview';

  @override
  String get titleSeasons => 'Seasons';

  @override
  String get titleEpisodes => 'Episodes';

  @override
  String get tvStatusRunning => 'ongoing';

  @override
  String get tvStatusEnded => 'ended';

  @override
  String get tvStatusCanceled => 'canceled';

  @override
  String seasonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seasons',
      one: '$count season',
    );
    return '$_temp0';
  }

  @override
  String episodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodes',
      one: '$count episode',
    );
    return '$_temp0';
  }

  @override
  String seasonNumber(int number) {
    return 'Season $number';
  }

  @override
  String get seasonSpecials => 'Specials';

  @override
  String episodeNumber(int number) {
    return 'Episode $number';
  }

  @override
  String episodeCode(int season, int episode) {
    return 'S$season · E$episode';
  }

  @override
  String runtimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String runtimeHours(int hours) {
    return '$hours h';
  }

  @override
  String runtimeHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get ratingKinopoisk => 'Kinopoisk';

  @override
  String ratingVotes(String count) {
    return '$count votes';
  }

  @override
  String ratingAsOf(String date) {
    return 'as of $date';
  }

  @override
  String get ratingSeasonAverage => 'episode average';

  @override
  String get ratingNoData => 'no data';

  @override
  String get ratingNeedsKey => 'add a key';

  @override
  String get ratingOffline => 'no connection';

  @override
  String get ratingLimit => 'daily limit used up';

  @override
  String get ratingKeyRejected => 'key rejected';

  @override
  String get ratingFailed => 'source error';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutIntro =>
      'Framebook is a personal diary of film and series ratings that compares your scores with Kinopoisk, IMDb and others. It has no server: everything you rate stays on your phone.';

  @override
  String get aboutData => 'Where the data comes from';

  @override
  String get aboutTmdb =>
      'Catalog, posters, seasons and episodes, TMDB rating.';

  @override
  String get aboutPoiskkinoTitle => 'PoiskKino API';

  @override
  String get aboutPoiskkino =>
      'Kinopoisk rating. An unofficial service, not affiliated with Kinopoisk.';

  @override
  String get aboutOmdb => 'IMDb, Rotten Tomatoes and Metacritic ratings.';

  @override
  String get aboutSource => 'Source code';

  @override
  String get aboutLicenses => 'Open-source licenses';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get undo => 'Undo';

  @override
  String get ratingRate => 'Rate';

  @override
  String get ratingMine => 'My rating';

  @override
  String get ratingEdit => 'Change';

  @override
  String get ratingDelete => 'Delete';

  @override
  String get ratingDeleteTitle => 'Delete your rating?';

  @override
  String get ratingDeleteBody =>
      'The score and the note will be deleted on all your devices.';

  @override
  String get ratingEditorTitle => 'Your rating';

  @override
  String get ratingNote => 'Note';

  @override
  String get ratingSave => 'Save';

  @override
  String partsAverageSeasons(int count, String average) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Your average over $count seasons: $average',
      one: 'Your score for $count season: $average',
    );
    return '$_temp0';
  }

  @override
  String partsAverageEpisodes(int count, String average) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Your average over $count episodes: $average',
      one: 'Your score for $count episode: $average',
    );
    return '$_temp0';
  }

  @override
  String get calibrationTitle => 'How it compares';

  @override
  String get calibrationHigher => 'Half a point higher';

  @override
  String get calibrationLower => 'Half a point lower';

  @override
  String calibrationSame(String score) {
    return 'Also $score';
  }

  @override
  String calibrationAbove(String score) {
    return 'A step above · $score';
  }

  @override
  String calibrationBelow(String score) {
    return 'A step below · $score';
  }

  @override
  String get calibrationNothing =>
      'Nothing else of this kind is rated near this score.';

  @override
  String get watchlistAdd => 'Want to watch';

  @override
  String get watchlistListed => 'On the watchlist';

  @override
  String get watchlistRemove => 'Remove from the watchlist';

  @override
  String watchlistRemoved(String title) {
    return '“$title” removed from the watchlist';
  }

  @override
  String get watchlistEmpty =>
      'Nothing here yet. Open a film or a series and tap “Want to watch”.';

  @override
  String get ratingsSort => 'Sort';

  @override
  String get ratingsSortDate => 'By date rated';

  @override
  String get ratingsSortScore => 'By my score';

  @override
  String get ratingsSortYear => 'By year';

  @override
  String get ratingsSortTitle => 'By title';

  @override
  String get ratingsEmpty =>
      'You haven\'t rated anything yet. Find a film in Search and give it a score.';

  @override
  String get ratingsEmptyKind => 'Nothing of this kind is rated yet.';

  @override
  String get kindAll => 'All';

  @override
  String get kindMovies => 'Films';

  @override
  String get kindSeries => 'Series';

  @override
  String get kindSeasons => 'Seasons';

  @override
  String get kindEpisodes => 'Episodes';
}
