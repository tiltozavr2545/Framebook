#!/bin/sh
# Снимает живые ответы TMDB, ПоискКино и OMDb в app/test/fixtures/ — Этап 0,
# пункт 2 (docs/implementation-plan.md). Тесты потом работают только на этих
# файлах и во внешние API не ходят.
#
# Ключи читаются из файла ВНЕ репозитория (по умолчанию
# ~/.config/framebook/keys.env):
#
#   TMDB_TOKEN=eyJ...        # API Read Access Token (v4)
#   POISKKINO_KEY=...        # необязательно
#   OMDB_KEY=...             # необязательно
#
# Источник без ключа пропускается. ПоискКино: скрипт тратит 8 из 200
# суточных запросов.
#
# Ключи передаются только в заголовке или в query и в сохранённые файлы не
# попадают: в конце скрипт проверяет, что ни одно значение ключа не
# встречается в fixtures, и падает, если встречается.
set -eu

keys_file=${FRAMEBOOK_KEYS:-$HOME/.config/framebook/keys.env}
[ -f "$keys_file" ] || {
	echo "Нет файла с ключами: $keys_file" >&2
	exit 1
}
# shellcheck disable=SC1090
. "$keys_file"

repo_root=$(git rev-parse --show-toplevel)
out="$repo_root/app/test/fixtures"
mkdir -p "$out/tmdb" "$out/poiskkino" "$out/omdb"

# fetch <файл> <url> [заголовок]
fetch() {
	file=$1
	url=$2
	header=${3:-}
	tmp="$file.tmp"
	if [ -n "$header" ]; then
		code=$(curl -sS -m 30 -o "$tmp" -w '%{http_code}' -H "$header" -H 'Accept: application/json' "$url")
	else
		code=$(curl -sS -m 30 -o "$tmp" -w '%{http_code}' -H 'Accept: application/json' "$url")
	fi
	if command -v python3 >/dev/null 2>&1; then
		python3 -I -c 'import json,sys; d=json.load(open(sys.argv[1])); json.dump(d, open(sys.argv[2],"w"), ensure_ascii=False, indent=2)' "$tmp" "$file" 2>/dev/null || mv "$tmp" "$file"
		rm -f "$tmp"
	else
		mv "$tmp" "$file"
	fi
	printf '%-55s HTTP %s\n' "${file#"$out"/}" "$code"
}

if [ -n "${TMDB_TOKEN:-}" ]; then
	t="https://api.themoviedb.org/3"
	h="Authorization: Bearer $TMDB_TOKEN"
	fetch "$out/tmdb/configuration.json" "$t/configuration" "$h"
	fetch "$out/tmdb/search_multi_matrix_ru.json" "$t/search/multi?query=%D0%9C%D0%B0%D1%82%D1%80%D0%B8%D1%86%D0%B0&language=ru-RU" "$h"
	fetch "$out/tmdb/movie_603_ru.json" "$t/movie/603?language=ru-RU&append_to_response=external_ids" "$h"
	fetch "$out/tmdb/tv_1399_ru.json" "$t/tv/1399?language=ru-RU&append_to_response=external_ids" "$h"
	fetch "$out/tmdb/tv_1399_season_1_ru.json" "$t/tv/1399/season/1?language=ru-RU" "$h"
	fetch "$out/tmdb/tv_1399_s1e3_external_ids.json" "$t/tv/1399/season/1/episode/3/external_ids" "$h"
	fetch "$out/tmdb/genre_movie_ru.json" "$t/genre/movie/list?language=ru-RU" "$h"
	fetch "$out/tmdb/genre_tv_ru.json" "$t/genre/tv/list?language=ru-RU" "$h"
	fetch "$out/tmdb/movie_not_found.json" "$t/movie/999999999" "$h"
else
	echo "TMDB_TOKEN не задан — пропускаю TMDB"
fi

if [ -n "${POISKKINO_KEY:-}" ]; then
	p="https://api.poiskkino.dev/v1.5"
	h="X-API-KEY: $POISKKINO_KEY"
	# Матрица: tmdb 603, imdb tt0133093, kp 301. Игра престолов: tmdb 1399, kp 464963.
	# Без фильтра по типу tmdb 603 находит и фильм, и сериал с тем же номером
	# (у TMDB раздельная нумерация movie и tv) — фикстура это фиксирует.
	fetch "$out/poiskkino/movie_by_tmdb_603.json" "$p/movie?externalId.tmdb=603" "$h"
	fetch "$out/poiskkino/movie_by_tmdb_603_type_movie.json" "$p/movie?externalId.tmdb=603&type=movie" "$h"
	fetch "$out/poiskkino/movie_by_imdb_tt0133093.json" "$p/movie?externalId.imdb=tt0133093" "$h"
	fetch "$out/poiskkino/movie_301.json" "$p/movie/301" "$h"
	fetch "$out/poiskkino/tv_by_tmdb_1399.json" "$p/movie?externalId.tmdb=1399&type=tv-series" "$h"
	# Есть ли у сезонов/серий рейтинг КП — ради этого и запрос (проверить).
	fetch "$out/poiskkino/season_464963.json" "$p/season?movieId=464963&limit=2" "$h"
	# tmdb id вне 1..2000000 ПоискКино отбивает 400 (ошибка валидации) —
	# честное «не найдено» снимаем по несуществующему imdb id.
	fetch "$out/poiskkino/movie_by_tmdb_out_of_range.json" "$p/movie?externalId.tmdb=999999999" "$h"
	fetch "$out/poiskkino/movie_by_imdb_not_found.json" "$p/movie?externalId.imdb=tt9999999" "$h"
else
	echo "POISKKINO_KEY не задан — пропускаю ПоискКино"
fi

if [ -n "${OMDB_KEY:-}" ]; then
	o="https://www.omdbapi.com/?apikey=$OMDB_KEY"
	fetch "$out/omdb/tt0133093.json" "$o&i=tt0133093"
	fetch "$out/omdb/tt0944947_series.json" "$o&i=tt0944947"
	fetch "$out/omdb/tt0944947_season_1.json" "$o&i=tt0944947&Season=1"
	fetch "$out/omdb/tt0944947_s1e3.json" "$o&i=tt0944947&Season=1&Episode=3"
	fetch "$out/omdb/malformed_id.json" "$o&i=tt9999999999"
	fetch "$out/omdb/not_found.json" "$o&i=tt9999999"
	fetch "$out/omdb/invalid_key.json" "https://www.omdbapi.com/?apikey=invalid&i=tt0133093"
else
	echo "OMDB_KEY не задан — пропускаю OMDb"
fi

leak=0
for key in "${TMDB_TOKEN:-}" "${POISKKINO_KEY:-}" "${OMDB_KEY:-}"; do
	[ -n "$key" ] || continue
	if grep -rqF -- "$key" "$out"; then
		echo "ОШИБКА: значение ключа найдено в $out — не коммитить!" >&2
		leak=1
	fi
done
[ "$leak" -eq 0 ] || exit 1
echo "Готово, ключей в фикстурах нет."
