import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Framebook'**
  String get appTitle;

  /// No description provided for @tabSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tabSearch;

  /// No description provided for @tabRatings.
  ///
  /// In en, this message translates to:
  /// **'My ratings'**
  String get tabRatings;

  /// No description provided for @tabWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get tabWatchlist;

  /// No description provided for @tabStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get tabStats;

  /// No description provided for @tabRatingsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Your ratings will be here.'**
  String get tabRatingsPlaceholder;

  /// No description provided for @tabWatchlistPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Films you want to watch will be here.'**
  String get tabWatchlistPlaceholder;

  /// No description provided for @tabStatsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Statistics will be here once you have ratings.'**
  String get tabStatsPlaceholder;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSources.
  ///
  /// In en, this message translates to:
  /// **'Sources and API keys'**
  String get settingsSources;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Framebook'**
  String get onboardingTitle;

  /// No description provided for @onboardingIntro.
  ///
  /// In en, this message translates to:
  /// **'Framebook has no server: film data comes straight from TMDB, Kinopoisk and IMDb using your own free API keys. Only the TMDB key is required to start.'**
  String get onboardingIntro;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingTmdbRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a working TMDB key to continue.'**
  String get onboardingTmdbRequired;

  /// No description provided for @sourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sources and API keys'**
  String get sourcesTitle;

  /// No description provided for @sourcesHowToGet.
  ///
  /// In en, this message translates to:
  /// **'How to get the keys'**
  String get sourcesHowToGet;

  /// No description provided for @sourceRequired.
  ///
  /// In en, this message translates to:
  /// **'required'**
  String get sourceRequired;

  /// No description provided for @sourceOptional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get sourceOptional;

  /// No description provided for @sourceTmdbName.
  ///
  /// In en, this message translates to:
  /// **'TMDB'**
  String get sourceTmdbName;

  /// No description provided for @sourceTmdbDescription.
  ///
  /// In en, this message translates to:
  /// **'Search, title details, seasons and episodes, posters, TMDB rating.'**
  String get sourceTmdbDescription;

  /// No description provided for @sourceTmdbHint.
  ///
  /// In en, this message translates to:
  /// **'API Read Access Token (starts with eyJ…) or API key'**
  String get sourceTmdbHint;

  /// No description provided for @sourcePoiskkinoName.
  ///
  /// In en, this message translates to:
  /// **'PoiskKino'**
  String get sourcePoiskkinoName;

  /// No description provided for @sourcePoiskkinoDescription.
  ///
  /// In en, this message translates to:
  /// **'Kinopoisk rating. Free plan: 200 requests a day.'**
  String get sourcePoiskkinoDescription;

  /// No description provided for @sourcePoiskkinoHint.
  ///
  /// In en, this message translates to:
  /// **'Key from the @poiskkinodev_bot Telegram bot'**
  String get sourcePoiskkinoHint;

  /// No description provided for @sourceOmdbName.
  ///
  /// In en, this message translates to:
  /// **'OMDb'**
  String get sourceOmdbName;

  /// No description provided for @sourceOmdbDescription.
  ///
  /// In en, this message translates to:
  /// **'IMDb, Rotten Tomatoes and Metacritic ratings. Free plan: 1,000 requests a day.'**
  String get sourceOmdbDescription;

  /// No description provided for @sourceOmdbHint.
  ///
  /// In en, this message translates to:
  /// **'Key from the OMDb email (activate it first)'**
  String get sourceOmdbHint;

  /// No description provided for @keySave.
  ///
  /// In en, this message translates to:
  /// **'Check and save'**
  String get keySave;

  /// No description provided for @keyRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get keyRemove;

  /// No description provided for @keyShow.
  ///
  /// In en, this message translates to:
  /// **'Show key'**
  String get keyShow;

  /// No description provided for @keyHide.
  ///
  /// In en, this message translates to:
  /// **'Hide key'**
  String get keyHide;

  /// No description provided for @keyStatusMissing.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get keyStatusMissing;

  /// No description provided for @keyStatusChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get keyStatusChecking;

  /// No description provided for @keyStatusValid.
  ///
  /// In en, this message translates to:
  /// **'Key works'**
  String get keyStatusValid;

  /// No description provided for @keyStatusUnverified.
  ///
  /// In en, this message translates to:
  /// **'Saved, not checked: no connection'**
  String get keyStatusUnverified;

  /// No description provided for @keyStatusInvalid.
  ///
  /// In en, this message translates to:
  /// **'The service rejected this key'**
  String get keyStatusInvalid;

  /// No description provided for @keyStatusLimit.
  ///
  /// In en, this message translates to:
  /// **'Key works, but today\'s request limit is used up'**
  String get keyStatusLimit;

  /// No description provided for @keyStatusEmpty.
  ///
  /// In en, this message translates to:
  /// **'Paste a key first'**
  String get keyStatusEmpty;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Film or series'**
  String get searchHint;

  /// No description provided for @searchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchClear;

  /// No description provided for @searchEmpty.
  ///
  /// In en, this message translates to:
  /// **'Find a film or series by title.'**
  String get searchEmpty;

  /// No description provided for @searchNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing found for “{query}”.'**
  String searchNothing(String query);

  /// No description provided for @kindMovie.
  ///
  /// In en, this message translates to:
  /// **'Film'**
  String get kindMovie;

  /// No description provided for @kindTv.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get kindTv;

  /// No description provided for @failureOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection. Search and title pages need the internet; what was opened before is shown from the cache.'**
  String get failureOffline;

  /// No description provided for @failureTmdbKey.
  ///
  /// In en, this message translates to:
  /// **'TMDB rejected the key. Check it in settings.'**
  String get failureTmdbKey;

  /// No description provided for @failureNotFound.
  ///
  /// In en, this message translates to:
  /// **'TMDB has no such title.'**
  String get failureNotFound;

  /// No description provided for @failureTmdb.
  ///
  /// In en, this message translates to:
  /// **'TMDB didn\'t answer properly. Try again a bit later.'**
  String get failureTmdb;

  /// No description provided for @titleOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get titleOverview;

  /// No description provided for @titleSeasons.
  ///
  /// In en, this message translates to:
  /// **'Seasons'**
  String get titleSeasons;

  /// No description provided for @titleEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get titleEpisodes;

  /// No description provided for @tvStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'ongoing'**
  String get tvStatusRunning;

  /// No description provided for @tvStatusEnded.
  ///
  /// In en, this message translates to:
  /// **'ended'**
  String get tvStatusEnded;

  /// No description provided for @tvStatusCanceled.
  ///
  /// In en, this message translates to:
  /// **'canceled'**
  String get tvStatusCanceled;

  /// No description provided for @seasonCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} season} other{{count} seasons}}'**
  String seasonCount(int count);

  /// No description provided for @episodeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} episode} other{{count} episodes}}'**
  String episodeCount(int count);

  /// No description provided for @seasonNumber.
  ///
  /// In en, this message translates to:
  /// **'Season {number}'**
  String seasonNumber(int number);

  /// No description provided for @seasonSpecials.
  ///
  /// In en, this message translates to:
  /// **'Specials'**
  String get seasonSpecials;

  /// No description provided for @episodeNumber.
  ///
  /// In en, this message translates to:
  /// **'Episode {number}'**
  String episodeNumber(int number);

  /// No description provided for @episodeCode.
  ///
  /// In en, this message translates to:
  /// **'S{season} · E{episode}'**
  String episodeCode(int season, int episode);

  /// No description provided for @runtimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String runtimeMinutes(int minutes);

  /// No description provided for @runtimeHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String runtimeHours(int hours);

  /// No description provided for @runtimeHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String runtimeHoursMinutes(int hours, int minutes);

  /// No description provided for @ratingKinopoisk.
  ///
  /// In en, this message translates to:
  /// **'Kinopoisk'**
  String get ratingKinopoisk;

  /// No description provided for @ratingVotes.
  ///
  /// In en, this message translates to:
  /// **'{count} votes'**
  String ratingVotes(String count);

  /// No description provided for @ratingAsOf.
  ///
  /// In en, this message translates to:
  /// **'as of {date}'**
  String ratingAsOf(String date);

  /// No description provided for @ratingSeasonAverage.
  ///
  /// In en, this message translates to:
  /// **'episode average'**
  String get ratingSeasonAverage;

  /// No description provided for @ratingNoData.
  ///
  /// In en, this message translates to:
  /// **'no data'**
  String get ratingNoData;

  /// No description provided for @ratingNeedsKey.
  ///
  /// In en, this message translates to:
  /// **'add a key'**
  String get ratingNeedsKey;

  /// No description provided for @ratingOffline.
  ///
  /// In en, this message translates to:
  /// **'no connection'**
  String get ratingOffline;

  /// No description provided for @ratingLimit.
  ///
  /// In en, this message translates to:
  /// **'daily limit used up'**
  String get ratingLimit;

  /// No description provided for @ratingKeyRejected.
  ///
  /// In en, this message translates to:
  /// **'key rejected'**
  String get ratingKeyRejected;

  /// No description provided for @ratingFailed.
  ///
  /// In en, this message translates to:
  /// **'source error'**
  String get ratingFailed;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutIntro.
  ///
  /// In en, this message translates to:
  /// **'Framebook is a personal diary of film and series ratings that compares your scores with Kinopoisk, IMDb and others. It has no server: everything you rate stays on your phone.'**
  String get aboutIntro;

  /// No description provided for @aboutData.
  ///
  /// In en, this message translates to:
  /// **'Where the data comes from'**
  String get aboutData;

  /// No description provided for @aboutTmdb.
  ///
  /// In en, this message translates to:
  /// **'Catalog, posters, seasons and episodes, TMDB rating.'**
  String get aboutTmdb;

  /// No description provided for @aboutPoiskkinoTitle.
  ///
  /// In en, this message translates to:
  /// **'PoiskKino API'**
  String get aboutPoiskkinoTitle;

  /// No description provided for @aboutPoiskkino.
  ///
  /// In en, this message translates to:
  /// **'Kinopoisk rating. An unofficial service, not affiliated with Kinopoisk.'**
  String get aboutPoiskkino;

  /// No description provided for @aboutOmdb.
  ///
  /// In en, this message translates to:
  /// **'IMDb, Rotten Tomatoes and Metacritic ratings.'**
  String get aboutOmdb;

  /// No description provided for @aboutSource.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get aboutSource;

  /// No description provided for @aboutLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get aboutLicenses;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
