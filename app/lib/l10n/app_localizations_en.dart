// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get titlePremiere => 'World premiere';

  @override
  String get titleCountries => 'Production countries';

  @override
  String get titleBudget => 'Budget';

  @override
  String get titleRevenue => 'Worldwide box office';

  @override
  String get titleCollection => 'Related films';

  @override
  String get titleSimilar => 'Similar titles';

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
  String get photoOpen => 'Open full-screen photo';

  @override
  String get startupFailed =>
      'Framebook could not open its local data. Try again.';

  @override
  String get keyStatusStorageFailed =>
      'Could not change the key. Your input is still here; try again.';

  @override
  String get fileOperationFailed =>
      'Could not read or save the file. Try again.';

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
  String get settingsNavigationStyle => 'Navigation bar';

  @override
  String get navigationFloating => 'Floating';

  @override
  String get navigationClassic => 'Classic';

  @override
  String get peopleInFavorites => 'In favourites';

  @override
  String peopleFavoriteAdded(String name) {
    return '$name added to favourites';
  }

  @override
  String peopleFavoriteRemoved(String name) {
    return '$name removed from favourites';
  }

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
  String get keyStatusFailed =>
      'The service returned an invalid response; the key was not saved';

  @override
  String get keyStatusLimit =>
      'Key works, but today\'s request limit is used up';

  @override
  String get keyStatusEmpty => 'Paste a key first';

  @override
  String get retry => 'Try again';

  @override
  String get searchTitles => 'Films';

  @override
  String get searchPeople => 'People';

  @override
  String get searchPeopleHint => 'Actor, director, filmmaker';

  @override
  String get filmographyActing => 'Acting';

  @override
  String get filmographyDirecting => 'Directing';

  @override
  String get filmographyProduction => 'Production';

  @override
  String get filmographyWriting => 'Writing';

  @override
  String get filmographyMusic => 'Music';

  @override
  String get filmographyCamera => 'Camera';

  @override
  String get filmographyOther => 'Other work';

  @override
  String get searchHint => 'Film or series';

  @override
  String get searchHistory => 'Recently opened';

  @override
  String get searchHistoryClear => 'Clear history';

  @override
  String get searchHistoryRemove => 'Remove from history';

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
  String get tvStatusPlanned => 'announced';

  @override
  String get tvStatusInProduction => 'in production';

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
  String get ratingNotReleased => 'Rating is available after release.';

  @override
  String get titleNotReleased => 'Not released yet';

  @override
  String get titleReleaseDateUnknown => 'Release date unknown';

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
  String get ratingSaveFailed =>
      'Could not save your rating. Your draft is still here; try again.';

  @override
  String get libraryChangeFailed => 'Could not save changes. Try again.';

  @override
  String get localDataLoadFailed => 'Could not load your library. Try again.';

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
  String watchlistRenumber(String from, String to) {
    return 'A season on your watchlist moved from $from to $to. Move it?';
  }

  @override
  String watchlistRenumberMany(String moves) {
    return 'Seasons on your watchlist were renumbered: $moves. Move them?';
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
  String get pairTitle => 'Review your scores';

  @override
  String get pairEntryTitle => 'Review your scores';

  @override
  String get pairHow => 'How pairs are selected';

  @override
  String get pairIntro =>
      'Compare rated films to check your score scale. Close scores and similar genres come first; previous answers reveal preference chains worth checking. Scores appear after your choice.';

  @override
  String get pairStart => 'Compare films';

  @override
  String get pairNeedFilms => 'Rate at least two films to start.';

  @override
  String get pairDailyHint => 'Up to 5 comparisons per day.';

  @override
  String pairProgress(int count) {
    return '$count of 5 comparisons today';
  }

  @override
  String get pairQuestion => 'Which film did you enjoy more?';

  @override
  String get pairFirst => 'First film';

  @override
  String get pairSecond => 'Second film';

  @override
  String get pairPreferFirst => 'The first film';

  @override
  String get pairPreferSecond => 'The second film';

  @override
  String get pairEqual => 'Enjoyed both equally';

  @override
  String get pairSkip => 'Skip / I do not remember';

  @override
  String get pairReasonBoundary =>
      'Checking a score boundary using comparable films.';

  @override
  String get pairReasonChain =>
      'Previous answers form a preference chain that your scores do not reflect. Let us check it directly.';

  @override
  String get pairAgrees => 'Your scores agree with this answer.';

  @override
  String get pairDisagrees =>
      'Your answer differs from your scores. Choose a correction or keep the scores.';

  @override
  String pairCorrection(String title, String before, String after) {
    return '$title: $before → $after';
  }

  @override
  String get pairChangeAnswer => 'Change answer';

  @override
  String get pairKeep => 'Keep scores and save answer';

  @override
  String get pairNext => 'Save answer and continue';

  @override
  String get pairLimit =>
      'Five comparisons completed today. Come back tomorrow.';

  @override
  String get pairFinished =>
      'No suitable new pairs remain at these score versions. New ratings or score changes can open more comparisons.';

  @override
  String get pairChanged =>
      'These ratings changed. The next pair uses the latest scores.';

  @override
  String get pairSaveFailed =>
      'Could not save the comparison. Your choice is still here; try again.';

  @override
  String get pairLoadFailed =>
      'Could not load rated films or comparison history.';

  @override
  String get statsSeeAll => 'All';

  @override
  String get statsRated => 'Rated';

  @override
  String get statsAverage => 'Average score';

  @override
  String get statsTopRated => 'Your high scores';

  @override
  String get statsFavoriteGenres => 'Favourite genres';

  @override
  String get statsScoresLinkHint => 'How often you give each score';

  @override
  String get statsGenresAndDecades => 'Genres and decades';

  @override
  String get statsGenresLinkHint => 'Ratings by genre and decade';

  @override
  String get statsActorsDirectors => 'Actors and directors';

  @override
  String get statsPeopleLinkHint => 'Who appears in your rated titles';

  @override
  String get statsCompareLinkHint => 'Kinopoisk and IMDb';

  @override
  String get statsNoCategories =>
      'No genre or release-year information for these titles yet.';

  @override
  String get statsActors => 'Actors';

  @override
  String get statsDirectors => 'Directors';

  @override
  String get statsPeopleMinimum =>
      'At least 3 rated titles are needed to rank by average score.';

  @override
  String statsPersonSummary(int count, String average) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titles',
      one: '$count title',
    );
    return '$_temp0 · average $average';
  }

  @override
  String statsOpenPerson(String name) {
    return 'Open profile: $name';
  }

  @override
  String statsRatesHigher(String value) {
    return 'You rate $value points higher on average.';
  }

  @override
  String statsRatesLower(String value) {
    return 'You rate $value points lower on average.';
  }

  @override
  String get statsRatesSame => 'Your scores are about the same on average.';

  @override
  String get pairEntryHint =>
      'Choose which film you enjoyed more and refine your scores.';

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
  String get statsCompared => 'Compare with public ratings';

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
      'Your ratings, notes, watchlist and favourite people are kept in a hidden folder of your own Google Drive and merged between your devices. The app sees only that folder.';

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
  String get syncErrorTooLarge =>
      'This file is too large. The limit is 32 MiB compressed and 128 MiB after unpacking.';

  @override
  String get syncErrorBroken =>
      'The file in Google Drive can\'t be read. It was left as it is; you can restore a daily copy.';

  @override
  String get syncErrorTooNew =>
      'The file in Google Drive was written by a newer Framebook. Update the app to sync.';

  @override
  String get syncErrorFailed => 'Could not complete sync. Try again later.';

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
      'Keeps up to seven copies from days when synced data changed. Restoring replaces your retained ratings, watchlist and favourite people across devices.';

  @override
  String get syncBackupsEmpty =>
      'No copies yet: a copy is made before the first overwrite of an existing sync file each day.';

  @override
  String get syncRestore => 'Restore';

  @override
  String syncRestoreTitle(String date) {
    return 'Restore the copy of $date?';
  }

  @override
  String get syncRepairBody =>
      'Restore this copy and repair the unreadable sync file? The damaged original will be kept separately in Drive. Existing daily copies and encrypted keys will stay. Newer app formats are never replaced.';

  @override
  String get syncRestoreBody =>
      'Ratings, watchlist and favourite-people changes after this copy will be rolled back across your devices. Entries permanently removed by cleanup cannot be recovered from an older copy.';

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
      'Your ratings, notes, watchlist and favourite people in one file. Works without Google.';

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
      'Ratings, watchlist entries and favourite people absent from the file will be removed on all your devices.';

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
  String get shelfForYou => 'For you';

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

  @override
  String get ratingDayToday => 'Today';

  @override
  String get ratingDayYesterday => 'Yesterday';

  @override
  String get peopleFavorites => 'Favourite people';

  @override
  String get peopleFrequent => 'Often in your ratings';

  @override
  String get peoplePopular => 'Popular people';

  @override
  String get peopleAddFavorite => 'Add to favourites';

  @override
  String get peopleRemoveFavorite => 'Remove from favourites';

  @override
  String get peopleFavoriteFailed => 'Could not update favourites. Try again.';

  @override
  String get peopleFavoritesEmpty =>
      'Save people from their pages to find them here.';

  @override
  String get peopleLoadContinue => 'Continue loading';

  @override
  String get peopleLoadHint =>
      'Credits load in short batches. You can use the screen while loading. Missing credits are excluded from people statistics.';

  @override
  String get peopleNoCredits => 'People will appear as credits are loaded.';

  @override
  String get filmographyAll => 'All work';

  @override
  String get statsAllTime => 'All time';

  @override
  String get statsBest => 'Your highest scores';

  @override
  String get statsWorst => 'Your lowest scores';

  @override
  String get statsFinds => 'You rated higher';

  @override
  String get statsDisappointments => 'You rated lower';

  @override
  String get statsFindsHint => 'The lists below show gaps of at least 1 point.';

  @override
  String get statsTasteAgreement => 'Preference agreement';

  @override
  String get statsAgreementMissing =>
      'Needs at least 3 shared ratings and scores that vary.';

  @override
  String get statsCorrelationHint =>
      'Rank agreement: +1 means the same order of preferences, 0 no rank relationship, −1 the reverse. This is not a percentage of matching scores.';

  @override
  String get statsReliableGenres => 'Reliable genres';

  @override
  String get statsPeople => 'People in your library';

  @override
  String get statsPeopleFrequent => 'Most frequent';

  @override
  String get statsPeopleHighest => 'Highest rated';

  @override
  String get statsPeopleReliable => 'Most often 8+';

  @override
  String get statsPeoplePolarizing => 'Mixed feelings';

  @override
  String get statsDuos => 'Favourite creative pairs';

  @override
  String get statsBreadth => 'Breadth of taste';

  @override
  String get statsBreadthHint =>
      'Effective diversity grows when ratings are spread evenly between categories. Genres overlap; a title can belong to several.';

  @override
  String get statsMinimumWorks =>
      'Average and reliability rankings need 3 works. Mixed feelings means at least one 8+ and one 4 or below. Spread is the standard deviation.';

  @override
  String get statsNoQualifying => 'Not enough qualifying works yet.';

  @override
  String get statsShowAll => 'Show all';

  @override
  String get statsScoreHigh => 'Scores 8–10';

  @override
  String get statsScoreLow => 'Scores 1–4';

  @override
  String get statsScoreMiddle => 'Scores 4.5–7.5';

  @override
  String get statsMedian => 'Median';

  @override
  String get statsSourceWorks => 'Shared ratings';

  @override
  String peopleLoadProgress(int loaded, int total) {
    return 'People: $loaded of $total works';
  }

  @override
  String statsProfile(int count, String average, int percent, String spread) {
    return '$count works · avg $average · 8+: $percent% · spread $spread';
  }

  @override
  String statsAgreementValue(String value, int count) {
    return '$value · $count shared ratings';
  }

  @override
  String statsBreadthSummary(int genres, int decades, int people) {
    return '$genres genres · $decades decades · $people people';
  }

  @override
  String statsEffectiveDiversity(String genres, String decades) {
    return 'Effective diversity: $genres genres · $decades decades';
  }

  @override
  String get recommendationsWatchlist => 'What to choose from my watchlist';

  @override
  String get recommendationsPeople => 'Work by favourite people';

  @override
  String get recommendationsExplore => 'Something different';

  @override
  String get recommendationsNotInterested => 'Not interested';

  @override
  String get recommendationsActions => 'Recommendation actions';

  @override
  String get recommendationsHidden => 'Hidden recommendations';

  @override
  String get recommendationsRestoreHint =>
      'Show all recommendations hidden on this device again? Your ratings and watchlist will stay as they are.';

  @override
  String get recommendationsRestore => 'Show again';

  @override
  String get recommendationsSaveFailed =>
      'Could not save this preference. Try again.';

  @override
  String get recommendationsRetry => 'Retry recommendations';

  @override
  String get recommendationsEmpty =>
      'No suggestions right now. You can show hidden recommendations again.';

  @override
  String get recommendationsBecauseTaste => 'Matches your favourite genres';

  @override
  String get recommendationsBecauseExplore => 'Explore something different';

  @override
  String get recommendationsBecauseWatchlist => 'From your watchlist';

  @override
  String recommendationsBecauseTitle(String title) {
    return 'Because you liked $title';
  }

  @override
  String recommendationsBecausePerson(String name) {
    return 'A favourite: $name';
  }

  @override
  String recommendationsBecauseAuthor(String name) {
    return 'You rate their work highly: $name';
  }

  @override
  String recommendationsHiddenTitle(String title) {
    return '“$title” hidden from recommendations';
  }
}
