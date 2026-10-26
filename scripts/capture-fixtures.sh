#!/bin/sh
# Captures live TMDB, PoiskKino and OMDb responses into app/test/fixtures/ —
# Stage 0, item 2 (docs/implementation-plan.md). The tests then run only on
# these files and never call the external APIs.
#
# Keys are read from a file OUTSIDE the repository (by default
# ~/.config/framebook/keys.env):
#
#   TMDB_TOKEN=eyJ...        # API Read Access Token (v4)
#   POISKKINO_KEY=...        # optional
#   OMDB_KEY=...             # optional
#
# A source without a key is skipped. PoiskKino: the script spends 8 of the
# 200 daily requests.
#
# Keys travel only in a header or the query and never reach the saved files:
# at the end the script checks that no key value appears in the fixtures, and
# fails if one does.
set -eu

keys_file=${FRAMEBOOK_KEYS:-$HOME/.config/framebook/keys.env}
[ -f "$keys_file" ] || {
	echo "No keys file: $keys_file" >&2
	exit 1
}
# shellcheck disable=SC1090
. "$keys_file"

repo_root=$(git rev-parse --show-toplevel)
out="$repo_root/app/test/fixtures"
mkdir -p "$out/tmdb" "$out/poiskkino" "$out/omdb"

# fetch <file> <url> [header]
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
	# Cards carry their cast and crew (Stage 6). `credits`, not
	# `aggregate_credits`: the aggregate for Game of Thrones is 350 KB.
	fetch "$out/tmdb/movie_603_ru.json" "$t/movie/603?language=ru-RU&append_to_response=external_ids%2Ccredits" "$h"
	fetch "$out/tmdb/tv_1399_ru.json" "$t/tv/1399?language=ru-RU&append_to_response=external_ids%2Ccredits" "$h"
	fetch "$out/tmdb/tv_1399_season_1_ru.json" "$t/tv/1399/season/1?language=ru-RU&append_to_response=credits" "$h"
	fetch "$out/tmdb/tv_1399_s1e3_credits_ru.json" "$t/tv/1399/season/1/episode/3/credits?language=ru-RU" "$h"
	# A person: Keanu Reeves, with everything he is in.
	fetch "$out/tmdb/person_6384_ru.json" "$t/person/6384?language=ru-RU&append_to_response=combined_credits" "$h"
	# The Discover shelves.
	fetch "$out/tmdb/trending_all_week_ru.json" "$t/trending/all/week?language=ru-RU" "$h"
	fetch "$out/tmdb/movie_now_playing_ru.json" "$t/movie/now_playing?language=ru-RU&page=1" "$h"
	# "Best of all time": /top_rated is crowded with new titles that have a
	# handful of votes, so it is discover by rating with a votes threshold.
	fetch "$out/tmdb/discover_movie_best_ru.json" "$t/discover/movie?language=ru-RU&sort_by=vote_average.desc&vote_count.gte=10000&page=1" "$h"
	fetch "$out/tmdb/discover_tv_best_ru.json" "$t/discover/tv?language=ru-RU&sort_by=vote_average.desc&vote_count.gte=3000&page=1" "$h"
	fetch "$out/tmdb/movie_603_recommendations_ru.json" "$t/movie/603/recommendations?language=ru-RU&page=1" "$h"
	fetch "$out/tmdb/tv_1399_recommendations_ru.json" "$t/tv/1399/recommendations?language=ru-RU&page=1" "$h"
	fetch "$out/tmdb/tv_1399_s1e3_external_ids.json" "$t/tv/1399/season/1/episode/3/external_ids" "$h"
	fetch "$out/tmdb/genre_movie_ru.json" "$t/genre/movie/list?language=ru-RU" "$h"
	fetch "$out/tmdb/genre_tv_ru.json" "$t/genre/tv/list?language=ru-RU" "$h"
	fetch "$out/tmdb/movie_not_found.json" "$t/movie/999999999" "$h"
else
	echo "TMDB_TOKEN not set — skipping TMDB"
fi

if [ -n "${POISKKINO_KEY:-}" ]; then
	p="https://api.poiskkino.dev/v1.5"
	h="X-API-KEY: $POISKKINO_KEY"
	# The Matrix: tmdb 603, imdb tt0133093, kp 301. Game of Thrones: tmdb 1399,
	# kp 464963. Without a type filter tmdb 603 finds both a film and a series
	# with the same number (TMDB numbers movie and tv separately) — the fixture
	# records that.
	fetch "$out/poiskkino/movie_by_tmdb_603.json" "$p/movie?externalId.tmdb=603" "$h"
	fetch "$out/poiskkino/movie_by_tmdb_603_type_movie.json" "$p/movie?externalId.tmdb=603&type=movie" "$h"
	fetch "$out/poiskkino/movie_by_imdb_tt0133093.json" "$p/movie?externalId.imdb=tt0133093" "$h"
	fetch "$out/poiskkino/movie_301.json" "$p/movie/301" "$h"
	fetch "$out/poiskkino/tv_by_tmdb_1399.json" "$p/movie?externalId.tmdb=1399&type=tv-series" "$h"
	# Do seasons/episodes have a Kinopoisk rating — this request is for that.
	fetch "$out/poiskkino/season_464963.json" "$p/season?movieId=464963&limit=2" "$h"
	# PoiskKino rejects a tmdb id outside 1..2000000 with a 400 (a validation
	# error), so an honest "not found" is captured with a nonexistent imdb id.
	fetch "$out/poiskkino/movie_by_tmdb_out_of_range.json" "$p/movie?externalId.tmdb=999999999" "$h"
	fetch "$out/poiskkino/movie_by_imdb_not_found.json" "$p/movie?externalId.imdb=tt9999999" "$h"
else
	echo "POISKKINO_KEY not set — skipping PoiskKino"
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
	echo "OMDB_KEY not set — skipping OMDb"
fi

leak=0
for key in "${TMDB_TOKEN:-}" "${POISKKINO_KEY:-}" "${OMDB_KEY:-}"; do
	[ -n "$key" ] || continue
	if grep -rqF -- "$key" "$out"; then
		echo "ERROR: a key value was found in $out — do not commit!" >&2
		leak=1
	fi
done
[ "$leak" -eq 0 ] || exit 1
echo "Done, no keys in the fixtures."
