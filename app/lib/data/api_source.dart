/// Внешний API. Имена — значения колонок `api_budget.source` и
/// `external_ratings.via` — не переименовывать.
enum ApiSource { tmdb, poiskkino, omdb }

/// Чей рейтинг. Имена — значения колонки `external_ratings.source`.
enum RatingSource { kp, imdb, tmdb, rt, metacritic }

/// Чем кончился запрос рейтинга. `notFound` кэшируется так же, как `ok`, —
/// иначе фильм, которого нет на Кинопоиске, сжигал бы лимит ПоискКино при
/// каждом открытии (docs/data-model.md).
enum RatingStatus { ok, notFound, error }
