/// An external API. The names are values of the `api_budget.source` and
/// `external_ratings.via` columns — don't rename them.
enum ApiSource { tmdb, poiskkino, omdb }

/// Whose rating. The names are values of the `external_ratings.source` column.
enum RatingSource { kp, imdb, tmdb, rt, metacritic }

/// How a rating request ended. `notFound` is cached just like `ok`; otherwise a
/// film missing from Kinopoisk would burn the PoiskKino limit on every open
/// (docs/data-model.md).
enum RatingStatus { ok, notFound, error }
