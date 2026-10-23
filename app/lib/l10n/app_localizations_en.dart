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
  String get tabSearchPlaceholder =>
      'Search for films and series will be here.';

  @override
  String get tabRatingsPlaceholder => 'Your ratings will be here.';

  @override
  String get tabWatchlistPlaceholder => 'Films you want to watch will be here.';

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
}
