// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Framebook';

  @override
  String get tabSearch => 'Поиск';

  @override
  String get tabRatings => 'Мои оценки';

  @override
  String get tabWatchlist => 'Хочу посмотреть';

  @override
  String get tabStats => 'Статистика';

  @override
  String get tabSearchPlaceholder => 'Здесь будет поиск фильмов и сериалов.';

  @override
  String get tabRatingsPlaceholder => 'Здесь будут твои оценки.';

  @override
  String get tabWatchlistPlaceholder =>
      'Здесь будут фильмы, которые хочешь посмотреть.';

  @override
  String get tabStatsPlaceholder => 'Статистика появится, когда будут оценки.';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsSources => 'Источники и ключи API';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get languageSystem => 'Как в системе';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get themeSystem => 'Как в системе';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get onboardingTitle => 'Добро пожаловать во Framebook';

  @override
  String get onboardingIntro =>
      'У Framebook нет сервера: данные о фильмах приходят прямо из TMDB, Кинопоиска и IMDb по твоим собственным бесплатным ключам API. Для начала нужен только ключ TMDB.';

  @override
  String get onboardingContinue => 'Продолжить';

  @override
  String get onboardingTmdbRequired =>
      'Чтобы продолжить, добавь рабочий ключ TMDB.';

  @override
  String get sourcesTitle => 'Источники и ключи API';

  @override
  String get sourcesHowToGet => 'Как получить ключи';

  @override
  String get sourceRequired => 'обязательно';

  @override
  String get sourceOptional => 'необязательно';

  @override
  String get sourceTmdbName => 'TMDB';

  @override
  String get sourceTmdbDescription =>
      'Поиск, карточки, сезоны и серии, постеры, рейтинг TMDB.';

  @override
  String get sourceTmdbHint =>
      'API Read Access Token (начинается с eyJ…) или API key';

  @override
  String get sourcePoiskkinoName => 'ПоискКино';

  @override
  String get sourcePoiskkinoDescription =>
      'Рейтинг Кинопоиска. Бесплатно — 200 запросов в сутки.';

  @override
  String get sourcePoiskkinoHint => 'Ключ из Telegram-бота @poiskkinodev_bot';

  @override
  String get sourceOmdbName => 'OMDb';

  @override
  String get sourceOmdbDescription =>
      'Рейтинги IMDb, Rotten Tomatoes и Metacritic. Бесплатно — 1000 запросов в сутки.';

  @override
  String get sourceOmdbHint => 'Ключ из письма OMDb (сначала активируй его)';

  @override
  String get keySave => 'Проверить и сохранить';

  @override
  String get keyRemove => 'Удалить';

  @override
  String get keyShow => 'Показать ключ';

  @override
  String get keyHide => 'Скрыть ключ';

  @override
  String get keyStatusMissing => 'Не задан';

  @override
  String get keyStatusChecking => 'Проверяю…';

  @override
  String get keyStatusValid => 'Ключ работает';

  @override
  String get keyStatusUnverified => 'Сохранён без проверки: нет связи';

  @override
  String get keyStatusInvalid => 'Сервис не принял этот ключ';

  @override
  String get keyStatusLimit =>
      'Ключ рабочий, но лимит запросов на сегодня исчерпан';

  @override
  String get keyStatusEmpty => 'Сначала вставь ключ';
}
