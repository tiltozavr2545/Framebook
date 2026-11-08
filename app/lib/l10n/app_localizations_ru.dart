// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get titlePremiere => 'Мировая премьера';

  @override
  String get titleCountries => 'Страны производства';

  @override
  String get titleBudget => 'Бюджет';

  @override
  String get titleRevenue => 'Мировые сборы';

  @override
  String get titleCollection => 'Связанные фильмы';

  @override
  String get titleSimilar => 'Похожие фильмы и сериалы';

  @override
  String updateAvailable(String version) {
    return 'Доступно обновление $version';
  }

  @override
  String get updateOpen => 'Открыть релиз';

  @override
  String get updateDismiss => 'Скрыть';

  @override
  String get updateCheck => 'Проверить обновления';

  @override
  String get updateFound => 'Доступно обновление';

  @override
  String get updateCurrent => 'Установлена последняя версия';

  @override
  String get updateFailed => 'Не удалось проверить обновления';

  @override
  String get coverOpen => 'Открыть обложку на весь экран';

  @override
  String get photoOpen => 'Открыть фотографию на весь экран';

  @override
  String get startupFailed =>
      'Framebook не смог открыть локальные данные. Попробуй ещё раз.';

  @override
  String get keyStatusStorageFailed =>
      'Не получилось изменить ключ. Введённое значение осталось здесь — попробуй ещё раз.';

  @override
  String get fileOperationFailed =>
      'Не получилось прочитать или сохранить файл. Попробуй ещё раз.';

  @override
  String get appTitle => 'Framebook';

  @override
  String get tabSearch => 'Обзор';

  @override
  String get tabRatings => 'Мои оценки';

  @override
  String get tabWatchlist => 'Хочу посмотреть';

  @override
  String get tabStats => 'Статистика';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsSources => 'Источники и ключи API';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsNavigationStyle => 'Нижняя панель';

  @override
  String get navigationFloating => 'Плавающая';

  @override
  String get navigationClassic => 'Классическая';

  @override
  String get peopleInFavorites => 'В избранном';

  @override
  String peopleFavoriteAdded(String name) {
    return 'В избранное: $name';
  }

  @override
  String peopleFavoriteRemoved(String name) {
    return 'Больше не в избранном: $name';
  }

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
  String get sourceTmdbComputer =>
      'Регистрируй аккаунт и получай ключ TMDB с компьютера, а не с телефона.';

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
  String get keyStatusFailed =>
      'Сервис вернул некорректный ответ — ключ не сохранён';

  @override
  String get keyStatusLimit =>
      'Ключ рабочий, но лимит запросов на сегодня исчерпан';

  @override
  String get keyStatusEmpty => 'Сначала вставь ключ';

  @override
  String get retry => 'Повторить';

  @override
  String get searchTitles => 'Фильмы';

  @override
  String get searchPeople => 'Люди';

  @override
  String get searchPeopleHint => 'Актёр, режиссёр, автор';

  @override
  String get filmographyActing => 'В кадре';

  @override
  String get filmographyDirecting => 'Режиссура';

  @override
  String get filmographyProduction => 'Продюсирование';

  @override
  String get filmographyWriting => 'Сценарий';

  @override
  String get filmographyMusic => 'Музыка';

  @override
  String get filmographyCamera => 'Операторская работа';

  @override
  String get filmographyOther => 'Другие работы';

  @override
  String get searchHint => 'Фильм или сериал';

  @override
  String get searchHistory => 'Недавно открытые';

  @override
  String get searchHistoryClear => 'Очистить историю';

  @override
  String get searchHistoryRemove => 'Удалить из истории';

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
  String get tvStatusPlanned => 'анонсирован';

  @override
  String get tvStatusInProduction => 'в производстве';

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
  String get ratingNotReleased => 'Оценка станет доступна после выхода.';

  @override
  String get titleNotReleased => 'Ещё не вышел';

  @override
  String get titleReleaseDateUnknown => 'Дата выхода неизвестна';

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
  String get ratingSaveFailed =>
      'Не получилось сохранить оценку. Заметка осталась здесь — попробуй ещё раз.';

  @override
  String get libraryChangeFailed =>
      'Не удалось сохранить изменения. Повторите попытку.';

  @override
  String get localDataLoadFailed =>
      'Не удалось загрузить вашу библиотеку. Повторите попытку.';

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
  String renumberEpisode(String from, String to) {
    return 'Ваша оценка «$from» была за серию, которая теперь «$to». Перенести её?';
  }

  @override
  String renumberSeason(String from, String to) {
    return 'Ваша оценка «$from» была за сезон, который теперь «$to». Перенести её?';
  }

  @override
  String renumberManyEpisodes(String moves) {
    return 'Ваши оценки были за серии, у которых теперь другие номера: $moves. Перенести их?';
  }

  @override
  String renumberManySeasons(String moves) {
    return 'Ваши оценки были за сезоны, у которых теперь другие номера: $moves. Перенести их?';
  }

  @override
  String renumberConflictEpisode(
    String fromScore,
    String from,
    String to,
    String toScore,
  ) {
    return 'Оценка $fromScore у «$from» была за серию, которая теперь «$to», а там уже стоит ваша $toScore. Какую оставить?';
  }

  @override
  String renumberConflictSeason(
    String fromScore,
    String from,
    String to,
    String toScore,
  ) {
    return 'Оценка $fromScore у «$from» была за сезон, который теперь «$to», а там уже стоит ваша $toScore. Какую оставить?';
  }

  @override
  String watchlistRenumber(String from, String to) {
    return 'Сезон в списке «Буду смотреть» переместился с $from на $to. Перенести?';
  }

  @override
  String watchlistRenumberMany(String moves) {
    return 'Сезоны в списке «Буду смотреть» перенумерованы: $moves. Перенести?';
  }

  @override
  String get renumberMove => 'Перенести';

  @override
  String get renumberKeep => 'Оставить';

  @override
  String renumberKeepScore(String score) {
    return 'Оставить $score';
  }

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

  @override
  String get ratingsSortDivergence => 'По расхождению';

  @override
  String ratingDivergence(String value) {
    return 'моя минус их: $value';
  }

  @override
  String get divergenceFurthest => 'Сильнее всего';

  @override
  String get divergenceHigher => 'Я выше';

  @override
  String get divergenceLower => 'Я ниже';

  @override
  String coverageLoaded(String source, int loaded, int total) {
    return 'Рейтинги $source загружены для $loaded из $total';
  }

  @override
  String coverageNeedsKey(String source) {
    return 'Чтобы сравнивать с $source, добавь ключ в «Источниках»';
  }

  @override
  String get pairTitle => 'Попарная калибровка';

  @override
  String get pairHow => 'Как подбираются пары';

  @override
  String get pairIntro =>
      'Сравни оценённые фильмы и проверь свою шкалу. Алгоритм выбирает близкие оценки и жанры, затем проверяет цепочки предыдущих ответов. Оценки появятся после выбора.';

  @override
  String get pairStart => 'Сравнить фильмы';

  @override
  String get pairNeedFilms => 'Для начала нужны хотя бы два оценённых фильма.';

  @override
  String get pairDailyHint => 'До 5 сравнений в день.';

  @override
  String pairProgress(int count) {
    return 'Сегодня сравнено: $count из 5';
  }

  @override
  String get pairQuestion => 'Какой фильм понравился больше?';

  @override
  String get pairFirst => 'Первый фильм';

  @override
  String get pairSecond => 'Второй фильм';

  @override
  String get pairPreferFirst => 'Первый понравился больше';

  @override
  String get pairPreferSecond => 'Второй понравился больше';

  @override
  String get pairEqual => 'Понравились одинаково';

  @override
  String get pairSkip => 'Пропустить / не помню';

  @override
  String get pairReasonBoundary =>
      'Проверяем границу оценок на сопоставимых фильмах.';

  @override
  String get pairReasonChain =>
      'Предыдущие ответы образуют цепочку предпочтений, которая расходится с оценками. Проверим её напрямую.';

  @override
  String get pairAgrees => 'Текущие оценки согласуются с ответом.';

  @override
  String get pairDisagrees =>
      'Ответ расходится с оценками. Выбери правку или оставь оценки как есть.';

  @override
  String pairCorrection(String title, String before, String after) {
    return '$title: $before → $after';
  }

  @override
  String get pairChangeAnswer => 'Изменить ответ';

  @override
  String get pairKeep => 'Оставить оценки и сохранить ответ';

  @override
  String get pairNext => 'Сохранить ответ и продолжить';

  @override
  String get pairLimit =>
      'На сегодня пять сравнений завершены. Возвращайся завтра.';

  @override
  String get pairFinished =>
      'Подходящие новые пары с текущими оценками закончились. Новые оценки или изменение баллов откроют другие сравнения.';

  @override
  String get pairChanged =>
      'Эти оценки изменились. Следующая пара учитывает актуальные баллы.';

  @override
  String get pairSaveFailed =>
      'Не удалось сохранить сравнение. Твой выбор сохранён на экране — попробуй ещё раз.';

  @override
  String get pairLoadFailed =>
      'Не удалось загрузить оценки или историю сравнений.';

  @override
  String get statsEmpty => 'Статистика появится, когда будут оценки.';

  @override
  String statsRatingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count оценки',
      many: '$count оценок',
      few: '$count оценки',
      one: '$count оценка',
    );
    return '$_temp0';
  }

  @override
  String get statsDistribution => 'Твои оценки';

  @override
  String get statsCompared => 'В сравнении с другими';

  @override
  String get statsComparedHint =>
      'Твоя оценка минус их: «+» значит, ты оцениваешь выше.';

  @override
  String get statsDeviationOnAverage => 'в среднем';

  @override
  String statsDeviationAbsolute(String value) {
    return 'в среднем на $value в любую сторону';
  }

  @override
  String statsDeviationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'по $count оценкам',
      one: 'по $count оценке',
    );
    return '$_temp0';
  }

  @override
  String statsDeviationNone(String source) {
    return 'Пока не с чем сравнивать: рейтингов $source нет.';
  }

  @override
  String get statsGenres => 'По жанрам';

  @override
  String get statsGenresOffline =>
      'Названия жанров приходят из TMDB, а сейчас нет связи.';

  @override
  String get statsDecades => 'По десятилетиям';

  @override
  String statsDecade(String decade) {
    return '$decade-е';
  }

  @override
  String get settingsSync => 'Синхронизация и копии';

  @override
  String get syncDrive => 'Google Диск';

  @override
  String get syncIntro =>
      'Оценки, заметки, список «Буду смотреть» и избранные люди хранятся в скрытой папке твоего Google Диска и объединяются между устройствами. Приложение видит только эту папку.';

  @override
  String get syncNotConfigured =>
      'В этой сборке приложения вход через Google не настроен.';

  @override
  String get syncSignIn => 'Войти через Google';

  @override
  String syncSignedInAs(String email) {
    return 'Вход выполнен: $email';
  }

  @override
  String get syncNow => 'Синхронизировать';

  @override
  String get syncInProgress => 'Синхронизация…';

  @override
  String syncLast(String when) {
    return 'Последняя синхронизация: $when';
  }

  @override
  String get syncNever => 'Ещё не синхронизировано';

  @override
  String get syncErrorUnauthorized =>
      'Доступ к Google Диску истёк. Войди заново.';

  @override
  String get syncErrorQuota =>
      'Google Диск заполнен, синхронизация приостановлена. На этом устройстве всё работает.';

  @override
  String get syncErrorTooLarge =>
      'Файл слишком большой. Допускается до 32 МиБ в сжатом виде и до 128 МиБ после распаковки.';

  @override
  String get syncErrorBroken =>
      'Файл на Google Диске не читается. Его не трогали; можно восстановить ежедневную копию.';

  @override
  String get syncErrorTooNew =>
      'Файл на Google Диске записан более новой версией Framebook. Обнови приложение, чтобы синхронизироваться.';

  @override
  String get syncErrorFailed =>
      'Не удалось завершить синхронизацию. Повторите попытку позже.';

  @override
  String get syncSignInAgain => 'Войти заново';

  @override
  String get syncSignOut => 'Выйти';

  @override
  String get syncSignInFailed =>
      'Не получилось войти в Google. Попробуй ещё раз.';

  @override
  String get syncOffline => 'Нет связи. Попробуй, когда появится интернет.';

  @override
  String get syncFirstTitle => 'Объединить с Google Диском?';

  @override
  String syncFirstBody(int device, int drive, int merged) {
    return 'Оценок на устройстве: $device. На Google Диске: $drive. После объединения: $merged. Ничего не потеряется: для каждого тайтла побеждает последнее изменение.';
  }

  @override
  String get syncMerge => 'Объединить';

  @override
  String get syncBackups => 'Ежедневные копии';

  @override
  String get syncBackupsHint =>
      'Храним до семи копий за дни, когда синхронизируемые данные менялись. Восстановление заменяет сохранённые оценки, список «Буду смотреть» и избранных людей на всех устройствах.';

  @override
  String get syncBackupsEmpty =>
      'Копий пока нет: копия создаётся перед первым изменением существующего файла синхронизации за день.';

  @override
  String get syncRestore => 'Восстановить';

  @override
  String syncRestoreTitle(String date) {
    return 'Восстановить копию от $date?';
  }

  @override
  String get syncRepairBody =>
      'Восстановить эту копию и исправить нечитаемый файл синхронизации? Повреждённый оригинал останется отдельно на Диске. Ежедневные копии и зашифрованные ключи сохранятся. Файлы более новой версии приложения не заменяются.';

  @override
  String get syncRestoreBody =>
      'Изменения оценок, списка «Буду смотреть» и избранных людей после этой копии будут отменены на всех устройствах. Записи, окончательно удалённые при очистке, нельзя вернуть из старой копии.';

  @override
  String get syncRestored => 'Копия восстановлена';

  @override
  String get syncDelete => 'Удалить данные с Google Диска';

  @override
  String get syncDeleteTitle => 'Удалить данные с Google Диска?';

  @override
  String get syncDeleteBody =>
      'Файл и ежедневные копии будут удалены, а это устройство выйдет из аккаунта. Оценки на устройствах останутся. Другое устройство, где вход ещё выполнен, вернёт свои данные при следующей синхронизации.';

  @override
  String get syncDeleted => 'Удалено с Google Диска';

  @override
  String get syncStaleTitle => 'Изменения удалённых записей';

  @override
  String syncStaleBody(int count) {
    return 'Несинхронизированных оценок и записей «Хочу посмотреть» на этом устройстве, которые конфликтуют с более поздним удалением на Google Диске: $count. «Оставить» восстановит эти записи на твоих устройствах. «Отбросить» применит удаление. Пока ты не выберешь, синхронизация на паузе.';
  }

  @override
  String get syncStaleKeep => 'Оставить';

  @override
  String get syncStaleDiscard => 'Отбросить';

  @override
  String get syncStalePaused => 'Синхронизация на паузе: нужен твой ответ';

  @override
  String get syncStaleReview => 'Открыть';

  @override
  String get backupFile => 'Экспорт и импорт';

  @override
  String get exportFile => 'Экспорт в файл';

  @override
  String get exportFileHint =>
      'Оценки, заметки, список «Буду смотреть» и избранные люди в одном файле. Работает без Google.';

  @override
  String get exportDone => 'Сохранено';

  @override
  String get importFile => 'Импорт из файла';

  @override
  String get importTitle => 'Импорт оценок';

  @override
  String importBody(int device, int inFile, int merged) {
    return 'Оценок на устройстве: $device. В файле: $inFile. После объединения: $merged.';
  }

  @override
  String get importMerge => 'Объединить';

  @override
  String get importReplace => 'Заменить всё';

  @override
  String get importReplaceTitle => 'Заменить всё содержимым файла?';

  @override
  String get importReplaceBody =>
      'Оценки, записи списка «Буду смотреть» и избранные люди, которых нет в файле, будут удалены на всех твоих устройствах.';

  @override
  String get importBroken => 'Этот файл не читается.';

  @override
  String get importTooNew =>
      'Файл записан более новой версией Framebook. Обнови приложение, чтобы его импортировать.';

  @override
  String get importDone => 'Импортировано';

  @override
  String importStaleBody(int count) {
    return 'Несинхронизированных оценок и записей «Хочу посмотреть» на этом устройстве, которые конфликтуют с более поздним удалением в файле: $count. «Оставить» восстановит эти записи. «Отбросить» применит удаление.';
  }

  @override
  String get reelHint =>
      'Потяни плёнку, чтобы выбрать оценку. Пока она движется, здесь видно твои другие оценки того же типа.';

  @override
  String get reelFirst =>
      'Это твоя первая оценка такого типа — сравнивать пока не с чем.';

  @override
  String get navDiscover => 'Обзор';

  @override
  String get navRatings => 'Оценки';

  @override
  String get navWatchlist => 'В планах';

  @override
  String get navStats => 'Статистика';

  @override
  String get shelfForYou => 'Для тебя';

  @override
  String get shelfTrending => 'В тренде на неделе';

  @override
  String get shelfNowPlaying => 'Сейчас в кино';

  @override
  String get shelfBest => 'Лучшее всех времён';

  @override
  String get shelvesOffline =>
      'Нет связи. Подборки приходят из TMDB и появятся, когда будет интернет.';

  @override
  String get castTitle => 'В ролях';

  @override
  String crewCreator(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Создатели',
      one: 'Создатель',
    );
    return '$_temp0';
  }

  @override
  String crewDirector(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Режиссёры',
      one: 'Режиссёр',
    );
    return '$_temp0';
  }

  @override
  String get crewWriter => 'Сценарий';

  @override
  String get crewComposer => 'Композитор';

  @override
  String get crewCinematographer => 'Оператор';

  @override
  String personBorn(String date) {
    return 'Дата рождения: $date';
  }

  @override
  String personBornIn(String date, String place) {
    return 'Дата рождения: $date, $place';
  }

  @override
  String personDied(String date) {
    return 'Дата смерти: $date';
  }

  @override
  String get personMore => 'Ещё';

  @override
  String get personFilmography => 'Фильмография';

  @override
  String personActing(int count) {
    return 'Роли · $count';
  }

  @override
  String personCrew(int count) {
    return 'За кадром · $count';
  }

  @override
  String statsAverageOver(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'твоя средняя по $count оценкам',
      one: 'твоя средняя по $count оценке',
    );
    return '$_temp0';
  }

  @override
  String aboutVersion(String name, String build) {
    return 'Версия $name, сборка $build';
  }

  @override
  String aboutVersionName(String name) {
    return 'Версия $name';
  }

  @override
  String get savedCardOffline =>
      'Нет связи: это сохранённая карточка. Описание и актёры появятся, когда будет интернет.';

  @override
  String get savedCardFailed => 'TMDB не ответил: это сохранённая карточка.';

  @override
  String get secretsRestoreFromDrive => 'Восстановить с Google Диска';

  @override
  String get secretsTitle => 'Синхронизация ключей API и источника сравнения';

  @override
  String get secretsHint =>
      'Данные защищены отдельным паролем. Изменения загружаются автоматически.';

  @override
  String get secretsError =>
      'Не удалось открыть или синхронизировать зашифрованную копию. Проверь пароль и подключение.';

  @override
  String get secretsUnlock => 'Открыть зашифрованную копию';

  @override
  String get secretsForgot => 'Забыл пароль?';

  @override
  String get secretsForgotHint =>
      'Перед заменой копии введи ключи на этом устройстве вручную.';

  @override
  String get secretsOverwriteConfirm =>
      'Заменить зашифрованную копию ключами и источником сравнения с этого устройства? Предыдущая копия будет потеряна.';

  @override
  String get secretsOverwrite => 'Заменить копию';

  @override
  String get secretsPassword => 'Пароль копии';

  @override
  String get secretsPasswordHint => 'Не менее 8 символов';

  @override
  String get secretsContinue => 'Продолжить';

  @override
  String get secretsMissing =>
      'Зашифрованная копия ключей не найдена. Сначала включите её на другом устройстве.';

  @override
  String get secretsWrongPassword =>
      'Неверный пароль или зашифрованный файл повреждён.';

  @override
  String get ratingDayToday => 'Сегодня';

  @override
  String get ratingDayYesterday => 'Вчера';

  @override
  String get peopleFavorites => 'Избранные люди';

  @override
  String get peopleFrequent => 'Часто встречаются в ваших оценках';

  @override
  String get peoplePopular => 'Популярные люди';

  @override
  String get peopleAddFavorite => 'Добавить в избранное';

  @override
  String get peopleRemoveFavorite => 'Убрать из избранного';

  @override
  String get peopleFavoriteFailed =>
      'Не удалось изменить избранное. Попробуйте ещё раз.';

  @override
  String get peopleFavoritesEmpty =>
      'Добавляйте людей в избранное на их страницах — они появятся здесь.';

  @override
  String get peopleLoadContinue => 'Продолжить загрузку';

  @override
  String get peopleLoadHint =>
      'Участники загружаются короткими порциями. Экран доступен во время загрузки. Работы без сведений об участниках пока не учитываются в статистике людей.';

  @override
  String get peopleNoCredits =>
      'Люди появятся по мере загрузки участников работ.';

  @override
  String get filmographyAll => 'Все работы';

  @override
  String get statsAllTime => 'За всё время · оценённые работы';

  @override
  String get statsBest => 'Ваши лучшие оценки';

  @override
  String get statsWorst => 'Ваши худшие оценки';

  @override
  String get statsFinds => 'Личные находки';

  @override
  String get statsDisappointments => 'Личные разочарования';

  @override
  String get statsFindsHint =>
      'Оценки минимум на 1 балл выше или ниже источника. Нажмите, чтобы посмотреть работы.';

  @override
  String get statsTasteAgreement => 'Совпадение предпочтений';

  @override
  String get statsAgreementMissing =>
      'Нужно минимум 3 общие оценки и различающиеся баллы.';

  @override
  String get statsCorrelationHint =>
      'Совпадение порядка предпочтений: +1 — одинаковый, 0 — нет связи, −1 — противоположный. Это не процент одинаковых оценок.';

  @override
  String get statsReliableGenres => 'Надёжные жанры';

  @override
  String get statsPeople => 'Люди в вашей библиотеке';

  @override
  String get statsPeopleFrequent => 'Чаще всего оцениваете';

  @override
  String get statsPeopleHighest => 'Высокая средняя оценка';

  @override
  String get statsPeopleReliable => 'Чаще получаются 8+';

  @override
  String get statsPeoplePolarizing => 'Неоднозначные авторы';

  @override
  String get statsDuos => 'Любимые творческие пары';

  @override
  String get statsBreadth => 'Широта вкуса';

  @override
  String get statsBreadthHint =>
      'Эффективное разнообразие растёт, когда оценки равномерно распределены между категориями. Жанры пересекаются: у работы может быть несколько.';

  @override
  String get statsMinimumWorks =>
      'Для рейтингов по среднему баллу и надёжности нужны 3 работы. Неоднозначность — есть хотя бы одна оценка 8+ и одна 4 или ниже. Разброс — стандартное отклонение.';

  @override
  String get statsNoQualifying => 'Пока недостаточно подходящих работ.';

  @override
  String get statsShowAll => 'Показать все';

  @override
  String get statsScoreHigh => 'Оценки 8–10';

  @override
  String get statsScoreLow => 'Оценки 1–4';

  @override
  String get statsScoreMiddle => 'Оценки 4,5–7,5';

  @override
  String get statsMedian => 'Медиана';

  @override
  String get statsSourceWorks => 'Общие оценки';

  @override
  String peopleLoadProgress(int loaded, int total) {
    return 'Участники: $loaded из $total работ';
  }

  @override
  String statsProfile(int count, String average, int percent, String spread) {
    return '$count работ · средняя $average · 8+: $percent% · разброс $spread';
  }

  @override
  String statsAgreementValue(String value, int count) {
    return '$value · $count общих оценок';
  }

  @override
  String statsBreadthSummary(int genres, int decades, int people) {
    return '$genres жанров · $decades десятилетий · $people людей';
  }

  @override
  String statsEffectiveDiversity(String genres, String decades) {
    return 'Эффективное разнообразие: $genres жанров · $decades десятилетий';
  }

  @override
  String get recommendationsWatchlist => 'Что выбрать из моего списка';

  @override
  String get recommendationsPeople => 'Работы избранных людей';

  @override
  String get recommendationsExplore => 'Попробовать необычное';

  @override
  String get recommendationsNotInterested => 'Не интересно';

  @override
  String get recommendationsActions => 'Действия с рекомендацией';

  @override
  String get recommendationsHidden => 'Скрытые рекомендации';

  @override
  String get recommendationsRestoreHint =>
      'Снова показывать все рекомендации, скрытые на этом устройстве? Оценки и список «В планах» останутся прежними.';

  @override
  String get recommendationsRestore => 'Показывать снова';

  @override
  String get recommendationsSaveFailed =>
      'Не удалось сохранить настройку. Попробуй ещё раз.';

  @override
  String get recommendationsRetry => 'Обновить рекомендации';

  @override
  String get recommendationsEmpty =>
      'Пока нет предложений. Можно вернуть скрытые рекомендации.';

  @override
  String get recommendationsBecauseTaste => 'По твоим любимым жанрам';

  @override
  String get recommendationsBecauseExplore => 'Открой что-то новое';

  @override
  String get recommendationsBecauseWatchlist => 'Из твоего списка «В планах»';

  @override
  String recommendationsBecauseTitle(String title) {
    return 'Потому что тебе понравился «$title»';
  }

  @override
  String recommendationsBecausePerson(String name) {
    return 'В избранном: $name';
  }

  @override
  String recommendationsBecauseAuthor(String name) {
    return 'Ты высоко оцениваешь: $name';
  }

  @override
  String recommendationsHiddenTitle(String title) {
    return '«$title» скрыт из рекомендаций';
  }
}
