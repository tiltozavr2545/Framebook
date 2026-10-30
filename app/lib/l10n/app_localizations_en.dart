// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String updateAvailable(String version) {
    return 'Update $version is available';
  }

  @override
  String get updateOpen => 'Open release';

  @override
  String get updateDismiss => 'Dismiss';

  @override
  String get updateCheck => 'Check for updates';

  @override
  String get updateFound => 'An update is available';

  @override
  String get updateCurrent => 'You have the latest version';

  @override
  String get updateFailed => 'Could not check for updates';

  @override
  String get coverOpen => 'Open full-screen cover';

  @override
  String get appTitle => 'Framebook';

  @override
  String get tabSearch => 'Discover';

  @override
  String get tabRatings => 'My ratings';

  @override
  String get tabWatchlist => 'Watchlist';

  @override
  String get tabStats => 'Stats';

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
  String get sourceTmdbComputer =>
      'Register your TMDB account and API key on a computer, not a phone.';

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
  String renumberEpisode(String from, String to) {
    return 'Your rating of $from was for an episode that is now $to. Move it?';
  }

  @override
  String renumberSeason(String from, String to) {
    return 'Your rating of $from was for a season that is now $to. Move it?';
  }

  @override
  String renumberManyEpisodes(String moves) {
    return 'Your ratings were for episodes that are now numbered differently: $moves. Move them?';
  }

  @override
  String renumberManySeasons(String moves) {
    return 'Your ratings were for seasons that are now numbered differently: $moves. Move them?';
  }

  @override
  String renumberConflictEpisode(
    String fromScore,
    String from,
    String to,
    String toScore,
  ) {
    return 'Your $fromScore for $from was for the episode that is now $to, which you rated $toScore. Which score to keep?';
  }

  @override
  String renumberConflictSeason(
    String fromScore,
    String from,
    String to,
    String toScore,
  ) {
    return 'Your $fromScore for $from was for the season that is now $to, which you rated $toScore. Which score to keep?';
  }

  @override
  String get renumberMove => 'Move';

  @override
  String get renumberKeep => 'Keep';

  @override
  String renumberKeepScore(String score) {
    return 'Keep $score';
  }

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

  @override
  String get ratingsSortDivergence => 'By divergence';

  @override
  String ratingDivergence(String value) {
    return 'mine minus theirs: $value';
  }

  @override
  String get divergenceFurthest => 'Furthest apart';

  @override
  String get divergenceHigher => 'I rate higher';

  @override
  String get divergenceLower => 'I rate lower';

  @override
  String coverageLoaded(String source, int loaded, int total) {
    return '$source ratings loaded for $loaded of $total';
  }

  @override
  String coverageNeedsKey(String source) {
    return 'Add a key in Sources to compare with $source';
  }

  @override
  String get statsEmpty => 'Statistics will be here once you have ratings.';

  @override
  String statsRatingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ratings',
      one: '$count rating',
    );
    return '$_temp0';
  }

  @override
  String get statsDistribution => 'Your scores';

  @override
  String get statsCompared => 'Compared with others';

  @override
  String get statsComparedHint =>
      'Your score minus theirs: “+” means you rate higher.';

  @override
  String get statsDeviationOnAverage => 'on average';

  @override
  String statsDeviationAbsolute(String value) {
    return '$value apart either way';
  }

  @override
  String statsDeviationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'over $count ratings',
      one: 'over $count rating',
    );
    return '$_temp0';
  }

  @override
  String statsDeviationNone(String source) {
    return 'Nothing to compare with yet: no $source ratings.';
  }

  @override
  String get statsGenres => 'By genre';

  @override
  String get statsGenresOffline =>
      'Genre names come from TMDB, and there is no connection right now.';

  @override
  String get statsDecades => 'By decade';

  @override
  String statsDecade(String decade) {
    return '${decade}s';
  }

  @override
  String get settingsSync => 'Sync and backup';

  @override
  String get syncDrive => 'Google Drive';

  @override
  String get syncIntro =>
      'Your ratings, notes and watchlist are kept in a hidden folder of your own Google Drive and merged between your devices. The app sees only that folder.';

  @override
  String get syncNotConfigured =>
      'Google sign-in isn\'t set up in this build of the app.';

  @override
  String get syncSignIn => 'Sign in with Google';

  @override
  String syncSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncInProgress => 'Syncing…';

  @override
  String syncLast(String when) {
    return 'Last synced $when';
  }

  @override
  String get syncNever => 'Not synced yet';

  @override
  String get syncErrorUnauthorized =>
      'Access to Google Drive has expired. Sign in again.';

  @override
  String get syncErrorQuota =>
      'Your Google Drive is full, so sync is paused. Everything still works on this device.';

  @override
  String get syncErrorBroken =>
      'The file in Google Drive can\'t be read. It was left as it is; you can restore a daily copy.';

  @override
  String get syncErrorTooNew =>
      'The file in Google Drive was written by a newer Framebook. Update the app to sync.';

  @override
  String get syncErrorFailed =>
      'Google Drive didn\'t answer properly. Sync will try again later.';

  @override
  String get syncSignInAgain => 'Sign in again';

  @override
  String get syncSignOut => 'Sign out';

  @override
  String get syncSignInFailed => 'Couldn\'t sign in to Google. Try again.';

  @override
  String get syncOffline => 'No connection. Try again when you\'re online.';

  @override
  String get syncFirstTitle => 'Merge with Google Drive?';

  @override
  String syncFirstBody(int device, int drive, int merged) {
    return 'Ratings on this device: $device. In Google Drive: $drive. After merging: $merged. Nothing is lost: for every title the latest change wins.';
  }

  @override
  String get syncMerge => 'Merge';

  @override
  String get syncBackups => 'Daily copies';

  @override
  String get syncBackupsHint =>
      'Google Drive keeps a copy for each of the last 7 days. Restoring one replaces everything on all your devices.';

  @override
  String get syncBackupsEmpty =>
      'No copies yet: one is made on the first sync of each day.';

  @override
  String get syncRestore => 'Restore';

  @override
  String syncRestoreTitle(String date) {
    return 'Restore the copy of $date?';
  }

  @override
  String get syncRestoreBody =>
      'Everything rated or changed after it will be undone on all your devices.';

  @override
  String get syncRestored => 'Copy restored';

  @override
  String get syncDelete => 'Delete data from Google Drive';

  @override
  String get syncDeleteTitle => 'Delete the data from Google Drive?';

  @override
  String get syncDeleteBody =>
      'The file and the daily copies will be deleted, and this device will sign out. Your ratings stay on your devices. Another device that is still signed in will put its data back on its next sync.';

  @override
  String get syncDeleted => 'Deleted from Google Drive';

  @override
  String get syncStaleTitle => 'Unsynced changes to deleted entries';

  @override
  String syncStaleBody(int count) {
    return 'Unsynced ratings and watchlist entries on this device that conflict with a newer deletion in Google Drive: $count. Keep restores these entries on your devices. Discard applies the deletion. Sync is paused until you choose.';
  }

  @override
  String get syncStaleKeep => 'Keep';

  @override
  String get syncStaleDiscard => 'Discard';

  @override
  String get syncStalePaused => 'Sync is paused until you answer a question';

  @override
  String get syncStaleReview => 'Review';

  @override
  String get backupFile => 'Export and import';

  @override
  String get exportFile => 'Export to a file';

  @override
  String get exportFileHint =>
      'Everything you rated, in one file. Works without Google.';

  @override
  String get exportDone => 'Saved';

  @override
  String get importFile => 'Import from a file';

  @override
  String get importTitle => 'Import ratings';

  @override
  String importBody(int device, int inFile, int merged) {
    return 'Ratings on this device: $device. In the file: $inFile. After merging: $merged.';
  }

  @override
  String get importMerge => 'Merge';

  @override
  String get importReplace => 'Replace everything';

  @override
  String get importReplaceTitle => 'Replace everything with the file?';

  @override
  String get importReplaceBody =>
      'Ratings that aren\'t in the file will be deleted on all your devices.';

  @override
  String get importBroken => 'This file can\'t be read.';

  @override
  String get importTooNew =>
      'This file was written by a newer Framebook. Update the app to import it.';

  @override
  String get importDone => 'Imported';

  @override
  String importStaleBody(int count) {
    return 'Unsynced ratings and watchlist entries on this device that conflict with a newer deletion in the file: $count. Keep restores these entries. Discard applies the deletion.';
  }

  @override
  String get reelHint =>
      'Pull the film to choose a score. Your other ratings of this kind show up here as it moves.';

  @override
  String get reelFirst =>
      'Your first rating of this kind — nothing to compare with yet.';

  @override
  String get navDiscover => 'Discover';

  @override
  String get navRatings => 'Ratings';

  @override
  String get navWatchlist => 'Watchlist';

  @override
  String get navStats => 'Stats';

  @override
  String get shelfForYou => 'Like your favourites';

  @override
  String get shelfTrending => 'Trending this week';

  @override
  String get shelfNowPlaying => 'In cinemas now';

  @override
  String get shelfBest => 'Best of all time';

  @override
  String get shelvesOffline =>
      'No connection. The shelves come from TMDB and will be here once you\'re online.';

  @override
  String get castTitle => 'Cast';

  @override
  String crewCreator(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Creators',
      one: 'Creator',
    );
    return '$_temp0';
  }

  @override
  String crewDirector(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Directors',
      one: 'Director',
    );
    return '$_temp0';
  }

  @override
  String get crewWriter => 'Written by';

  @override
  String get crewComposer => 'Music';

  @override
  String get crewCinematographer => 'Cinematography';

  @override
  String personBorn(String date) {
    return 'Born $date';
  }

  @override
  String personBornIn(String date, String place) {
    return 'Born $date in $place';
  }

  @override
  String personDied(String date) {
    return 'Died $date';
  }

  @override
  String get personMore => 'More';

  @override
  String get personFilmography => 'Filmography';

  @override
  String personActing(int count) {
    return 'Acting · $count';
  }

  @override
  String personCrew(int count) {
    return 'Behind the camera · $count';
  }

  @override
  String statsAverageOver(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'your average over $count ratings',
      one: 'your score, the only one so far',
    );
    return '$_temp0';
  }

  @override
  String aboutVersion(String name, String build) {
    return 'Version $name, build $build';
  }

  @override
  String aboutVersionName(String name) {
    return 'Version $name';
  }

  @override
  String get savedCardOffline =>
      'No connection: this is the saved card. The overview and the cast come back online.';

  @override
  String get savedCardFailed => 'TMDB didn\'t answer: this is the saved card.';

  @override
  String get secretsRestoreFromDrive => 'Restore from Google Drive';

  @override
  String get secretsTitle => 'Sync API keys and comparison source';

  @override
  String get secretsHint =>
      'Encrypted with a separate password. Changes are uploaded automatically.';

  @override
  String get secretsError =>
      'Could not unlock or sync the encrypted backup. Check the password and connection.';

  @override
  String get secretsUnlock => 'Unlock encrypted backup';

  @override
  String get secretsForgot => 'Forgot password?';

  @override
  String get secretsForgotHint =>
      'Enter your keys manually before replacing the encrypted backup.';

  @override
  String get secretsOverwriteConfirm =>
      'Replace the encrypted backup with the keys and comparison source on this device? The previous encrypted backup will be lost.';

  @override
  String get secretsOverwrite => 'Replace backup';

  @override
  String get secretsPassword => 'Backup password';

  @override
  String get secretsPasswordHint => 'At least 8 characters';

  @override
  String get secretsContinue => 'Continue';

  @override
  String get secretsMissing =>
      'No encrypted key backup found. Enable it on your other device first.';

  @override
  String get secretsWrongPassword =>
      'The password is incorrect or the encrypted file is damaged.';
}
