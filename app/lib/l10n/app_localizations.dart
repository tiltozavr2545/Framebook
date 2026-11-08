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

  /// No description provided for @titlePremiere.
  ///
  /// In en, this message translates to:
  /// **'World premiere'**
  String get titlePremiere;

  /// No description provided for @titleCountries.
  ///
  /// In en, this message translates to:
  /// **'Production countries'**
  String get titleCountries;

  /// No description provided for @titleBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get titleBudget;

  /// No description provided for @titleRevenue.
  ///
  /// In en, this message translates to:
  /// **'Worldwide box office'**
  String get titleRevenue;

  /// No description provided for @titleCollection.
  ///
  /// In en, this message translates to:
  /// **'Related films'**
  String get titleCollection;

  /// No description provided for @titleSimilar.
  ///
  /// In en, this message translates to:
  /// **'Similar titles'**
  String get titleSimilar;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update {version} is available'**
  String updateAvailable(String version);

  /// No description provided for @updateOpen.
  ///
  /// In en, this message translates to:
  /// **'Open release'**
  String get updateOpen;

  /// No description provided for @updateDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get updateDismiss;

  /// No description provided for @updateCheck.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get updateCheck;

  /// No description provided for @updateFound.
  ///
  /// In en, this message translates to:
  /// **'An update is available'**
  String get updateFound;

  /// No description provided for @updateCurrent.
  ///
  /// In en, this message translates to:
  /// **'You have the latest version'**
  String get updateCurrent;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check for updates'**
  String get updateFailed;

  /// No description provided for @coverOpen.
  ///
  /// In en, this message translates to:
  /// **'Open full-screen cover'**
  String get coverOpen;

  /// No description provided for @photoOpen.
  ///
  /// In en, this message translates to:
  /// **'Open full-screen photo'**
  String get photoOpen;

  /// No description provided for @startupFailed.
  ///
  /// In en, this message translates to:
  /// **'Framebook could not open its local data. Try again.'**
  String get startupFailed;

  /// No description provided for @keyStatusStorageFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change the key. Your input is still here; try again.'**
  String get keyStatusStorageFailed;

  /// No description provided for @fileOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read or save the file. Try again.'**
  String get fileOperationFailed;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Framebook'**
  String get appTitle;

  /// No description provided for @tabSearch.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
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

  /// No description provided for @settingsNavigationStyle.
  ///
  /// In en, this message translates to:
  /// **'Navigation bar'**
  String get settingsNavigationStyle;

  /// No description provided for @navigationFloating.
  ///
  /// In en, this message translates to:
  /// **'Floating'**
  String get navigationFloating;

  /// No description provided for @navigationClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get navigationClassic;

  /// No description provided for @peopleInFavorites.
  ///
  /// In en, this message translates to:
  /// **'In favourites'**
  String get peopleInFavorites;

  /// No description provided for @peopleFavoriteAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added to favourites'**
  String peopleFavoriteAdded(String name);

  /// No description provided for @peopleFavoriteRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed from favourites'**
  String peopleFavoriteRemoved(String name);

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

  /// No description provided for @sourceTmdbComputer.
  ///
  /// In en, this message translates to:
  /// **'Register your TMDB account and API key on a computer, not a phone.'**
  String get sourceTmdbComputer;

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

  /// No description provided for @keyStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'The service returned an invalid response; the key was not saved'**
  String get keyStatusFailed;

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

  /// No description provided for @searchTitles.
  ///
  /// In en, this message translates to:
  /// **'Films'**
  String get searchTitles;

  /// No description provided for @searchPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get searchPeople;

  /// No description provided for @searchPeopleHint.
  ///
  /// In en, this message translates to:
  /// **'Actor, director, filmmaker'**
  String get searchPeopleHint;

  /// No description provided for @filmographyActing.
  ///
  /// In en, this message translates to:
  /// **'Acting'**
  String get filmographyActing;

  /// No description provided for @filmographyDirecting.
  ///
  /// In en, this message translates to:
  /// **'Directing'**
  String get filmographyDirecting;

  /// No description provided for @filmographyProduction.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get filmographyProduction;

  /// No description provided for @filmographyWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get filmographyWriting;

  /// No description provided for @filmographyMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get filmographyMusic;

  /// No description provided for @filmographyCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get filmographyCamera;

  /// No description provided for @filmographyOther.
  ///
  /// In en, this message translates to:
  /// **'Other work'**
  String get filmographyOther;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Film or series'**
  String get searchHint;

  /// No description provided for @searchHistory.
  ///
  /// In en, this message translates to:
  /// **'Recently opened'**
  String get searchHistory;

  /// No description provided for @searchHistoryClear.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get searchHistoryClear;

  /// No description provided for @searchHistoryRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from history'**
  String get searchHistoryRemove;

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

  /// No description provided for @tvStatusPlanned.
  ///
  /// In en, this message translates to:
  /// **'announced'**
  String get tvStatusPlanned;

  /// No description provided for @tvStatusInProduction.
  ///
  /// In en, this message translates to:
  /// **'in production'**
  String get tvStatusInProduction;

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

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @ratingRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get ratingRate;

  /// No description provided for @ratingNotReleased.
  ///
  /// In en, this message translates to:
  /// **'Rating is available after release.'**
  String get ratingNotReleased;

  /// No description provided for @titleNotReleased.
  ///
  /// In en, this message translates to:
  /// **'Not released yet'**
  String get titleNotReleased;

  /// No description provided for @titleReleaseDateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Release date unknown'**
  String get titleReleaseDateUnknown;

  /// No description provided for @ratingMine.
  ///
  /// In en, this message translates to:
  /// **'My rating'**
  String get ratingMine;

  /// No description provided for @ratingEdit.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get ratingEdit;

  /// No description provided for @ratingDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get ratingDelete;

  /// No description provided for @ratingDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your rating?'**
  String get ratingDeleteTitle;

  /// No description provided for @ratingDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The score and the note will be deleted on all your devices.'**
  String get ratingDeleteBody;

  /// No description provided for @ratingEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Your rating'**
  String get ratingEditorTitle;

  /// No description provided for @ratingNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get ratingNote;

  /// No description provided for @ratingSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your rating. Your draft is still here; try again.'**
  String get ratingSaveFailed;

  /// No description provided for @libraryChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save changes. Try again.'**
  String get libraryChangeFailed;

  /// No description provided for @localDataLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your library. Try again.'**
  String get localDataLoadFailed;

  /// No description provided for @ratingSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get ratingSave;

  /// No description provided for @partsAverageSeasons.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Your score for {count} season: {average}} other{Your average over {count} seasons: {average}}}'**
  String partsAverageSeasons(int count, String average);

  /// No description provided for @partsAverageEpisodes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Your score for {count} episode: {average}} other{Your average over {count} episodes: {average}}}'**
  String partsAverageEpisodes(int count, String average);

  /// No description provided for @renumberEpisode.
  ///
  /// In en, this message translates to:
  /// **'Your rating of {from} was for an episode that is now {to}. Move it?'**
  String renumberEpisode(String from, String to);

  /// No description provided for @renumberSeason.
  ///
  /// In en, this message translates to:
  /// **'Your rating of {from} was for a season that is now {to}. Move it?'**
  String renumberSeason(String from, String to);

  /// No description provided for @renumberManyEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Your ratings were for episodes that are now numbered differently: {moves}. Move them?'**
  String renumberManyEpisodes(String moves);

  /// No description provided for @renumberManySeasons.
  ///
  /// In en, this message translates to:
  /// **'Your ratings were for seasons that are now numbered differently: {moves}. Move them?'**
  String renumberManySeasons(String moves);

  /// No description provided for @renumberConflictEpisode.
  ///
  /// In en, this message translates to:
  /// **'Your {fromScore} for {from} was for the episode that is now {to}, which you rated {toScore}. Which score to keep?'**
  String renumberConflictEpisode(
    String fromScore,
    String from,
    String to,
    String toScore,
  );

  /// No description provided for @renumberConflictSeason.
  ///
  /// In en, this message translates to:
  /// **'Your {fromScore} for {from} was for the season that is now {to}, which you rated {toScore}. Which score to keep?'**
  String renumberConflictSeason(
    String fromScore,
    String from,
    String to,
    String toScore,
  );

  /// No description provided for @watchlistRenumber.
  ///
  /// In en, this message translates to:
  /// **'A season on your watchlist moved from {from} to {to}. Move it?'**
  String watchlistRenumber(String from, String to);

  /// No description provided for @watchlistRenumberMany.
  ///
  /// In en, this message translates to:
  /// **'Seasons on your watchlist were renumbered: {moves}. Move them?'**
  String watchlistRenumberMany(String moves);

  /// No description provided for @renumberMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get renumberMove;

  /// No description provided for @renumberKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get renumberKeep;

  /// No description provided for @renumberKeepScore.
  ///
  /// In en, this message translates to:
  /// **'Keep {score}'**
  String renumberKeepScore(String score);

  /// No description provided for @calibrationSame.
  ///
  /// In en, this message translates to:
  /// **'Also {score}'**
  String calibrationSame(String score);

  /// No description provided for @calibrationAbove.
  ///
  /// In en, this message translates to:
  /// **'A step above · {score}'**
  String calibrationAbove(String score);

  /// No description provided for @calibrationBelow.
  ///
  /// In en, this message translates to:
  /// **'A step below · {score}'**
  String calibrationBelow(String score);

  /// No description provided for @calibrationNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing else of this kind is rated near this score.'**
  String get calibrationNothing;

  /// No description provided for @watchlistAdd.
  ///
  /// In en, this message translates to:
  /// **'Want to watch'**
  String get watchlistAdd;

  /// No description provided for @watchlistListed.
  ///
  /// In en, this message translates to:
  /// **'On the watchlist'**
  String get watchlistListed;

  /// No description provided for @watchlistRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from the watchlist'**
  String get watchlistRemove;

  /// No description provided for @watchlistRemoved.
  ///
  /// In en, this message translates to:
  /// **'“{title}” removed from the watchlist'**
  String watchlistRemoved(String title);

  /// No description provided for @watchlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet. Open a film or a series and tap “Want to watch”.'**
  String get watchlistEmpty;

  /// No description provided for @ratingsSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get ratingsSort;

  /// No description provided for @ratingsSortDate.
  ///
  /// In en, this message translates to:
  /// **'By date rated'**
  String get ratingsSortDate;

  /// No description provided for @ratingsSortScore.
  ///
  /// In en, this message translates to:
  /// **'By my score'**
  String get ratingsSortScore;

  /// No description provided for @ratingsSortYear.
  ///
  /// In en, this message translates to:
  /// **'By year'**
  String get ratingsSortYear;

  /// No description provided for @ratingsSortTitle.
  ///
  /// In en, this message translates to:
  /// **'By title'**
  String get ratingsSortTitle;

  /// No description provided for @ratingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t rated anything yet. Find a film in Search and give it a score.'**
  String get ratingsEmpty;

  /// No description provided for @ratingsEmptyKind.
  ///
  /// In en, this message translates to:
  /// **'Nothing of this kind is rated yet.'**
  String get ratingsEmptyKind;

  /// No description provided for @kindAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get kindAll;

  /// No description provided for @kindMovies.
  ///
  /// In en, this message translates to:
  /// **'Films'**
  String get kindMovies;

  /// No description provided for @kindSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get kindSeries;

  /// No description provided for @kindSeasons.
  ///
  /// In en, this message translates to:
  /// **'Seasons'**
  String get kindSeasons;

  /// No description provided for @kindEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get kindEpisodes;

  /// No description provided for @ratingsSortDivergence.
  ///
  /// In en, this message translates to:
  /// **'By divergence'**
  String get ratingsSortDivergence;

  /// No description provided for @ratingDivergence.
  ///
  /// In en, this message translates to:
  /// **'mine minus theirs: {value}'**
  String ratingDivergence(String value);

  /// No description provided for @divergenceFurthest.
  ///
  /// In en, this message translates to:
  /// **'Furthest apart'**
  String get divergenceFurthest;

  /// No description provided for @divergenceHigher.
  ///
  /// In en, this message translates to:
  /// **'I rate higher'**
  String get divergenceHigher;

  /// No description provided for @divergenceLower.
  ///
  /// In en, this message translates to:
  /// **'I rate lower'**
  String get divergenceLower;

  /// No description provided for @coverageLoaded.
  ///
  /// In en, this message translates to:
  /// **'{source} ratings loaded for {loaded} of {total}'**
  String coverageLoaded(String source, int loaded, int total);

  /// No description provided for @coverageNeedsKey.
  ///
  /// In en, this message translates to:
  /// **'Add a key in Sources to compare with {source}'**
  String coverageNeedsKey(String source);

  /// No description provided for @pairTitle.
  ///
  /// In en, this message translates to:
  /// **'Pairwise calibration'**
  String get pairTitle;

  /// No description provided for @pairHow.
  ///
  /// In en, this message translates to:
  /// **'How pairs are selected'**
  String get pairHow;

  /// No description provided for @pairIntro.
  ///
  /// In en, this message translates to:
  /// **'Compare rated films to check your score scale. Close scores and similar genres come first; previous answers reveal preference chains worth checking. Scores appear after your choice.'**
  String get pairIntro;

  /// No description provided for @pairStart.
  ///
  /// In en, this message translates to:
  /// **'Compare films'**
  String get pairStart;

  /// No description provided for @pairNeedFilms.
  ///
  /// In en, this message translates to:
  /// **'Rate at least two films to start.'**
  String get pairNeedFilms;

  /// No description provided for @pairDailyHint.
  ///
  /// In en, this message translates to:
  /// **'Up to 5 completed comparisons per day. Answers sync through Drive.'**
  String get pairDailyHint;

  /// No description provided for @pairProgress.
  ///
  /// In en, this message translates to:
  /// **'{count} of 5 comparisons today'**
  String pairProgress(int count);

  /// No description provided for @pairQuestion.
  ///
  /// In en, this message translates to:
  /// **'Which film did you enjoy more?'**
  String get pairQuestion;

  /// No description provided for @pairFirst.
  ///
  /// In en, this message translates to:
  /// **'First film'**
  String get pairFirst;

  /// No description provided for @pairSecond.
  ///
  /// In en, this message translates to:
  /// **'Second film'**
  String get pairSecond;

  /// No description provided for @pairPreferFirst.
  ///
  /// In en, this message translates to:
  /// **'The first film'**
  String get pairPreferFirst;

  /// No description provided for @pairPreferSecond.
  ///
  /// In en, this message translates to:
  /// **'The second film'**
  String get pairPreferSecond;

  /// No description provided for @pairEqual.
  ///
  /// In en, this message translates to:
  /// **'Enjoyed both equally'**
  String get pairEqual;

  /// No description provided for @pairSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip / I do not remember'**
  String get pairSkip;

  /// No description provided for @pairReasonBoundary.
  ///
  /// In en, this message translates to:
  /// **'Checking a score boundary using comparable films.'**
  String get pairReasonBoundary;

  /// No description provided for @pairReasonChain.
  ///
  /// In en, this message translates to:
  /// **'Previous answers form a preference chain that your scores do not reflect. Let us check it directly.'**
  String get pairReasonChain;

  /// No description provided for @pairAgrees.
  ///
  /// In en, this message translates to:
  /// **'Your scores agree with this answer.'**
  String get pairAgrees;

  /// No description provided for @pairDisagrees.
  ///
  /// In en, this message translates to:
  /// **'Your answer differs from your scores. Choose a correction or keep the scores.'**
  String get pairDisagrees;

  /// No description provided for @pairCorrection.
  ///
  /// In en, this message translates to:
  /// **'{title}: {before} → {after}'**
  String pairCorrection(String title, String before, String after);

  /// No description provided for @pairChangeAnswer.
  ///
  /// In en, this message translates to:
  /// **'Change answer'**
  String get pairChangeAnswer;

  /// No description provided for @pairKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep scores and save answer'**
  String get pairKeep;

  /// No description provided for @pairNext.
  ///
  /// In en, this message translates to:
  /// **'Save answer and continue'**
  String get pairNext;

  /// No description provided for @pairLimit.
  ///
  /// In en, this message translates to:
  /// **'Five comparisons completed today. Come back tomorrow.'**
  String get pairLimit;

  /// No description provided for @pairFinished.
  ///
  /// In en, this message translates to:
  /// **'No suitable new pairs remain at these score versions. New ratings or score changes can open more comparisons.'**
  String get pairFinished;

  /// No description provided for @pairChanged.
  ///
  /// In en, this message translates to:
  /// **'These ratings changed. The next pair uses the latest scores.'**
  String get pairChanged;

  /// No description provided for @pairSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the comparison. Your choice is still here; try again.'**
  String get pairSaveFailed;

  /// No description provided for @pairLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load rated films or comparison history.'**
  String get pairLoadFailed;

  /// No description provided for @statsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Statistics will be here once you have ratings.'**
  String get statsEmpty;

  /// No description provided for @statsRatingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} rating} other{{count} ratings}}'**
  String statsRatingCount(int count);

  /// No description provided for @statsDistribution.
  ///
  /// In en, this message translates to:
  /// **'Your scores'**
  String get statsDistribution;

  /// No description provided for @statsCompared.
  ///
  /// In en, this message translates to:
  /// **'Compared with others'**
  String get statsCompared;

  /// No description provided for @statsComparedHint.
  ///
  /// In en, this message translates to:
  /// **'Your score minus theirs: “+” means you rate higher.'**
  String get statsComparedHint;

  /// No description provided for @statsDeviationOnAverage.
  ///
  /// In en, this message translates to:
  /// **'on average'**
  String get statsDeviationOnAverage;

  /// No description provided for @statsDeviationAbsolute.
  ///
  /// In en, this message translates to:
  /// **'{value} apart either way'**
  String statsDeviationAbsolute(String value);

  /// No description provided for @statsDeviationCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{over {count} rating} other{over {count} ratings}}'**
  String statsDeviationCount(int count);

  /// No description provided for @statsDeviationNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing to compare with yet: no {source} ratings.'**
  String statsDeviationNone(String source);

  /// No description provided for @statsGenres.
  ///
  /// In en, this message translates to:
  /// **'By genre'**
  String get statsGenres;

  /// No description provided for @statsGenresOffline.
  ///
  /// In en, this message translates to:
  /// **'Genre names come from TMDB, and there is no connection right now.'**
  String get statsGenresOffline;

  /// No description provided for @statsDecades.
  ///
  /// In en, this message translates to:
  /// **'By decade'**
  String get statsDecades;

  /// No description provided for @statsDecade.
  ///
  /// In en, this message translates to:
  /// **'{decade}s'**
  String statsDecade(String decade);

  /// No description provided for @settingsSync.
  ///
  /// In en, this message translates to:
  /// **'Sync and backup'**
  String get settingsSync;

  /// No description provided for @syncDrive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get syncDrive;

  /// No description provided for @syncIntro.
  ///
  /// In en, this message translates to:
  /// **'Your ratings, notes, watchlist and favourite people are kept in a hidden folder of your own Google Drive and merged between your devices. The app sees only that folder.'**
  String get syncIntro;

  /// No description provided for @syncNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in isn\'t set up in this build of the app.'**
  String get syncNotConfigured;

  /// No description provided for @syncSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get syncSignIn;

  /// No description provided for @syncSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String syncSignedInAs(String email);

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncInProgress.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncInProgress;

  /// No description provided for @syncLast.
  ///
  /// In en, this message translates to:
  /// **'Last synced {when}'**
  String syncLast(String when);

  /// No description provided for @syncNever.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get syncNever;

  /// No description provided for @syncErrorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Access to Google Drive has expired. Sign in again.'**
  String get syncErrorUnauthorized;

  /// No description provided for @syncErrorQuota.
  ///
  /// In en, this message translates to:
  /// **'Your Google Drive is full, so sync is paused. Everything still works on this device.'**
  String get syncErrorQuota;

  /// No description provided for @syncErrorTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This file is too large. The limit is 32 MiB compressed and 128 MiB after unpacking.'**
  String get syncErrorTooLarge;

  /// No description provided for @syncErrorBroken.
  ///
  /// In en, this message translates to:
  /// **'The file in Google Drive can\'t be read. It was left as it is; you can restore a daily copy.'**
  String get syncErrorBroken;

  /// No description provided for @syncErrorTooNew.
  ///
  /// In en, this message translates to:
  /// **'The file in Google Drive was written by a newer Framebook. Update the app to sync.'**
  String get syncErrorTooNew;

  /// No description provided for @syncErrorFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete sync. Try again later.'**
  String get syncErrorFailed;

  /// No description provided for @syncSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get syncSignInAgain;

  /// No description provided for @syncSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get syncSignOut;

  /// No description provided for @syncSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in to Google. Try again.'**
  String get syncSignInFailed;

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection. Try again when you\'re online.'**
  String get syncOffline;

  /// No description provided for @syncFirstTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge with Google Drive?'**
  String get syncFirstTitle;

  /// No description provided for @syncFirstBody.
  ///
  /// In en, this message translates to:
  /// **'Ratings on this device: {device}. In Google Drive: {drive}. After merging: {merged}. Nothing is lost: for every title the latest change wins.'**
  String syncFirstBody(int device, int drive, int merged);

  /// No description provided for @syncMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get syncMerge;

  /// No description provided for @syncBackups.
  ///
  /// In en, this message translates to:
  /// **'Daily copies'**
  String get syncBackups;

  /// No description provided for @syncBackupsHint.
  ///
  /// In en, this message translates to:
  /// **'Keeps up to seven copies from days when synced data changed. Restoring replaces your retained ratings, watchlist and favourite people across devices.'**
  String get syncBackupsHint;

  /// No description provided for @syncBackupsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No copies yet: a copy is made before the first overwrite of an existing sync file each day.'**
  String get syncBackupsEmpty;

  /// No description provided for @syncRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get syncRestore;

  /// No description provided for @syncRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore the copy of {date}?'**
  String syncRestoreTitle(String date);

  /// No description provided for @syncRepairBody.
  ///
  /// In en, this message translates to:
  /// **'Restore this copy and repair the unreadable sync file? The damaged original will be kept separately in Drive. Existing daily copies and encrypted keys will stay. Newer app formats are never replaced.'**
  String get syncRepairBody;

  /// No description provided for @syncRestoreBody.
  ///
  /// In en, this message translates to:
  /// **'Ratings, watchlist and favourite-people changes after this copy will be rolled back across your devices. Entries permanently removed by cleanup cannot be recovered from an older copy.'**
  String get syncRestoreBody;

  /// No description provided for @syncRestored.
  ///
  /// In en, this message translates to:
  /// **'Copy restored'**
  String get syncRestored;

  /// No description provided for @syncDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete data from Google Drive'**
  String get syncDelete;

  /// No description provided for @syncDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete the data from Google Drive?'**
  String get syncDeleteTitle;

  /// No description provided for @syncDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The file and the daily copies will be deleted, and this device will sign out. Your ratings stay on your devices. Another device that is still signed in will put its data back on its next sync.'**
  String get syncDeleteBody;

  /// No description provided for @syncDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted from Google Drive'**
  String get syncDeleted;

  /// No description provided for @syncStaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsynced changes to deleted entries'**
  String get syncStaleTitle;

  /// No description provided for @syncStaleBody.
  ///
  /// In en, this message translates to:
  /// **'Unsynced ratings and watchlist entries on this device that conflict with a newer deletion in Google Drive: {count}. Keep restores these entries on your devices. Discard applies the deletion. Sync is paused until you choose.'**
  String syncStaleBody(int count);

  /// No description provided for @syncStaleKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get syncStaleKeep;

  /// No description provided for @syncStaleDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get syncStaleDiscard;

  /// No description provided for @syncStalePaused.
  ///
  /// In en, this message translates to:
  /// **'Sync is paused until you answer a question'**
  String get syncStalePaused;

  /// No description provided for @syncStaleReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get syncStaleReview;

  /// No description provided for @backupFile.
  ///
  /// In en, this message translates to:
  /// **'Export and import'**
  String get backupFile;

  /// No description provided for @exportFile.
  ///
  /// In en, this message translates to:
  /// **'Export to a file'**
  String get exportFile;

  /// No description provided for @exportFileHint.
  ///
  /// In en, this message translates to:
  /// **'Your ratings, notes, watchlist and favourite people in one file. Works without Google.'**
  String get exportFileHint;

  /// No description provided for @exportDone.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get exportDone;

  /// No description provided for @importFile.
  ///
  /// In en, this message translates to:
  /// **'Import from a file'**
  String get importFile;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import ratings'**
  String get importTitle;

  /// No description provided for @importBody.
  ///
  /// In en, this message translates to:
  /// **'Ratings on this device: {device}. In the file: {inFile}. After merging: {merged}.'**
  String importBody(int device, int inFile, int merged);

  /// No description provided for @importMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get importMerge;

  /// No description provided for @importReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace everything'**
  String get importReplace;

  /// No description provided for @importReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace everything with the file?'**
  String get importReplaceTitle;

  /// No description provided for @importReplaceBody.
  ///
  /// In en, this message translates to:
  /// **'Ratings, watchlist entries and favourite people absent from the file will be removed on all your devices.'**
  String get importReplaceBody;

  /// No description provided for @importBroken.
  ///
  /// In en, this message translates to:
  /// **'This file can\'t be read.'**
  String get importBroken;

  /// No description provided for @importTooNew.
  ///
  /// In en, this message translates to:
  /// **'This file was written by a newer Framebook. Update the app to import it.'**
  String get importTooNew;

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get importDone;

  /// No description provided for @importStaleBody.
  ///
  /// In en, this message translates to:
  /// **'Unsynced ratings and watchlist entries on this device that conflict with a newer deletion in the file: {count}. Keep restores these entries. Discard applies the deletion.'**
  String importStaleBody(int count);

  /// No description provided for @reelHint.
  ///
  /// In en, this message translates to:
  /// **'Pull the film to choose a score. Your other ratings of this kind show up here as it moves.'**
  String get reelHint;

  /// No description provided for @reelFirst.
  ///
  /// In en, this message translates to:
  /// **'Your first rating of this kind — nothing to compare with yet.'**
  String get reelFirst;

  /// No description provided for @navDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// No description provided for @navRatings.
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get navRatings;

  /// No description provided for @navWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get navWatchlist;

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// No description provided for @shelfForYou.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get shelfForYou;

  /// No description provided for @shelfTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending this week'**
  String get shelfTrending;

  /// No description provided for @shelfNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'In cinemas now'**
  String get shelfNowPlaying;

  /// No description provided for @shelfBest.
  ///
  /// In en, this message translates to:
  /// **'Best of all time'**
  String get shelfBest;

  /// No description provided for @shelvesOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection. The shelves come from TMDB and will be here once you\'re online.'**
  String get shelvesOffline;

  /// No description provided for @castTitle.
  ///
  /// In en, this message translates to:
  /// **'Cast'**
  String get castTitle;

  /// No description provided for @crewCreator.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Creator} other{Creators}}'**
  String crewCreator(int count);

  /// No description provided for @crewDirector.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Director} other{Directors}}'**
  String crewDirector(int count);

  /// No description provided for @crewWriter.
  ///
  /// In en, this message translates to:
  /// **'Written by'**
  String get crewWriter;

  /// No description provided for @crewComposer.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get crewComposer;

  /// No description provided for @crewCinematographer.
  ///
  /// In en, this message translates to:
  /// **'Cinematography'**
  String get crewCinematographer;

  /// No description provided for @personBorn.
  ///
  /// In en, this message translates to:
  /// **'Born {date}'**
  String personBorn(String date);

  /// No description provided for @personBornIn.
  ///
  /// In en, this message translates to:
  /// **'Born {date} in {place}'**
  String personBornIn(String date, String place);

  /// No description provided for @personDied.
  ///
  /// In en, this message translates to:
  /// **'Died {date}'**
  String personDied(String date);

  /// No description provided for @personMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get personMore;

  /// No description provided for @personFilmography.
  ///
  /// In en, this message translates to:
  /// **'Filmography'**
  String get personFilmography;

  /// No description provided for @personActing.
  ///
  /// In en, this message translates to:
  /// **'Acting · {count}'**
  String personActing(int count);

  /// No description provided for @personCrew.
  ///
  /// In en, this message translates to:
  /// **'Behind the camera · {count}'**
  String personCrew(int count);

  /// No description provided for @statsAverageOver.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{your score, the only one so far} other{your average over {count} ratings}}'**
  String statsAverageOver(int count);

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {name}, build {build}'**
  String aboutVersion(String name, String build);

  /// No description provided for @aboutVersionName.
  ///
  /// In en, this message translates to:
  /// **'Version {name}'**
  String aboutVersionName(String name);

  /// No description provided for @savedCardOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection: this is the saved card. The overview and the cast come back online.'**
  String get savedCardOffline;

  /// No description provided for @savedCardFailed.
  ///
  /// In en, this message translates to:
  /// **'TMDB didn\'t answer: this is the saved card.'**
  String get savedCardFailed;

  /// No description provided for @secretsRestoreFromDrive.
  ///
  /// In en, this message translates to:
  /// **'Restore from Google Drive'**
  String get secretsRestoreFromDrive;

  /// No description provided for @secretsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync API keys and comparison source'**
  String get secretsTitle;

  /// No description provided for @secretsHint.
  ///
  /// In en, this message translates to:
  /// **'Encrypted with a separate password. Changes are uploaded automatically.'**
  String get secretsHint;

  /// No description provided for @secretsError.
  ///
  /// In en, this message translates to:
  /// **'Could not unlock or sync the encrypted backup. Check the password and connection.'**
  String get secretsError;

  /// No description provided for @secretsUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock encrypted backup'**
  String get secretsUnlock;

  /// No description provided for @secretsForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get secretsForgot;

  /// No description provided for @secretsForgotHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your keys manually before replacing the encrypted backup.'**
  String get secretsForgotHint;

  /// No description provided for @secretsOverwriteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Replace the encrypted backup with the keys and comparison source on this device? The previous encrypted backup will be lost.'**
  String get secretsOverwriteConfirm;

  /// No description provided for @secretsOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Replace backup'**
  String get secretsOverwrite;

  /// No description provided for @secretsPassword.
  ///
  /// In en, this message translates to:
  /// **'Backup password'**
  String get secretsPassword;

  /// No description provided for @secretsPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get secretsPasswordHint;

  /// No description provided for @secretsContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get secretsContinue;

  /// No description provided for @secretsMissing.
  ///
  /// In en, this message translates to:
  /// **'No encrypted key backup found. Enable it on your other device first.'**
  String get secretsMissing;

  /// No description provided for @secretsWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'The password is incorrect or the encrypted file is damaged.'**
  String get secretsWrongPassword;

  /// No description provided for @ratingDayToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get ratingDayToday;

  /// No description provided for @ratingDayYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get ratingDayYesterday;

  /// No description provided for @peopleFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favourite people'**
  String get peopleFavorites;

  /// No description provided for @peopleFrequent.
  ///
  /// In en, this message translates to:
  /// **'Often in your ratings'**
  String get peopleFrequent;

  /// No description provided for @peoplePopular.
  ///
  /// In en, this message translates to:
  /// **'Popular people'**
  String get peoplePopular;

  /// No description provided for @peopleAddFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get peopleAddFavorite;

  /// No description provided for @peopleRemoveFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get peopleRemoveFavorite;

  /// No description provided for @peopleFavoriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update favourites. Try again.'**
  String get peopleFavoriteFailed;

  /// No description provided for @peopleFavoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Save people from their pages to find them here.'**
  String get peopleFavoritesEmpty;

  /// No description provided for @peopleLoadContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue loading'**
  String get peopleLoadContinue;

  /// No description provided for @peopleLoadHint.
  ///
  /// In en, this message translates to:
  /// **'Credits load in short batches. You can use the screen while loading. Missing credits are excluded from people statistics.'**
  String get peopleLoadHint;

  /// No description provided for @peopleNoCredits.
  ///
  /// In en, this message translates to:
  /// **'People will appear as credits are loaded.'**
  String get peopleNoCredits;

  /// No description provided for @filmographyAll.
  ///
  /// In en, this message translates to:
  /// **'All work'**
  String get filmographyAll;

  /// No description provided for @statsAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time · rated titles'**
  String get statsAllTime;

  /// No description provided for @statsBest.
  ///
  /// In en, this message translates to:
  /// **'Your highest scores'**
  String get statsBest;

  /// No description provided for @statsWorst.
  ///
  /// In en, this message translates to:
  /// **'Your lowest scores'**
  String get statsWorst;

  /// No description provided for @statsFinds.
  ///
  /// In en, this message translates to:
  /// **'Personal discoveries'**
  String get statsFinds;

  /// No description provided for @statsDisappointments.
  ///
  /// In en, this message translates to:
  /// **'Personal disappointments'**
  String get statsDisappointments;

  /// No description provided for @statsFindsHint.
  ///
  /// In en, this message translates to:
  /// **'Scores at least 1 point above or below the source. Tap to explore.'**
  String get statsFindsHint;

  /// No description provided for @statsTasteAgreement.
  ///
  /// In en, this message translates to:
  /// **'Preference agreement'**
  String get statsTasteAgreement;

  /// No description provided for @statsAgreementMissing.
  ///
  /// In en, this message translates to:
  /// **'Needs at least 3 shared ratings and scores that vary.'**
  String get statsAgreementMissing;

  /// No description provided for @statsCorrelationHint.
  ///
  /// In en, this message translates to:
  /// **'Rank agreement: +1 means the same order of preferences, 0 no rank relationship, −1 the reverse. This is not a percentage of matching scores.'**
  String get statsCorrelationHint;

  /// No description provided for @statsReliableGenres.
  ///
  /// In en, this message translates to:
  /// **'Reliable genres'**
  String get statsReliableGenres;

  /// No description provided for @statsPeople.
  ///
  /// In en, this message translates to:
  /// **'People in your library'**
  String get statsPeople;

  /// No description provided for @statsPeopleFrequent.
  ///
  /// In en, this message translates to:
  /// **'Most often rated'**
  String get statsPeopleFrequent;

  /// No description provided for @statsPeopleHighest.
  ///
  /// In en, this message translates to:
  /// **'Highest average'**
  String get statsPeopleHighest;

  /// No description provided for @statsPeopleReliable.
  ///
  /// In en, this message translates to:
  /// **'Most often 8+'**
  String get statsPeopleReliable;

  /// No description provided for @statsPeoplePolarizing.
  ///
  /// In en, this message translates to:
  /// **'Mixed feelings'**
  String get statsPeoplePolarizing;

  /// No description provided for @statsDuos.
  ///
  /// In en, this message translates to:
  /// **'Favourite creative pairs'**
  String get statsDuos;

  /// No description provided for @statsBreadth.
  ///
  /// In en, this message translates to:
  /// **'Breadth of taste'**
  String get statsBreadth;

  /// No description provided for @statsBreadthHint.
  ///
  /// In en, this message translates to:
  /// **'Effective diversity grows when ratings are spread evenly between categories. Genres overlap; a title can belong to several.'**
  String get statsBreadthHint;

  /// No description provided for @statsMinimumWorks.
  ///
  /// In en, this message translates to:
  /// **'Average and reliability rankings need 3 works. Mixed feelings means at least one 8+ and one 4 or below. Spread is the standard deviation.'**
  String get statsMinimumWorks;

  /// No description provided for @statsNoQualifying.
  ///
  /// In en, this message translates to:
  /// **'Not enough qualifying works yet.'**
  String get statsNoQualifying;

  /// No description provided for @statsShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get statsShowAll;

  /// No description provided for @statsScoreHigh.
  ///
  /// In en, this message translates to:
  /// **'Scores 8–10'**
  String get statsScoreHigh;

  /// No description provided for @statsScoreLow.
  ///
  /// In en, this message translates to:
  /// **'Scores 1–4'**
  String get statsScoreLow;

  /// No description provided for @statsScoreMiddle.
  ///
  /// In en, this message translates to:
  /// **'Scores 4.5–7.5'**
  String get statsScoreMiddle;

  /// No description provided for @statsMedian.
  ///
  /// In en, this message translates to:
  /// **'Median'**
  String get statsMedian;

  /// No description provided for @statsSourceWorks.
  ///
  /// In en, this message translates to:
  /// **'Shared ratings'**
  String get statsSourceWorks;

  /// No description provided for @peopleLoadProgress.
  ///
  /// In en, this message translates to:
  /// **'People: {loaded} of {total} works'**
  String peopleLoadProgress(int loaded, int total);

  /// No description provided for @statsProfile.
  ///
  /// In en, this message translates to:
  /// **'{count} works · avg {average} · 8+: {percent}% · spread {spread}'**
  String statsProfile(int count, String average, int percent, String spread);

  /// No description provided for @statsAgreementValue.
  ///
  /// In en, this message translates to:
  /// **'{value} · {count} shared ratings'**
  String statsAgreementValue(String value, int count);

  /// No description provided for @statsBreadthSummary.
  ///
  /// In en, this message translates to:
  /// **'{genres} genres · {decades} decades · {people} people'**
  String statsBreadthSummary(int genres, int decades, int people);

  /// No description provided for @statsEffectiveDiversity.
  ///
  /// In en, this message translates to:
  /// **'Effective diversity: {genres} genres · {decades} decades'**
  String statsEffectiveDiversity(String genres, String decades);

  /// No description provided for @recommendationsWatchlist.
  ///
  /// In en, this message translates to:
  /// **'What to choose from my watchlist'**
  String get recommendationsWatchlist;

  /// No description provided for @recommendationsPeople.
  ///
  /// In en, this message translates to:
  /// **'Work by favourite people'**
  String get recommendationsPeople;

  /// No description provided for @recommendationsExplore.
  ///
  /// In en, this message translates to:
  /// **'Something different'**
  String get recommendationsExplore;

  /// No description provided for @recommendationsNotInterested.
  ///
  /// In en, this message translates to:
  /// **'Not interested'**
  String get recommendationsNotInterested;

  /// No description provided for @recommendationsActions.
  ///
  /// In en, this message translates to:
  /// **'Recommendation actions'**
  String get recommendationsActions;

  /// No description provided for @recommendationsHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden recommendations'**
  String get recommendationsHidden;

  /// No description provided for @recommendationsRestoreHint.
  ///
  /// In en, this message translates to:
  /// **'Show all recommendations hidden on this device again? Your ratings and watchlist will stay as they are.'**
  String get recommendationsRestoreHint;

  /// No description provided for @recommendationsRestore.
  ///
  /// In en, this message translates to:
  /// **'Show again'**
  String get recommendationsRestore;

  /// No description provided for @recommendationsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save this preference. Try again.'**
  String get recommendationsSaveFailed;

  /// No description provided for @recommendationsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry recommendations'**
  String get recommendationsRetry;

  /// No description provided for @recommendationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No suggestions right now. You can show hidden recommendations again.'**
  String get recommendationsEmpty;

  /// No description provided for @recommendationsBecauseTaste.
  ///
  /// In en, this message translates to:
  /// **'Matches your favourite genres'**
  String get recommendationsBecauseTaste;

  /// No description provided for @recommendationsBecauseExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore something different'**
  String get recommendationsBecauseExplore;

  /// No description provided for @recommendationsBecauseWatchlist.
  ///
  /// In en, this message translates to:
  /// **'From your watchlist'**
  String get recommendationsBecauseWatchlist;

  /// No description provided for @recommendationsBecauseTitle.
  ///
  /// In en, this message translates to:
  /// **'Because you liked {title}'**
  String recommendationsBecauseTitle(String title);

  /// No description provided for @recommendationsBecausePerson.
  ///
  /// In en, this message translates to:
  /// **'A favourite: {name}'**
  String recommendationsBecausePerson(String name);

  /// No description provided for @recommendationsBecauseAuthor.
  ///
  /// In en, this message translates to:
  /// **'You rate their work highly: {name}'**
  String recommendationsBecauseAuthor(String name);

  /// No description provided for @recommendationsHiddenTitle.
  ///
  /// In en, this message translates to:
  /// **'“{title}” hidden from recommendations'**
  String recommendationsHiddenTitle(String title);
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
