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

  @override
  String get retry => 'Повторить';

  @override
  String get searchHint => 'Фильм или сериал';

  @override
  String get searchClear => 'Очистить';

  @override
  String get searchEmpty => 'Найди фильм или сериал по названию.';

  @override
  String searchNothing(String query) {
    return 'По запросу «$query» ничего не нашлось.';
  }

  @override
  String get kindMovie => 'Фильм';

  @override
  String get kindTv => 'Сериал';

  @override
  String get failureOffline =>
      'Нет связи. Поиску и карточкам нужен интернет; то, что уже открывалось, показывается из кэша.';

  @override
  String get failureTmdbKey => 'TMDB не принял ключ. Проверь его в настройках.';

  @override
  String get failureNotFound => 'В TMDB такого нет.';

  @override
  String get failureTmdb =>
      'TMDB ответил не так, как надо. Попробуй чуть позже.';

  @override
  String get titleOverview => 'Описание';

  @override
  String get titleSeasons => 'Сезоны';

  @override
  String get titleEpisodes => 'Серии';

  @override
  String get tvStatusRunning => 'выходит';

  @override
  String get tvStatusEnded => 'завершён';

  @override
  String get tvStatusCanceled => 'закрыт';

  @override
  String seasonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сезона',
      many: '$count сезонов',
      few: '$count сезона',
      one: '$count сезон',
    );
    return '$_temp0';
  }

  @override
  String episodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count серии',
      many: '$count серий',
      few: '$count серии',
      one: '$count серия',
    );
    return '$_temp0';
  }

  @override
  String seasonNumber(int number) {
    return 'Сезон $number';
  }

  @override
  String get seasonSpecials => 'Спецвыпуски';

  @override
  String episodeNumber(int number) {
    return 'Серия $number';
  }

  @override
  String episodeCode(int season, int episode) {
    return 'Сезон $season · серия $episode';
  }

  @override
  String runtimeMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String runtimeHours(int hours) {
    return '$hours ч';
  }

  @override
  String runtimeHoursMinutes(int hours, int minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String get ratingKinopoisk => 'Кинопоиск';

  @override
  String ratingVotes(String count) {
    return '$count голосов';
  }

  @override
  String ratingAsOf(String date) {
    return 'на $date';
  }

  @override
  String get ratingSeasonAverage => 'среднее по сериям';

  @override
  String get ratingNoData => 'нет данных';

  @override
  String get ratingNeedsKey => 'добавь ключ';

  @override
  String get ratingOffline => 'нет связи';

  @override
  String get ratingLimit => 'лимит на сегодня';

  @override
  String get ratingKeyRejected => 'ключ не принят';

  @override
  String get ratingFailed => 'ошибка источника';

  @override
  String get aboutTitle => 'О приложении';

  @override
  String get aboutIntro =>
      'Framebook — личный дневник оценок фильмов и сериалов со сравнением с Кинопоиском, IMDb и другими. Сервера нет: всё, что ты оценил, хранится на телефоне.';

  @override
  String get aboutData => 'Откуда данные';

  @override
  String get aboutTmdb => 'Каталог, постеры, сезоны и серии, рейтинг TMDB.';

  @override
  String get aboutPoiskkinoTitle => 'ПоискКино API';

  @override
  String get aboutPoiskkino =>
      'Рейтинг Кинопоиска. Неофициальный сервис, с Кинопоиском не связан.';

  @override
  String get aboutOmdb => 'Рейтинги IMDb, Rotten Tomatoes и Metacritic.';

  @override
  String get aboutSource => 'Исходный код';

  @override
  String get aboutLicenses => 'Лицензии открытого ПО';

  @override
  String get cancel => 'Отмена';

  @override
  String get done => 'Готово';

  @override
  String get undo => 'Вернуть';

  @override
  String get ratingRate => 'Оценить';

  @override
  String get ratingMine => 'Моя оценка';

  @override
  String get ratingEdit => 'Изменить';

  @override
  String get ratingDelete => 'Удалить';

  @override
  String get ratingDeleteTitle => 'Удалить оценку?';

  @override
  String get ratingDeleteBody =>
      'Оценка и заметка удалятся на всех твоих устройствах.';

  @override
  String get ratingEditorTitle => 'Твоя оценка';

  @override
  String get ratingNote => 'Заметка';

  @override
  String get ratingSave => 'Сохранить';

  @override
  String partsAverageSeasons(int count, String average) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Средняя по $count сезонам: $average',
      one: 'Средняя по $count сезону: $average',
    );
    return '$_temp0';
  }

  @override
  String partsAverageEpisodes(int count, String average) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Средняя по $count сериям: $average',
      one: 'Средняя по $count серии: $average',
    );
    return '$_temp0';
  }

  @override
  String get calibrationTitle => 'С чем это в одном ряду';

  @override
  String get calibrationHigher => 'На полбалла выше';

  @override
  String get calibrationLower => 'На полбалла ниже';

  @override
  String calibrationSame(String score) {
    return 'Тоже $score';
  }

  @override
  String calibrationAbove(String score) {
    return 'Ступенькой выше · $score';
  }

  @override
  String calibrationBelow(String score) {
    return 'Ступенькой ниже · $score';
  }

  @override
  String get calibrationNothing =>
      'Рядом с этой оценкой больше ничего такого же типа нет.';

  @override
  String get watchlistAdd => 'Хочу посмотреть';

  @override
  String get watchlistListed => 'В списке';

  @override
  String get watchlistRemove => 'Убрать из списка';

  @override
  String watchlistRemoved(String title) {
    return '«$title» убран из списка';
  }

  @override
  String get watchlistEmpty =>
      'Пока пусто. Открой фильм или сериал и нажми «Хочу посмотреть».';

  @override
  String get ratingsSort => 'Сортировка';

  @override
  String get ratingsSortDate => 'По дате оценки';

  @override
  String get ratingsSortScore => 'По моей оценке';

  @override
  String get ratingsSortYear => 'По году';

  @override
  String get ratingsSortTitle => 'По названию';

  @override
  String get ratingsEmpty =>
      'Ты ещё ничего не оценил. Найди фильм в поиске и поставь оценку.';

  @override
  String get ratingsEmptyKind => 'Такого пока ничего не оценено.';

  @override
  String get kindAll => 'Всё';

  @override
  String get kindMovies => 'Фильмы';

  @override
  String get kindSeries => 'Сериалы';

  @override
  String get kindSeasons => 'Сезоны';

  @override
  String get kindEpisodes => 'Серии';
}
