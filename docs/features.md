# Product behavior

Current screen behavior and visual conventions. Algorithms and persistence
rules are linked where they apply; release chronology is in the
[changelog](../CHANGELOG.md).

## Navigation and settings

The root tabs are Discover, My ratings, Watchlist and Stats. Each retains its
own back stack and scroll position. Settings opens from the app bar.
Title routes nest inside the active tab; Back follows episode, season,
series and the originating list. Related titles and person profiles push
inside that tab so Back returns to the originating card.

Both navigation styles appear only on root tabs and support horizontal swipes
there. Movie, series, season, episode, person and full cast pages hide the bar;
returning to a root tab restores the selected style. Horizontal shelves keep
their gestures; nested title/person pages do not
switch tabs through body swipes. The default floating bar has a glass
selection that moves with the page. The classic bar remains available in
Settings. Tapping the active tab returns to its root. Content includes enough
bottom padding to bring the final row above the bar. Reduced motion disables
animated settling; navigation supports RTL.

Language, theme and navigation style are device preferences. Settings places
labels and their choices side by side at normal text sizes and vertically
when larger text requires more room.

## First launch and sources

Onboarding remains open until a TMDB key has been entered and the user
chooses to continue, leaving time to add optional sources. Removing the
TMDB key returns to onboarding. Restore from Drive is available before a key
has been entered. The [key guide](api-keys.md) covers setup, checks and security.
An initialization failure offers Retry without deleting local data.

About shows the app version, source attribution and licenses. It also offers
a manual update check. Automatic checks run on launch at most once per
24 hours after a successful response; failures can retry on a later launch.
The update banner opens the release page and can be dismissed per version.

## Discover and search

Discover has Films and People modes sharing one query. The mode selector
matches the search field and supports taps and horizontal drags; changing
modes retains the query and each mode's shelf positions. An inactive mode
cannot paginate the active results. Large text can increase selector height.

Search sends after a 400 ms pause or keyboard submission, discards obsolete
answers and loads more pages while scrolling. Films mode includes series.
People results show portraits, names and known-for titles. Back from a card
or profile preserves the search.

Empty title search offers personal recommendation rows followed by trending,
cinema and all-time-best shelves. Retrieval, ranking, explanations and
Not interested/Undo are specified in [recommendations](recommendations.md).
Empty People search shows favourites, frequent contributors, role-based rows
and popular people. Empty or failed optional shelves are omitted; a full
failure without useful local rows offers Retry.

The recent-title dropdown opens only from the focused, empty title field.
It contains the latest 20 films/series opened from search results, with
individual removal and Clear. Reopening a title moves it to the top.
Queries, pagination and people results are not recorded. Typing, changing
mode, selection or loss of focus closes the overlay. Clearing a query leaves
it closed until another tap. It overlays content without moving the shelves.
Its storage boundary is listed in the [data model](data-model.md#outside-the-database).
History writes run in order. Failed persistence restores the latest saved
history without interrupting title navigation.

## Title cards

Cards first show catalog details, then cached source ratings while eligible
refreshes run. Source cells load independently: one failure does not block
another source or rating the title. Existing values remain visible through
loading, failures and removed keys. Stale values show their date; missing
values distinguish no data, add a key, loading, offline, exhausted quota,
rejected key and source failure. Source coverage and freshness rules are in
[external sources](external-sources.md).

Movie headers show the earliest known valid release date, countries, positive
budget and worldwide box office in USD beside the poster. The full date
replaces a separate year. Series show first air date, last air date when
ended/cancelled, and countries. Unknown facts are omitted; movie finances
are not inferred for series. Country names follow TMDB's supplied text.
Cards explicitly show when a title has not been released or its release date
is unknown. Planned series and series in production have their own status
labels instead of appearing as ongoing; a known past premiere still permits
rating while later seasons are in production.

Cast strips show the first 20 actors. The cast heading opens a lazy full list;
actor profiles open above it. Names and roles reserve two scaled lines each,
with deliberate wrapping and ellipsis. Crew lines show the relevant creators,
directors, writers, music and camera work. Credit retrieval is described in
[external sources](external-sources.md#tmdb--the-catalog).

Movie collections and film/TV similar-title shelves load independently, omit
empty results and have their own Retry. They deduplicate typed keys and
exclude the current title. Collections sort by release date, undated last.
TMDB collections do not imply TV franchise membership.

Renumbered rated parts and watchlisted seasons prompt Move / Keep inline:
above the series' seasons, the season's episodes, or below the episode header.
Only one question appears at a time; conflicting destination scores require
a choice. Choices wait for persistence and disable repeated taps; a failed
write reports an error and keeps the question available for retry.
Detection and mutation rules are in the
[data model](data-model.md#when-tmdb-renumbers).

## Rating editor and lists

Each card has My rating. The bottom-sheet editor uses a score reel from 1 to
10 in half-point steps, with haptic feedback and an optional note. A new
rating starts at 5; an existing one starts at its saved score. Scores display
without a trailing `.0`. Films, series, seasons and episodes require a valid
release date on or before today to add or edit a rating, including saved cards
without catalog access. Missing or invalid dates show an explicit explanation
and keep rating disabled; adding to the watchlist remains available. Existing
ratings are retained and can still be deleted. Deletion requires
confirmation. Failed persistence keeps the editor and draft open, and saving
freezes the reel's current value.
Failed deletion and watchlist changes show a retryable error while preserving
the saved state. Card controls prevent duplicate writes while their operation
is pending. Optional snapshot-refresh failures do not interrupt the card.
A missing query result is not proof that a title is unrated. Until either the
individual query or the loaded library confirms the state, the card shows
loading or a retryable local-data error. Known library ratings remain visible
while the individual query is pending; a confirmed deletion takes precedence.
Opening a new draft also rechecks the stored row, so an empty library fallback
that lags a concurrent import cannot discard an existing note.

The comparison area appears only with more than 20 other live movie ratings
or more than 10 other ratings of the same series, season or episode kind.
Eligibility is checked before opening the editor so the reel stays in place.
As the score moves, three independent shelves show all same-kind titles at
that score and at the nearest existing score above and below, excluding the
current title. Each group sorts by `scored_at` descending, then natural key.
The same-score panel spans the width above the two neighbour panels; the
area keeps a fixed height. An empty group says so. Optional comparison
failures do not block saving, and superseded replies cannot replace the
current selection.

My ratings filters by kind and sorts by score-change date, score, year,
title or divergence. Parts sort under their series in number order. Date
order groups entries by local day: Today, Yesterday and full localized dates.
Note-only changes do not move a title to a new score day. Other sorts stay
flat. Filter/order selections last for the session. Source comparison and
parent-average formulas are specified in [analytics](analytics.md).

Ratings, watchlist and statistics show a local-library error with Retry if
reading or preparing their first useful data fails. Retry restarts the affected
read and preparation; a useful previous result remains visible through refresh.

Watchlist shows films, whole series and seasons, newest first. Seasons group
under a tappable series heading that need not itself be selected. Choosing
a whole series displaces its seasons; choosing a season displaces the whole
series. Removing offers Undo; if Undo cannot save, its error offers Undo again.
Rating a title removes it from the list, while
deleting that rating does not re-add it. Offline/concurrent selection rules
are specified in [sync](sync.md#series-and-season-watchlist-choices).

## People and statistics

The People discovery page retains its last useful contributor shelves while
indexing or insight preparation replaces their data. A temporary empty or
partial pass must not collapse the vertical list and reset its scroll position.
The first useful batch can appear during initial loading; completed results,
including a genuinely empty result, replace the retained groups. Favourites
remain independently reactive.

Person profiles show dates, an expandable biography and a filmography with
your scores. The default combines all roles with one row per title. Acting,
directing, production, writing, music, camera and Other work filters count
unique titles and show the jobs relevant to that filter. Empty roles are
hidden; assistant directors are not classified as directors. Talk/news
appearances as themselves are excluded.

Favourite actions apply to the whole person across roles. Profiles use a
static violet frame and a centered favourite button. A shelf portrait opens
on one tap and toggles favourite on double tap, with a brief heart animation,
snackbar and a saved-heart badge. An equivalent accessibility action exists.

Stats separates films, series, seasons and episodes, starting with films.
Its four-way inset switcher shares Discover's moving glass selection and
supports taps and horizontal dragging, including RTL and reduced motion.
Compact labels stay on one line and scale down when space is tight.
The overview shows a compact rating count and mean, up to six posters with
scores of 8 or above, and up to three favourite genres. Genre ranking uses
the highest mean over at least three rated works. Empty optional sections
are omitted; the overview does not wait for people-credit enrichment.
Its bounded summary, genre and navigation sections have exact heights from
their first layout, keeping the scroll range steady while they enter view.

Separate routes contain score distribution, genres/decades, actors/directors
and public-score comparison. They keep the overview's kind filter, hide tab
navigation and return to the retained overview with Back. Score, genre,
decade and people rows open contributing works; title and person links keep
that detail screen beneath them in the Stats stack.

People offers Acting/Directing and Most frequent/Highest rated, with count
and mean only. Highest rated requires three works in the selected role.
Partial credit coverage and continuation stay on that detail page.
Source comparison displays one chosen service, a plain-language signed mean
gap, coverage and contributing titles. Higher/lower lists use a one-point
gap and show both personal and source scores when opened. Median, numeric
correlation, score spread, diversity, creative duos and reliability/polarization
rankings are absent from the statistics UI. Calculation definitions are in
[analytics](analytics.md).

Movie statistics offers a separate Review your scores panel below the count/
mean summary and before the poster shelf. Its static violet gradient and frame
are shared with person headers. A heading and explanation sit above the
full-width filled Compare films button, making the panel an independent
feature rather than an action on the summary numbers. It opens a nested
calibration route with tab navigation hidden and remains distinct from the
four ruled detail links below.
Its confirmed score
changes and daily allowance are specified in [pair calibration](pair-calibration.md).

## Images, offline use and keyboard

A title cover opens full screen with the current image first, followed by
UI-language, original-language and textless variants. Episode covers use
stills; movie/TV backdrops are excluded. Person photos use the same viewer.
The viewer covers the tab navigation, including the floating bottom bar;
closing it returns to the card in its original tab.
Swipe changes images and pinch zooms. The cached preview and large image
use identical viewport constraints with `BoxFit.contain`; the route fades
without scaling. Decode memory limits belong to the
[architecture](client-architecture.md#images).

Without a network, saved lists, edits, sorting and local statistics remain
usable. Search needs a cached response or a connection. If a catalog card
cannot load but a library snapshot exists, a saved card shows its title,
poster, score, note and known source scores, with an offline explanation and
Retry. It opens only its cached cover. Without a response or snapshot, the
screen shows an error. Uncached genre names and people credits remain missing.

After backgrounding, the keyboard reopens only for the still-mounted editor
that owned visible keyboard focus before the pause. An explicitly dismissed
keyboard stays hidden. This state does not survive process restarts.

## Visual conventions

The editing-table theme uses a cool lightbox, ink, film stock and grease-pencil
marks. Both light and dark palettes are designed explicitly. Bundled Sofia
Sans uses Extra Condensed for figures/titles and normal width for reading;
static weights select the intended font file.
Both interface languages use the Russian Cyrillic glyph forms for saved titles,
names and notes; choosing English does not switch them to the font's Bulgarian
default. This glyph choice does not change interface translations or formatting.

Scores below 4 are red, 4–6.5 inclusive amber, and above 6.5 green. Sources
on a 100-point scale are normalized before choosing colour. Reel frames and
poster badges use the light score palette in either theme. Muted violet is
the action accent; edge-print amber marks dates and years. Ratings and Stats
comparisons use ruled columns; notes sit in the margin with a score-coloured
rule. The reel remains the main visual emphasis.

Poster tint prefers visible chromatic midtones over dark borders and white
lettering. It blends into the header at 24% in light and 38% in dark themes,
with a reserved border so loading does not change geometry. Missing artwork
uses the ordinary surface. Source cells similarly reserve caption/numeric
space and adapt to the current text scale.
